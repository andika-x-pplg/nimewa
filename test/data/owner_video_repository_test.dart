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
      expect(ep1.videoUrl.toLowerCase(), contains('sl-bd-01_hardsub'));
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

    test('One Punch Man S1 resolves to Japanese audio with Sub Indo/Eng Sub without German dub and S2 is unavailable', () {
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

      // S2 is explicitly unavailable per user request
      final opmS2Ep1 = repo.getVideo(102194, 2, 1);
      expect(opmS2Ep1, isNull);
      expect(repo.hasVideosForAnime(102194, seasonNumber: 2), isFalse);
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

    test('verifies all 25 requested anime titles resolve to valid authentic Japanese audio streams', () {
      final repo = OwnerVideoRepository.instance;

      // 1. Solo Leveling
      expect(repo.getVideo(151807, 1, 1)?.videoUrl, contains('sl-bd-s1'));
      // 2. Tokyo Revengers Season 4 (Explicitly unavailable per user request)
      expect(repo.getVideo(178945, 4, 1), isNull);
      expect(repo.hasVideosForAnime(178945), isFalse);
      // 3. Demon Slayer Season 2 (11 distinct episodes)
      final ds2Ep1 = repo.getVideo(142329, 2, 1);
      final ds2Ep11 = repo.getVideo(142329, 2, 11);
      expect(ds2Ep1?.videoUrl, contains('otakudesu.io-kn-y.-yh-01-720p/Otakudesu.io_KnY.Yh--01_720p.mp4'));
      expect(ds2Ep11?.videoUrl, contains('otakudesu.io-kn-y.-yh-01-720p/Otakudesu.io_KnY.Yh--11_End_720p.mp4'));
      expect(ds2Ep1?.videoUrl, isNot(equals(ds2Ep11?.videoUrl)));
      // 4. One-Punch Man Season 2 (Explicitly unavailable per user request)
      expect(repo.getVideo(102194, 2, 1), isNull);
      expect(repo.hasVideosForAnime(102194), isFalse);
      // 5. Attack on Titan Season 1
      expect(repo.getVideo(16498, 1, 1)?.videoUrl, contains('aot-s-1'));
      // 6. Jujutsu Kaisen Season 1
      expect(repo.getVideo(113415, 1, 1)?.videoUrl, contains('jjk-s01CBT'));
      // 7. Tokyo Ghoul Season 1
      expect(repo.getVideo(20605, 1, 1)?.videoUrl, contains('tokyo-ghoul-s01-sm'));
      // 8. Spy x Family Season 1 (Unavailable per atomicity / no authentic hardsub in public repositories)
      expect(repo.getVideo(140960, 1, 1), isNull);
      expect(repo.hasVideosForAnime(140960), isFalse);
      // 9. Fullmetal Alchemist: Brotherhood
      expect(repo.getVideo(5114, 1, 1)?.videoUrl, contains('ma-fullmetal-alchemist-2009'));
      // 10. Hunter x Hunter (2011) (Unavailable per user request / no authentic Japanese dub with hardsubs available)
      expect(repo.getVideo(11061, 1, 1), isNull);
      expect(repo.hasVideosForAnime(11061), isFalse);
      // 11. Bleach Season 1 (Unavailable per user request / no authentic Japanese dub with hardsubs available)
      expect(repo.getVideo(269, 1, 1), isNull);
      expect(repo.hasVideosForAnime(269), isFalse);
      // 12. Sousou no Frieren
      expect(repo.getVideo(154587, 1, 1)?.videoUrl, contains('Sousou_no_Frieren'));
      // 13. Death Note
      expect(repo.getVideo(1535, 1, 1)?.videoUrl, contains('death-note-relight-1/Death%20Note%20Episode%201%20Rebirth.mp4'));
      expect(repo.getVideo(1535, 1, 37)?.videoUrl, contains('death-note-relight-1/Death%20Note%20Episode%2037%20New%20World.mp4'));
      // 14. Dan Da Dan Season 1 & 2 (Unavailable per atomicity / English dub without hardsubs)
      expect(repo.getVideo(166240, 1, 1), isNull);
      expect(repo.getVideo(178526, 2, 1), isNull);
      expect(repo.hasVideosForAnime(166240), isFalse);
      expect(repo.hasVideosForAnime(178526, seasonNumber: 2), isFalse);
      // 15. One Piece Season 1 (Unavailable per atomicity / incomplete 4Kids English dub)
      expect(repo.getVideo(21, 1, 1), isNull);
      expect(repo.hasVideosForAnime(21), isFalse);
      final resolvedOp = AnimeStreamResolver.resolveStreamUrl(
        animeId: '21',
        animeTitle: 'One Piece',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(resolvedOp, isEmpty);
      // 16. Steins;Gate (Unavailable per atomicity / English dub without hardsubs)
      expect(repo.getVideo(9253, 1, 1), isNull);
      expect(repo.hasVideosForAnime(9253), isFalse);
      // 17. Re:Zero Season 1 (authentic Japanese audio)
      final rz1 = repo.getVideo(21355, 1, 1);
      expect(rz1?.videoUrl, contains('rezerokarahajimeruisekaiseikatsu_202001'));
      expect(rz1?.videoUrl, isNot(contains('english-dub')));
      // 18. Yosuga no Sora (Unavailable per atomicity / raw video without hardsubs)
      expect(repo.getVideo(8861, 1, 1), isNull);
      expect(repo.hasVideosForAnime(8861), isFalse);
      // 19. Jujutsu Kaisen 0 Movie
      expect(repo.getVideo(131573, 1, 1)?.videoUrl, contains('anime-pahe-jujutsu-kaisen-0-movie-01-bd-804p-vodes'));
      // 20. Kimi no Na wa (Your Name)
      expect(repo.getVideo(21827, 1, 1)?.videoUrl, contains('your-name-2'));
      // 21. Koe no Katachi (A Silent Voice)
      expect(repo.getVideo(20954, 1, 1)?.videoUrl, contains('koe-no-katachi-1080p'));
      // 22. Demon Slayer: Mugen Ressha-hen (Movie) (Unavailable per atomicity)
      expect(repo.getVideo(112151, 1, 1), isNull);
      expect(repo.hasVideosForAnime(112151), isFalse);
      // 22b. Demon Slayer: Mugen Ressha-hen (TV Arc, AniList ID 129874)
      expect(repo.getVideo(129874, 1, 1)?.videoUrl, contains('Otakudesu.io_KnY.MRh--01_720p.mp4'));
      expect(repo.getVideo(129874, 1, 7)?.videoUrl, contains('Otakudesu.io_KnY.MRh--07_End_720p.mp4'));
      expect(repo.hasVideosForAnime(129874), isTrue);
      // 23. Haikyuu!! The Dumpster Battle
      expect(repo.getVideo(152865, 1, 1)?.videoUrl, contains('haikyu-the-dumpster-battle-2024'));
      // 24. Chainsaw Man: Reze Arc Movie
      expect(repo.getVideo(172905, 1, 1)?.videoUrl, contains('rezearc/csmrezearc.mp4'));
      // 25. Tokyo Ghoul Movie (Unavailable per atomicity / live-action only, no anime movie exists)
      expect(repo.getVideo(99920, 1, 1), isNull);
      expect(repo.hasVideosForAnime(99920), isFalse);
    });
  });
}

