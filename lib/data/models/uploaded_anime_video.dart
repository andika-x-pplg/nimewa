/// Data structure for videos explicitly uploaded or managed by the app owner.
/// Connected directly to an AniList anime ID and specific season number.
class UploadedAnimeVideo {
  final int aniListId;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeTitle;
  final String videoUrl;
  final String? uploader;
  final DateTime uploadedAt;

  const UploadedAnimeVideo({
    required this.aniListId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.videoUrl,
    this.uploader = 'Owner',
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'aniListId': aniListId,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
        'episodeTitle': episodeTitle,
        'videoUrl': videoUrl,
        'uploader': uploader,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory UploadedAnimeVideo.fromJson(Map<String, dynamic> json) {
    return UploadedAnimeVideo(
      aniListId: json['aniListId'] as int,
      seasonNumber: json['seasonNumber'] as int,
      episodeNumber: json['episodeNumber'] as int,
      episodeTitle: json['episodeTitle'] as String,
      videoUrl: json['videoUrl'] as String,
      uploader: json['uploader'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

