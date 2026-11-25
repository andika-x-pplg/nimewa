import '../models/schedule_entry.dart';
import 'anilist_api_client.dart';
import 'anime_stream_resolver.dart';

/// Signature for executing an AniList GraphQL query with variables.
typedef GraphQLRequester = Future<Map<String, dynamic>> Function(
  String query,
  Map<String, dynamic> variables,
);

/// Service for fetching, caching, and normalizing AniList weekly airing schedules.
class ScheduleService {
  static const int _perPage = 50;
  static const int _maxPages = 15;
  static const Duration _delayThreshold = Duration(days: 10);

  static const String _weeklyScheduleQuery = r'''
query ($page: Int, $perPage: Int, $airingAtGreater: Int, $airingAtLesser: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    airingSchedules(
      airingAt_greater: $airingAtGreater
      airingAt_lesser: $airingAtLesser
      sort: TIME
    ) {
      id
      airingAt
      episode
      media {
        id
        isAdult
        status
        format
        averageScore
        description
        genres
        bannerImage
        coverImage {
          extraLarge
          large
          medium
        }
        title {
          romaji
          english
          native
        }
        nextAiringEpisode {
          airingAt
          episode
        }
      }
    }
  }
}
''';

  final GraphQLRequester _requester;
  final Duration _cacheTtl;
  final DateTime Function() _clock;
  final Map<String, _CachedScheduleWeek> _cache = {};

  /// Creates a [ScheduleService] with optional custom GraphQL requester and cache TTL.
  ScheduleService({
    AniListApiClient? apiClient,
    GraphQLRequester? graphQLRequester,
    Duration cacheTtl = const Duration(minutes: 10),
    DateTime Function()? clock,
  })  : _requester = graphQLRequester ??
            (apiClient ?? const AniListApiClient()).executeGraphQL,
        _cacheTtl = cacheTtl,
        _clock = clock ?? DateTime.now;

  /// Fetches the rolling Sunday-to-Saturday schedule containing [now].
  Future<WeeklyScheduleResult> fetchWeeklySchedule({
    DateTime? now,
    bool forceRefresh = false,
  }) async {
    final currentTime = _clock();
    final referenceNow = (now ?? currentTime).toLocal();
    final weekStart = ScheduleDateHelper.weekStartSunday(referenceNow);
    final nextWeekStart =
        DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
    final prevWeekStart =
        DateTime(weekStart.year, weekStart.month, weekStart.day - 7);
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
      23,
      59,
      59,
    );
    final weekKey = ScheduleDateHelper.dateKey(weekStart);

    final cached = _cache[weekKey];
    if (!forceRefresh &&
        cached != null &&
        currentTime.difference(cached.fetchedAt) < _cacheTtl) {
      return cached.result;
    }

