import 'anime_item.dart';

/// Persisted watch history record for an anime episode including exact
/// playback position in seconds so users can resume from where they left off.
class WatchHistoryEntry {
  final String canonicalKey;
  final String animeId;
  final int aniListId;
  final String title;
  final String posterUrl;
  final int episodeNumber;
  final String episodeTitle;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime watchedAt;

  const WatchHistoryEntry({
    required this.canonicalKey,
    required this.animeId,
    this.aniListId = 0,
    required this.title,
    this.posterUrl = '',
    required this.episodeNumber,
    this.episodeTitle = '',
    this.positionSeconds = 0,
    this.durationSeconds = 0,
    required this.watchedAt,
  });

  /// Formats [positionSeconds] as `MM:SS` or `HH:MM:SS` when >= 1 hour.
  String get formattedPosition {
    final safe = positionSeconds < 0 ? 0 : positionSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }

  double get progressFraction {
    if (durationSeconds <= 0) return 0.0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  AnimeItem toAnimeItem() {
    return AnimeItem(
      id: animeId,
      aniListId: aniListId,
      title: title,
      japaneseTitle: '',
      rating: 0.0,
      releaseYear: 0,
      genres: const [],
      description: '',
      posterUrl: posterUrl,
      backdropUrl: posterUrl,
      episodeInfo: 'EP $episodeNumber',
      hasVideoAvailable: true,
    );
  }

  WatchHistoryEntry copyWith({
    int? episodeNumber,
    String? episodeTitle,
    int? positionSeconds,
    int? durationSeconds,
    DateTime? watchedAt,
  }) {
    return WatchHistoryEntry(
      canonicalKey: canonicalKey,
      animeId: animeId,
      aniListId: aniListId,
      title: title,
      posterUrl: posterUrl,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canonicalKey': canonicalKey,
      'animeId': animeId,
      'aniListId': aniListId,
      'title': title,
      'posterUrl': posterUrl,
      'episodeNumber': episodeNumber,
      'episodeTitle': episodeTitle,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'watchedAt': watchedAt.toIso8601String(),
    };
  }

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WatchHistoryEntry(
      canonicalKey: (json['canonicalKey'] ?? '').toString(),
      animeId: (json['animeId'] ?? '').toString(),
      aniListId: (json['aniListId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      posterUrl: (json['posterUrl'] ?? '').toString(),
      episodeNumber: (json['episodeNumber'] as num?)?.toInt() ?? 1,
      episodeTitle: (json['episodeTitle'] ?? '').toString(),
      positionSeconds: (json['positionSeconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      watchedAt: DateTime.tryParse((json['watchedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

