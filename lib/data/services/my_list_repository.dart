import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/anime_detail.dart';
import '../models/anime_item.dart';
import '../models/my_list_entry.dart';
import 'anime_stream_resolver.dart';

/// Persistent repository managing the user's saved, watching, and completed anime.
///
/// Uses [AnimeStreamResolver.detectAnimeKey] to unify entries across Home,
/// Explore, Schedule, Detail, and Watch screens without duplicate records.
class MyListRepository extends ChangeNotifier {
  static final MyListRepository instance = MyListRepository._internal();

  MyListRepository._internal()
      : _storageFile = null,
        _disablePersistence = false,
        _clock = DateTime.now;

  /// Creates an isolated [MyListRepository] instance for testing or custom storage.
  MyListRepository({
    File? storageFile,
    bool disablePersistence = false,
    DateTime Function()? clock,
  })  : _storageFile = storageFile,
        _disablePersistence = disablePersistence,
        _clock = clock ?? DateTime.now;

  final File? _storageFile;
  final bool _disablePersistence;
  final DateTime Function() _clock;

  final Map<String, MyListEntry> _entries = {};
  bool _initialized = false;
  bool _isLoading = false;
  String? _loadError;

  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  /// All entries sorted by most recently updated first.
  List<MyListEntry> get allEntries {
    final list = _entries.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  /// Entries filtered by [status], sorted by most recently updated first.
  List<MyListEntry> entriesByStatus(MyListStatus status) {
    final list = _entries.values.where((e) => e.status == status).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  /// Count of entries in [status].
  int countByStatus(MyListStatus status) =>
      _entries.values.where((e) => e.status == status).length;

  /// Computes a canonical storage key unifying mock slugs and AniList IDs.
  static String canonicalKeyFor(
    String animeId, {
    int aniListId = 0,
    String title = '',
  }) {
    final cleanId = animeId.trim();
    final primaryId = aniListId > 0 ? aniListId.toString() : cleanId;
    final detected = AnimeStreamResolver.detectAnimeKey(primaryId, title);
    if (detected != 'unknown' && detected.isNotEmpty) {
      return detected;
    }
    if (cleanId.isNotEmpty && cleanId != primaryId) {
      final secondaryDetected = AnimeStreamResolver.detectAnimeKey(cleanId, title);
      if (secondaryDetected != 'unknown' && secondaryDetected.isNotEmpty) {
        return secondaryDetected;
      }
    }
    if (aniListId > 0) return 'anilist-$aniListId';
    if (cleanId.isNotEmpty) return cleanId.toLowerCase();
    return title.trim().toLowerCase();
  }

  static bool _resolvePlayable(
    String animeId, {
    int aniListId = 0,
    String title = '',
  }) {
    if (AnimeStreamResolver.hasCompleteEpisodes(animeId, title)) return true;
    if (aniListId > 0 &&
        AnimeStreamResolver.hasCompleteEpisodes(aniListId.toString(), title)) {
      return true;
    }
    return false;
  }

  File _resolveDefaultStorageFile() {
    final customFile = _storageFile;
    if (customFile != null) return customFile;
    if (Platform.isAndroid) {
      final androidDir = Directory('/data/user/0/com.example.nimeva/files');
      if (androidDir.existsSync()) {
        return File('${androidDir.path}/nimeva_my_list.json');
      }
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return File('$home/.nimeva/nimeva_my_list.json');
    }
    return File('${Directory.systemTemp.path}/nimeva_my_list.json');
  }

  /// Loads persisted entries from local JSON storage once (idempotent).
  Future<void> init({bool forceReload = false}) async {
    if (_initialized && !forceReload) return;
    if (_disablePersistence) {
      _initialized = true;
      _loadError = null;
      return;
    }

    _isLoading = true;
    _loadError = null;

    try {
      final file = _resolveDefaultStorageFile();
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            _entries.clear();
            for (final item in decoded) {
              if (item is Map<String, dynamic>) {
                final entry = MyListEntry.fromJson(item);
                if (entry.canonicalKey.isNotEmpty) {
                  _entries[entry.canonicalKey] = entry;
                }
              }
            }
          }
        }
      }
      _initialized = true;
    } catch (e) {
      _loadError = 'Gagal memuat daftar anime tersimpan.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (_disablePersistence) return;
    try {
      final file = _resolveDefaultStorageFile();
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final payload = jsonEncode(allEntries.map((e) => e.toJson()).toList());
      await file.writeAsString(payload);
    } catch (_) {
      // Non-fatal in sandboxed / restricted environments; in-memory state stays intact.
    }
  }

