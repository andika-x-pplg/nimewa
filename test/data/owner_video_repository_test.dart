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
      expect(ep1.videoUrl, contains('Solo'));
      expect(ep1.uploader, isNotEmpty);
    });

    test('strictly rejects unuploaded seasons and prevents cross-season fallback', () {
      final repo = OwnerVideoRepository.instance;
      // An unuploaded anime season (ID 999998) has no uploaded videos
      expect(repo.hasVideosForAnime(999998), isFalse);
      expect(repo.getVideo(999998, 4, 1), isNull);

      final streamUrl = AnimeStreamResolver.resolveStreamUrl(
        animeId: '999998',
        animeTitle: 'Unreleased Anime: Season 4',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );

      // Must be empty to prevent season bleeding
      expect(streamUrl, isEmpty);

      // Audit logger must record rejection with reason
      final logs = StreamAuditLogger.instance.recentLogs;
      expect(logs.any((l) => !l.isAccepted), isTrue);
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

    test('One Punch Man S1 and S2 resolve to Japanese audio with Sub Indo/Eng Sub without German dub', () {
      final repo = OwnerVideoRepository.instance;
      // S1 Ep 1
      final opmS1Ep1 = repo.getVideo(21087, 1, 1);
      expect(opmS1Ep1, isNotNull);
      expect(opmS1Ep1!.videoUrl, contains('opm-s1/OPM-BD-01.mp4'));
      expect(opmS1Ep1.videoUrl, isNot(contains('Der%20St%C3%A4rkste')));
      expect(opmS1Ep1.videoUrl, isNot(contains('Gemischt')));

      // S1 Ep 12
      final opmS1Ep12 = repo.getVideo(21087, 1, 12);
      expect(opmS1Ep12, isNotNull);
      expect(opmS1Ep12!.videoUrl, contains('opm-s1/OPM-BD-12.mp4'));

      // S2 Ep 1
      final opmS2Ep1 = repo.getVideo(102194, 2, 1);
      expect(opmS2Ep1, isNotNull);
      expect(opmS2Ep1!.videoUrl, contains('opm-s2/O-S2-BD-01.mp4'));
      expect(opmS2Ep1.videoUrl, isNot(contains('R%C3%BCckkehr')));
      expect(opmS2Ep1.videoUrl, isNot(contains('Gemischt')));
    });

    test('Demon Slayer, Tokyo Revengers S3, and FMAB resolve to authentic Japanese audio streams', () {
      final repo = OwnerVideoRepository.instance;
      // Demon Slayer S1
      final kny1 = repo.getVideo(101922, 1, 1);
      expect(kny1, isNotNull);
      expect(kny1!.videoUrl, contains('knys1/KNYS1-E1.mp4'));
      expect(kny1.videoUrl, isNot(contains('Grausamkeit')));
      expect(kny1.videoUrl, isNot(contains('Gemischt')));

      // Tokyo Revengers S3
      final trS3 = repo.getVideo(163539, 3, 1);
      expect(trS3, isNotNull);
      expect(trS3!.videoUrl, contains('kyotoavenrgesrsamputahahaha'));
      expect(trS3.videoUrl, isNot(contains('animeflv')));

      // FMAB
      final fmab = repo.getVideo(5114, 1, 1);
      expect(fmab, isNotNull);
      expect(fmab!.videoUrl, contains('ma-fullmetal-alchemist-2009'));
      expect(fmab.videoUrl, isNot(contains('1st%20Dubbing')));
    });
  });
}

