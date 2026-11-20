import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/uploaded_anime_video.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/owner_video_repository.dart';
import 'package:nimeva/data/services/stream_audit_logger.dart';

void main() {
  group('OwnerVideoRepository Tests', () {
    setUp(() {
      OwnerVideoRepository.instance.resetToDefaults();
      StreamAuditLogger.instance.clear();
    });

    test('stores and retrieves owner uploaded video mapped to AniList ID and season', () {
      final repo = OwnerVideoRepository.instance;
      expect(repo.hasVideosForAnime(151807, seasonNumber: 1), isTrue);

      final ep1 = repo.getVideo(151807, 1, 1);
      expect(ep1, isNotNull);
      expect(ep1!.aniListId, equals(151807));
      expect(ep1.seasonNumber, equals(1));
      expect(ep1.episodeNumber, equals(1));
      expect(ep1.videoUrl, contains('Solo.Leveling'));
      expect(ep1.uploader, isNotEmpty);
    });

    test('strictly rejects unuploaded seasons and prevents cross-season fallback', () {
      final repo = OwnerVideoRepository.instance;
      // Tokyo Revengers Season 4 (AniList ID 178945) has no uploaded videos
      expect(repo.hasVideosForAnime(178945), isFalse);
      expect(repo.getVideo(178945, 4, 1), isNull);

      final streamUrl = AnimeStreamResolver.resolveStreamUrl(
        animeId: '178945',
        animeTitle: 'Tokyo Revengers: Season 4',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );

      // Must be empty to prevent season bleeding
      expect(streamUrl, isEmpty);

      // Audit logger must record rejection with reason
      final logs = StreamAuditLogger.instance.recentLogs;
      expect(logs.any((l) => !l.isAccepted && l.reason.contains('dinonaktifkan')), isTrue);
    });

    test('allows app owner to dynamically register self-hosted video and resolve it', () {
      final repo = OwnerVideoRepository.instance;
      const customAniListId = 999999;
      final newVideo = UploadedAnimeVideo(
        aniListId: customAniListId,
        seasonNumber: 1,
        episodeNumber: 1,
        episodeTitle: 'Custom Owner Episode 1 Sub Indo',
        videoUrl: 'https://cdn.nimeva.local/episodes/custom-ep1.mp4',
        uploader: 'NimevaAdmin',
        uploadedAt: DateTime(2026, 11, 20),
      );

      repo.registerVideo(newVideo);
      expect(repo.hasVideosForAnime(customAniListId), isTrue);

      final resolvedUrl = AnimeStreamResolver.resolveStreamUrl(
        animeId: customAniListId.toString(),
        animeTitle: 'Custom Anime Series',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );

      expect(resolvedUrl, equals('https://cdn.nimeva.local/episodes/custom-ep1.mp4'));

      final latestLog = StreamAuditLogger.instance.recentLogs.last;
      expect(latestLog.isAccepted, isTrue);
      expect(latestLog.candidateSource, contains('OwnerVideoRepository'));
    });

    test('rejects videos containing reaction or review in title per filter validator', () {
      final repo = OwnerVideoRepository.instance;
      const customAniListId = 888888;
      final reactionVideo = UploadedAnimeVideo(
        aniListId: customAniListId,
        seasonNumber: 1,
        episodeNumber: 1,
        episodeTitle: 'Episode 1 React and Discussion by Fans',
        videoUrl: 'https://cdn.nimeva.local/episodes/reaction-ep1.mp4',
        uploader: 'ThirdParty',
        uploadedAt: DateTime(2026, 11, 20),
      );

      repo.registerVideo(reactionVideo);

      final resolvedUrl = AnimeStreamResolver.resolveStreamUrl(
        animeId: customAniListId.toString(),
        animeTitle: 'Reaction Anime',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );

      expect(resolvedUrl, isEmpty);

      final latestLog = StreamAuditLogger.instance.recentLogs.last;
      expect(latestLog.isAccepted, isFalse);
      expect(latestLog.reason, contains('reaksi'));
    });
  });
}

