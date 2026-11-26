enum DownloadStatus {
  downloading,
  paused,
  completed,
  failed,
}

/// Represents a downloaded or in-progress anime episode video file.
class DownloadItem {
  final String id;
  final String animeId;
  final String title;
  final String posterUrl;
  final int episodeNumber;
  final String episodeTitle;
  final String streamUrl;
  final String filePath;
  final int receivedBytes;
  final int totalBytes;
  final DownloadStatus status;
  final DateTime updatedAt;

  const DownloadItem({
    required this.id,
    required this.animeId,
    required this.title,
    this.posterUrl = '',
    required this.episodeNumber,
    this.episodeTitle = '',
    required this.streamUrl,
    required this.filePath,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.downloading,
    required this.updatedAt,
  });

  double get progress {
    if (status == DownloadStatus.completed) return 1.0;
    if (totalBytes <= 0) return 0.0;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  String get formattedSize {
    String fmt(int bytes) {
      if (bytes <= 0) return '0 MB';
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }

    if (totalBytes > 0) {
      return '${fmt(receivedBytes)} / ${fmt(totalBytes)}';
    }
    return fmt(receivedBytes);
  }

  DownloadItem copyWith({
    int? receivedBytes,
    int? totalBytes,
    DownloadStatus? status,
    DateTime? updatedAt,
  }) {
    return DownloadItem(
      id: id,
      animeId: animeId,
      title: title,
      posterUrl: posterUrl,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      streamUrl: streamUrl,
      filePath: filePath,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animeId': animeId,
      'title': title,
      'posterUrl': posterUrl,
      'episodeNumber': episodeNumber,
      'episodeTitle': episodeTitle,
      'streamUrl': streamUrl,
      'filePath': filePath,
      'receivedBytes': receivedBytes,
      'totalBytes': totalBytes,
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    final statusName = (json['status'] ?? 'paused').toString();
    final parsedStatus = DownloadStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => DownloadStatus.paused,
    );
    // Downloads interrupted by app close resume cleanly as paused.
    final safeStatus = parsedStatus == DownloadStatus.downloading
        ? DownloadStatus.paused
        : parsedStatus;

    return DownloadItem(
      id: (json['id'] ?? '').toString(),
      animeId: (json['animeId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      posterUrl: (json['posterUrl'] ?? '').toString(),
      episodeNumber: (json['episodeNumber'] as num?)?.toInt() ?? 1,
      episodeTitle: (json['episodeTitle'] ?? '').toString(),
      streamUrl: (json['streamUrl'] ?? '').toString(),
      filePath: (json['filePath'] ?? '').toString(),
      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      status: safeStatus,
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

