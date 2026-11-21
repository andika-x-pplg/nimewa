/// Data structure for videos explicitly uploaded or managed by the app owner.
/// Connected directly to an AniList anime ID and specific season number.
class UploadedAnimeVideo {
  final int aniListId;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeTitle;
  final String videoUrl;
  final String? server3Url;
  final String? server4Url;
  final String? uploader;
  final DateTime uploadedAt;

  const UploadedAnimeVideo({
    required this.aniListId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.videoUrl,
    this.server3Url,
    this.server4Url,
    this.uploader = 'Owner',
    required this.uploadedAt,
  });

  String getUrlForServer(String server) {
    if (server.contains('Server 3') || server.toLowerCase().contains('otaku')) {
      final s3 = server3Url;
      if (s3 != null &&
          s3.isNotEmpty &&
          !s3.contains('dn72') &&
          !s3.contains('.ca.archive') &&
          !s3.contains('ia820602') &&
          !s3.contains('ia800505') &&
          !s3.contains('ia601508')) {
        return s3;
      }
      return videoUrl.replaceAll('/download/', '/cors/');
    }
    if (server.contains('Server 4') ||
        server.toLowerCase().contains('consumet') ||
        server.toLowerCase().contains('cloud')) {
      final s4 = server4Url;
      if (s4 != null &&
          s4.isNotEmpty &&
          !s4.contains('dn72') &&
          !s4.contains('.ca.archive') &&
          !s4.contains('ia820602') &&
          !s4.contains('ia800505') &&
          !s4.contains('ia601508')) {
        return s4;
      }
      return videoUrl;
    }
    return videoUrl;
  }

  Map<String, dynamic> toJson() => {
        'aniListId': aniListId,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
        'episodeTitle': episodeTitle,
        'videoUrl': videoUrl,
        'server3Url': server3Url,
        'server4Url': server4Url,
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
      server3Url: json['server3Url'] as String?,
      server4Url: json['server4Url'] as String?,
      uploader: json['uploader'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

