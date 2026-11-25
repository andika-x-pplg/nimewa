import 'anime_item.dart';

/// User tracking status for an anime stored in My List.
enum MyListStatus {
  watching,
  saved,
  completed,
}

/// Domain model representing a user's saved or watched anime entry in My List.
class MyListEntry {
  final String canonicalKey;
  final String animeId;
  final int aniListId;
  final String title;
  final String japaneseTitle;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final int releaseYear;
  final List<String> genres;
  final String description;
  final int totalEpisodes;
  final int watchedEpisode;
  final String? currentEpisodeTitle;
  final MyListStatus status;
  final bool hasVideoAvailable;
  final DateTime updatedAt;

  const MyListEntry({
    required this.canonicalKey,
    required this.animeId,
    this.aniListId = 0,
    required this.title,
    this.japaneseTitle = '',
    this.posterUrl = '',
    this.backdropUrl = '',
    this.rating = 0.0,
    this.releaseYear = 0,
    this.genres = const [],
    this.description = '',
    this.totalEpisodes = 0,
    this.watchedEpisode = 0,
    this.currentEpisodeTitle,
    this.status = MyListStatus.saved,
    this.hasVideoAvailable = false,
    required this.updatedAt,
  });

  /// Completion percentage clamped strictly to 0..100 without division-by-zero.
  int get completedPercent {
    if (status == MyListStatus.completed) return 100;
    if (totalEpisodes <= 0 || watchedEpisode <= 0) return 0;
    return ((watchedEpisode / totalEpisodes) * 100).round().clamp(0, 100);
  }

  /// Remaining percentage until completion (0..100).
  int get remainingPercent => (100 - completedPercent).clamp(0, 100);

  /// Normalized progress bar fraction (0.0..1.0).
  double get progressFraction => completedPercent / 100.0;

  /// Human-readable episode progress label for cards.
  String get progressSummaryText {
    if (!hasVideoAvailable &&
        watchedEpisode == 0 &&
        status == MyListStatus.saved) {
      return 'Platform resmi · Progres 0%';
    }
    if (totalEpisodes > 0) {
      return '$watchedEpisode dari $totalEpisodes episode';
    }
    return 'Episode $watchedEpisode';
  }

  /// Human-readable completion & remaining percentage summary without em-dashes.
  String get percentSummaryText =>
      '$completedPercent% selesai · Sisa $remainingPercent%';

  /// Extracts an episode count from strings such as 'SUB · 24 EPS (Tamat)' or 'SUB · MOVIE'.
  static int parseTotalEpisodesFromInfo(String episodeInfo) {
    final upper = episodeInfo.toUpperCase();
    final match = RegExp(r'(\d+)\s*EPS?').firstMatch(upper);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    if (upper.contains('MOVIE')) {
      return 1;
    }
    return 0;
  }

  /// Converts this saved entry into an [AnimeItem] for detail navigation.
  AnimeItem toAnimeItem() {
    final epInfo = totalEpisodes == 1
        ? 'SUB · MOVIE'
        : (totalEpisodes > 0 ? 'SUB · $totalEpisodes EPS' : 'SUB · ONGOING');
    final statusLbl = status == MyListStatus.completed ? 'Tamat' : 'Ongoing';
    return AnimeItem(
      id: animeId,
      title: title,
      japaneseTitle: japaneseTitle,
      rating: rating,
      releaseYear: releaseYear,
      genres: genres,
      description: description,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl.isNotEmpty ? backdropUrl : posterUrl,
      episodeInfo: epInfo,
      statusLabel: statusLbl,
      aniListId: aniListId,
      hasVideoAvailable: hasVideoAvailable,
    );
  }

  MyListEntry copyWith({
    String? canonicalKey,
    String? animeId,
    int? aniListId,
    String? title,
    String? japaneseTitle,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    int? releaseYear,
    List<String>? genres,
    String? description,
    int? totalEpisodes,
    int? watchedEpisode,
    String? currentEpisodeTitle,
    bool clearCurrentEpisodeTitle = false,
    MyListStatus? status,
    bool? hasVideoAvailable,
    DateTime? updatedAt,
  }) {
    return MyListEntry(
      canonicalKey: canonicalKey ?? this.canonicalKey,
      animeId: animeId ?? this.animeId,
      aniListId: aniListId ?? this.aniListId,
      title: title ?? this.title,
      japaneseTitle: japaneseTitle ?? this.japaneseTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      releaseYear: releaseYear ?? this.releaseYear,
      genres: genres ?? this.genres,
      description: description ?? this.description,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      watchedEpisode: watchedEpisode ?? this.watchedEpisode,
      currentEpisodeTitle: clearCurrentEpisodeTitle
          ? null
          : (currentEpisodeTitle ?? this.currentEpisodeTitle),
      status: status ?? this.status,
      hasVideoAvailable: hasVideoAvailable ?? this.hasVideoAvailable,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canonicalKey': canonicalKey,
      'animeId': animeId,
      'aniListId': aniListId,
      'title': title,
      'japaneseTitle': japaneseTitle,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'rating': rating,
      'releaseYear': releaseYear,
      'genres': genres,
      'description': description,
      'totalEpisodes': totalEpisodes,
      'watchedEpisode': watchedEpisode,
      'currentEpisodeTitle': currentEpisodeTitle,
      'status': status.name,
      'hasVideoAvailable': hasVideoAvailable,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MyListEntry.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? 'saved';
    final status = MyListStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => MyListStatus.saved,
    );
    final rawGenres = json['genres'];
    final genres = rawGenres is List
        ? rawGenres.map((e) => e.toString()).toList()
        : const <String>[];
    final parsedDate = DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
        DateTime.now();

    return MyListEntry(
      canonicalKey: json['canonicalKey']?.toString() ?? '',
      animeId: json['animeId']?.toString() ?? '',
      aniListId: (json['aniListId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      japaneseTitle: json['japaneseTitle']?.toString() ?? '',
      posterUrl: json['posterUrl']?.toString() ?? '',
      backdropUrl: json['backdropUrl']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      releaseYear: (json['releaseYear'] as num?)?.toInt() ?? 0,
      genres: genres,
      description: json['description']?.toString() ?? '',
      totalEpisodes: (json['totalEpisodes'] as num?)?.toInt() ?? 0,
      watchedEpisode: (json['watchedEpisode'] as num?)?.toInt() ?? 0,
      currentEpisodeTitle: json['currentEpisodeTitle']?.toString(),
      status: status,
      hasVideoAvailable: json['hasVideoAvailable'] == true,
      updatedAt: parsedDate,
    );
  }
}