    try {
      final results = await Future.wait([
        _fetchSchedulesInRange(start: weekStart, endExclusive: nextWeekStart),
        _fetchSchedulesInRange(start: prevWeekStart, endExclusive: weekStart),
      ]);

      final currentWeekItems = results[0];
      final previousWeekItems = results[1];

      final entries = <ScheduleEntry>[
        for (final item in currentWeekItems) item.entry,
      ];
      final currentMediaIds = {
        for (final item in currentWeekItems) item.entry.mediaId,
      };

      final delayedEntries = _detectDelayedEntries(
        previousWeekItems: previousWeekItems,
        currentMediaIds: currentMediaIds,
        weekStart: weekStart,
        nextWeekStart: nextWeekStart,
      );
      entries.addAll(delayedEntries);

      final grouped = _groupAndSortEntries(entries);
      final freshResult = WeeklyScheduleResult(
        weekStart: weekStart,
        weekEnd: weekEnd,
        entriesByDateKey: grouped,
        isStaleCache: false,
      );

      _cache[weekKey] = _CachedScheduleWeek(
        result: freshResult,
        fetchedAt: _clock(),
      );
      return freshResult;
    } catch (_) {
      if (cached != null) {
        return WeeklyScheduleResult(
          weekStart: cached.result.weekStart,
          weekEnd: cached.result.weekEnd,
          entriesByDateKey: cached.result.entriesByDateKey,
          isStaleCache: true,
        );
      }
      rethrow;
    }
  }

  Future<List<_ParsedScheduleRecord>> _fetchSchedulesInRange({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final startSec = start.millisecondsSinceEpoch ~/ 1000;
    final endSec = endExclusive.millisecondsSinceEpoch ~/ 1000;

    final records = <_ParsedScheduleRecord>[];
    var page = 1;
    var hasNextPage = true;

    while (hasNextPage && page <= _maxPages) {
      final response = await _requester(
        _weeklyScheduleQuery,
        {
          'page': page,
          'perPage': _perPage,
          // AniList bounds are strictly exclusive, so shift start by -1s to include 00:00:00.
          'airingAtGreater': startSec - 1,
          'airingAtLesser': endSec,
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw StateError(
          'AniList schedule query returned no data: ${response['errors']}',
        );
      }

      final pageData = data['Page'] as Map<String, dynamic>?;
      if (pageData == null) {
        break;
      }

      final rawSchedules =
          pageData['airingSchedules'] as List<dynamic>? ?? const [];
      for (final rawNode in rawSchedules) {
        if (rawNode is! Map<String, dynamic>) continue;
        final parsed = _parseScheduleNode(
          rawNode,
          rangeStart: start,
          rangeEndExclusive: endExclusive,
        );
        if (parsed != null) {
          records.add(parsed);
        }
      }

      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>?;
      hasNextPage = pageInfo?['hasNextPage'] == true;
      page++;
    }

    return records;
  }

  _ParsedScheduleRecord? _parseScheduleNode(
    Map<String, dynamic> node, {
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) {
    final media = node['media'] as Map<String, dynamic>?;
    if (media == null || media['isAdult'] == true) {
      return null;
    }

    final mediaId = _toInt(media['id']);
    final scheduleId = _toInt(node['id']);
    final airingAtSec = _toInt(node['airingAt']);
    if (mediaId <= 0 || airingAtSec <= 0) {
      return null;
    }

    final titles = media['title'] as Map<String, dynamic>? ?? const {};
    final englishTitle = _trimmedOrEmpty(titles['english']);
    final romajiTitle = _trimmedOrEmpty(titles['romaji']);
    final nativeTitle = _trimmedOrEmpty(titles['native']);
    final title = _firstNonEmpty([englishTitle, romajiTitle, nativeTitle]);
    if (title == null) {
      return null;
    }

    final airingAt =
        DateTime.fromMillisecondsSinceEpoch(airingAtSec * 1000).toLocal();
    if (airingAt.isBefore(rangeStart) || !airingAt.isBefore(rangeEndExclusive)) {
      return null;
    }

    final covers = media['coverImage'] as Map<String, dynamic>? ?? const {};
    final posterUrl = _firstNonEmpty([
          _trimmedOrEmpty(covers['extraLarge']),
          _trimmedOrEmpty(covers['large']),
          _trimmedOrEmpty(covers['medium']),
        ]) ??
        '';
    final bannerUrl = _firstNonEmpty([_trimmedOrEmpty(media['bannerImage'])]);

    final scoreInt = _toInt(media['averageScore']);
    final rating = scoreInt > 0
        ? double.parse((scoreInt / 10.0).toStringAsFixed(1))
        : 0.0;

    final rawGenres = media['genres'] as List<dynamic>? ?? const [];
    final genres = rawGenres
        .map((g) => g.toString().trim())
        .where((g) => g.isNotEmpty)
        .toList();

    final rawDescription = media['description']?.toString() ?? '';
    final synopsis = rawDescription.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final format = _firstNonEmpty([_trimmedOrEmpty(media['format'])]) ?? 'TV';
    final episodeNumber = _toInt(node['episode']);

    final nextAiring = media['nextAiringEpisode'] as Map<String, dynamic>?;
    final nextAiringSec = _toInt(nextAiring?['airingAt']);
    final nextAiringAt = nextAiringSec > 0
        ? DateTime.fromMillisecondsSinceEpoch(nextAiringSec * 1000).toLocal()
        : null;
    final nextEpisodeNumber = _toInt(nextAiring?['episode']);

    final hasVideo = AnimeStreamResolver.hasCompleteEpisodes(
      mediaId.toString(),
      title,
    );

    final entry = ScheduleEntry(
      scheduleId: scheduleId,
      mediaId: mediaId,
      title: title,
      japaneseTitle: nativeTitle,
      posterUrl: posterUrl,
      bannerUrl: bannerUrl,
      rating: rating,
      genres: genres,
      synopsis: synopsis,
      format: format,
      episodeNumber: episodeNumber,
      airingAt: airingAt,
      nextAiringAt: nextAiringAt,
      hasVideoAvailable: hasVideo,
    );

    return _ParsedScheduleRecord(
      entry: entry,
      mediaStatus: _trimmedOrEmpty(media['status']),
      nextEpisodeNumber: nextEpisodeNumber > 0 ? nextEpisodeNumber : null,
    );
  }

  List<ScheduleEntry> _detectDelayedEntries({
    required List<_ParsedScheduleRecord> previousWeekItems,
    required Set<int> currentMediaIds,
    required DateTime weekStart,
    required DateTime nextWeekStart,
  }) {
    final latestByMedia = <int, _ParsedScheduleRecord>{};
    for (final record in previousWeekItems) {
      final mediaId = record.entry.mediaId;
      if (currentMediaIds.contains(mediaId)) continue;
      final existing = latestByMedia[mediaId];
      if (existing == null ||
          record.entry.airingAt.isAfter(existing.entry.airingAt)) {
        latestByMedia[mediaId] = record;
      }
    }

    final delayed = <ScheduleEntry>[];
    for (final record in latestByMedia.values) {
      if (record.mediaStatus != 'RELEASING') continue;

      final nextAiringAt = record.entry.nextAiringAt;
      if (nextAiringAt == null) continue;
      if (nextAiringAt.difference(record.entry.airingAt) < _delayThreshold) {
        continue;
      }

      final prev = record.entry.airingAt;
      final projectedAiringAt = DateTime(
        prev.year,
        prev.month,
        prev.day + 7,
        prev.hour,
        prev.minute,
        prev.second,
      );
      if (projectedAiringAt.isBefore(weekStart) ||
          !projectedAiringAt.isBefore(nextWeekStart)) {
        continue;
      }

      final nextEpisode =
          record.nextEpisodeNumber ?? (record.entry.episodeNumber + 1);
      final delayNote =
          'Libur minggu ini · Tayang lagi ${nextAiringAt.day} ${ScheduleDateHelper.shortMonthLabel(nextAiringAt.month)}';

      delayed.add(
        ScheduleEntry(
          scheduleId: record.entry.scheduleId > 0
              ? -record.entry.scheduleId
              : -record.entry.mediaId,
          mediaId: record.entry.mediaId,
          title: record.entry.title,
          japaneseTitle: record.entry.japaneseTitle,
          posterUrl: record.entry.posterUrl,
          bannerUrl: record.entry.bannerUrl,
          rating: record.entry.rating,
          genres: record.entry.genres,
          synopsis: record.entry.synopsis,
          format: record.entry.format,
          episodeNumber: nextEpisode,
          airingAt: projectedAiringAt,
          isHiatusOrDelayed: true,
          nextAiringAt: nextAiringAt,
          delayNote: delayNote,
          hasVideoAvailable: record.entry.hasVideoAvailable,
        ),
      );
    }

    return delayed;
  }

  Map<String, List<ScheduleEntry>> _groupAndSortEntries(
    List<ScheduleEntry> entries,
  ) {
    final grouped = <String, List<ScheduleEntry>>{};
    for (final entry in entries) {
      final key = ScheduleDateHelper.dateKey(entry.airingAt);
      grouped.putIfAbsent(key, () => <ScheduleEntry>[]).add(entry);
    }

    for (final list in grouped.values) {
      list.sort((a, b) {
        final timeCmp = a.airingAt.compareTo(b.airingAt);
        if (timeCmp != 0) return timeCmp;
        final mediaCmp = a.mediaId.compareTo(b.mediaId);
        if (mediaCmp != 0) return mediaCmp;
        return a.scheduleId.compareTo(b.scheduleId);
      });
    }

    return grouped;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _trimmedOrEmpty(dynamic value) =>
      value?.toString().trim() ?? '';

  static String? _firstNonEmpty(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isNotEmpty) return candidate;
    }
    return null;
  }
}

class _ParsedScheduleRecord {
  final ScheduleEntry entry;
  final String mediaStatus;
  final int? nextEpisodeNumber;

  const _ParsedScheduleRecord({
    required this.entry,
    required this.mediaStatus,
    this.nextEpisodeNumber,
  });
}

class _CachedScheduleWeek {
  final WeeklyScheduleResult result;
  final DateTime fetchedAt;

  const _CachedScheduleWeek({
    required this.result,
    required this.fetchedAt,
  });
}