  MyListEntry? _findByAnyKey(
    String animeId, {
    int aniListId = 0,
    String title = '',
  }) {
    final key = canonicalKeyFor(animeId, aniListId: aniListId, title: title);
    final direct = _entries[key];
    if (direct != null) return direct;

    for (final entry in _entries.values) {
      if (aniListId > 0 && entry.aniListId == aniListId) return entry;
      if (animeId.isNotEmpty && entry.animeId == animeId) return entry;
      if (animeId.isNotEmpty && entry.canonicalKey == animeId) return entry;
    }
    return null;
  }

  /// Returns true if the anime is already saved anywhere in My List.
  bool contains(
    String animeId, {
    int aniListId = 0,
    String title = '',
  }) {
    return _findByAnyKey(animeId, aniListId: aniListId, title: title) != null;
  }

  /// Finds an entry matching [animeId], [aniListId], or [title].
  MyListEntry? findEntry(
    String animeId, {
    int aniListId = 0,
    String title = '',
  }) {
    return _findByAnyKey(animeId, aniListId: aniListId, title: title);
  }

  /// Toggles saving [item] in My List. Returns `true` if saved, `false` if removed.
  Future<bool> toggleSaveAnime(AnimeItem item, {int? totalEpisodes}) async {
    final existing = _findByAnyKey(
      item.id,
      aniListId: item.aniListId,
      title: item.title,
    );
    if (existing != null) {
      _entries.remove(existing.canonicalKey);
      notifyListeners();
      await _persist();
      return false;
    }

    final key = canonicalKeyFor(
      item.id,
      aniListId: item.aniListId,
      title: item.title,
    );
    final parsedEps = totalEpisodes ??
        MyListEntry.parseTotalEpisodesFromInfo(item.episodeInfo);
    final playable = _resolvePlayable(
      item.id,
      aniListId: item.aniListId,
      title: item.title,
    );

    _entries[key] = MyListEntry(
      canonicalKey: key,
      animeId: item.id,
      aniListId: item.aniListId,
      title: item.title,
      japaneseTitle: item.japaneseTitle,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      rating: item.rating,
      releaseYear: item.releaseYear,
      genres: item.genres,
      description: item.description,
      totalEpisodes: parsedEps,
      watchedEpisode: 0,
      status: MyListStatus.saved,
      hasVideoAvailable: playable,
      updatedAt: _clock(),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  /// Toggles saving from [AnimeDetail]. Returns `true` if saved, `false` if removed.
  Future<bool> toggleSaveFromDetail(AnimeDetail detail) async {
    final existing = _findByAnyKey(
      detail.id,
      aniListId: detail.aniListId,
      title: detail.title,
    );
    if (existing != null) {
      _entries.remove(existing.canonicalKey);
      notifyListeners();
      await _persist();
      return false;
    }

    final key = canonicalKeyFor(
      detail.id,
      aniListId: detail.aniListId,
      title: detail.title,
    );
    final playable = _resolvePlayable(
      detail.id,
      aniListId: detail.aniListId,
      title: detail.title,
    );
    final resolvedTotal = detail.episodes.isNotEmpty
        ? max(detail.totalEpisodes, detail.episodes.length)
        : detail.totalEpisodes;

    _entries[key] = MyListEntry(
      canonicalKey: key,
      animeId: detail.id,
      aniListId: detail.aniListId,
      title: detail.title,
      japaneseTitle: detail.japaneseTitle,
      posterUrl: detail.posterUrl,
      backdropUrl: detail.backdropUrl,
      rating: detail.rating,
      releaseYear: detail.releaseYear,
      genres: detail.genres,
      description: detail.synopsis,
      totalEpisodes: resolvedTotal,
      watchedEpisode: 0,
      status: MyListStatus.saved,
      hasVideoAvailable: playable,
      updatedAt: _clock(),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  /// Records automatic episode watch progress from [AnimeWatchScreen].
  ///
  /// Only increments progress when [detail] has playable local video.
  Future<void> recordWatchProgress({
    required AnimeDetail detail,
    required int episodeNumber,
    String? episodeTitle,
  }) async {
    if (episodeNumber <= 0) return;
    final playable = detail.hasVideoAvailable &&
        _resolvePlayable(
          detail.id,
          aniListId: detail.aniListId,
          title: detail.title,
        );
    if (!playable) return;

    final existing = _findByAnyKey(
      detail.id,
      aniListId: detail.aniListId,
      title: detail.title,
    );
    final key = existing?.canonicalKey ??
        canonicalKeyFor(
          detail.id,
          aniListId: detail.aniListId,
          title: detail.title,
        );

    final totalEps = max(
      existing?.totalEpisodes ?? 0,
      detail.episodes.isNotEmpty
          ? max(detail.totalEpisodes, detail.episodes.length)
          : detail.totalEpisodes,
    );
    final nextWatched = max(existing?.watchedEpisode ?? 0, episodeNumber);
    final clampedWatched = totalEps > 0 ? min(nextWatched, totalEps) : nextWatched;
    final nextStatus = (totalEps > 0 && clampedWatched >= totalEps)
        ? MyListStatus.completed
        : MyListStatus.watching;

    _entries[key] = MyListEntry(
      canonicalKey: key,
      animeId: existing?.animeId.isNotEmpty == true ? existing!.animeId : detail.id,
      aniListId: detail.aniListId > 0
          ? detail.aniListId
          : (existing?.aniListId ?? 0),
      title: detail.title,
      japaneseTitle: detail.japaneseTitle,
      posterUrl: detail.posterUrl.isNotEmpty
          ? detail.posterUrl
          : (existing?.posterUrl ?? ''),
      backdropUrl: detail.backdropUrl.isNotEmpty
          ? detail.backdropUrl
          : (existing?.backdropUrl ?? ''),
      rating: detail.rating > 0 ? detail.rating : (existing?.rating ?? 0.0),
      releaseYear: detail.releaseYear > 0
          ? detail.releaseYear
          : (existing?.releaseYear ?? 0),
      genres: detail.genres.isNotEmpty
          ? detail.genres
          : (existing?.genres ?? const []),
      description: detail.synopsis.isNotEmpty
          ? detail.synopsis
          : (existing?.description ?? ''),
      totalEpisodes: totalEps,
      watchedEpisode: clampedWatched,
      currentEpisodeTitle: episodeTitle ?? existing?.currentEpisodeTitle,
      status: nextStatus,
      hasVideoAvailable: true,
      updatedAt: _clock(),
    );
    notifyListeners();
    await _persist();
  }

  /// Manually moves an entry to [newStatus] and adjusts episode progress cleanly.
  Future<void> updateStatus(String keyOrId, MyListStatus newStatus) async {
    final existing = _findByAnyKey(keyOrId);
    if (existing == null) return;

    int nextWatched = existing.watchedEpisode;
    bool clearTitle = false;
    if (newStatus == MyListStatus.saved) {
      nextWatched = 0;
      clearTitle = true;
    } else if (newStatus == MyListStatus.completed && existing.totalEpisodes > 0) {
      nextWatched = existing.totalEpisodes;
    } else if (newStatus == MyListStatus.watching && nextWatched == 0) {
      nextWatched = 1;
    }

    _entries[existing.canonicalKey] = existing.copyWith(
      status: newStatus,
      watchedEpisode: nextWatched,
      clearCurrentEpisodeTitle: clearTitle,
      updatedAt: _clock(),
    );
    notifyListeners();
    await _persist();
  }

  /// Manually updates [watchedEpisode] and transitions status accordingly.
  Future<void> updateEpisodeProgress(String keyOrId, int episodeNumber) async {
    final existing = _findByAnyKey(keyOrId);
    if (existing == null) return;

    final safeEpisode = episodeNumber < 0 ? 0 : episodeNumber;
    final effectiveTotal = existing.totalEpisodes > 0
        ? max(existing.totalEpisodes, safeEpisode)
        : 0;

    final MyListStatus nextStatus;
    if (safeEpisode == 0) {
      nextStatus = MyListStatus.saved;
    } else if (effectiveTotal > 0 && safeEpisode >= effectiveTotal) {
      nextStatus = MyListStatus.completed;
    } else {
      nextStatus = MyListStatus.watching;
    }

    _entries[existing.canonicalKey] = existing.copyWith(
      watchedEpisode: safeEpisode,
      totalEpisodes: existing.totalEpisodes > 0 ? existing.totalEpisodes : 0,
      status: nextStatus,
      currentEpisodeTitle: safeEpisode > 0 ? 'Episode $safeEpisode' : null,
      clearCurrentEpisodeTitle: safeEpisode == 0,
      updatedAt: _clock(),
    );
    notifyListeners();
    await _persist();
  }

  /// Removes an entry from My List and returns the removed copy for undo.
  Future<MyListEntry?> removeEntry(String keyOrId) async {
    final existing = _findByAnyKey(keyOrId);
    if (existing == null) return null;
    _entries.remove(existing.canonicalKey);
    notifyListeners();
    await _persist();
    return existing;
  }

  /// Restores a previously removed entry (used by Undo SnackBar actions).
  Future<void> restoreEntry(MyListEntry entry) async {
    _entries[entry.canonicalKey] = entry;
    notifyListeners();
    await _persist();
  }
}
