import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/anime_subtitle_service.dart';
import 'package:nimeva/data/services/stream_audit_logger.dart';
import 'package:nimeva/data/services/subtitle_offset_repository.dart';
import 'package:nimeva/data/services/subtitle_sync_validator.dart';

void main() {
  group('AnimeStreamResolver Tests', () {
    test('resolves Demon Slayer Season 1 sequential episodes accurately (Cruelty Ep 1, Ep 2, Ep 10)', () {
      final ep1Server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370', // Kitsu ID for Kimetsu no Yaiba
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      // Episode 1 must be authentic Japanese audio mobile MP4
      expect(ep1Server1, contains('S01E01'));
      expect(ep1Server1, contains('.mp4'));
      expect(ep1Server1, isNot(contains('sintel')));
      expect(ep1Server1, isNot(contains('oceans')));

      final ep1Server3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370',
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 3 (Otaku)',
        episodeNumber: 1,
      );
      expect(ep1Server3, contains('S01E01'));
      expect(ep1Server3, contains('.mp4'));

      final ep2Server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370',
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      // Episode 2 must return authentic Season 1 Episode 2 in playable MP4 format
      expect(ep2Server1, contains('02'));
      expect(ep2Server1, contains('Lehrmeister'));
      expect(ep2Server1, contains('.mp4'));
      expect(ep2Server1, isNot(equals(ep1Server1)));

      final ep10Server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370',
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      // Episode 10 must return authentic Season 1 Episode 10 in playable MP4 format
      expect(ep10Server1, contains('10'));
      expect(ep10Server1, contains('Immer%20zusammen'));
      expect(ep10Server1, contains('.mp4'));
      expect(ep10Server1, isNot(contains('GATON%202.3'))); // Not Season 2!
      expect(ep10Server1, isNot(equals(ep2Server1)));

      final japaneseTitle = AnimeStreamResolver.detectAnimeKey('unknown-id', '鬼滅の刃');
      expect(japaneseTitle, equals('demon-slayer'));
    });

    test('resolves Attack on Titan to authentic Shingeki no Kyojin streams for Ep 1, 2, & 10', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '7442',
        animeTitle: 'Attack on Titan',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('Shingeki'));
      expect(ep1, contains('Cap%2001'));
      expect(ep1, contains('.mp4'));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '7442',
        animeTitle: 'Attack on Titan',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, contains('Shingeki'));
      expect(ep2, contains('Cap%2002'));
      expect(ep2, isNot(equals(ep1)));

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '7442',
        animeTitle: 'Attack on Titan',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, contains('Cap%2010'));
      expect(ep10, isNot(equals(ep2)));

      final japaneseKey = AnimeStreamResolver.detectAnimeKey('7442', '進撃の巨人');
      expect(japaneseKey, equals('attack-on-titan'));
    });

    test('resolves Death Note distinct episodes 1, 2, and 10', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '1376',
        animeTitle: 'Death Note',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('E01'));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '1376',
        animeTitle: 'Death Note',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, contains('E02'));
      expect(ep2, isNot(equals(ep1)));

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '1376',
        animeTitle: 'Death Note',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, contains('E10'));
      expect(ep10, isNot(equals(ep2)));
    });

    test('resolves Naruto Season 1 distinct episodes 1, 2, and 10 sequentially without jumping', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '3936',
        animeTitle: 'Naruto Shippuden',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, anyOf(contains('Enter%20Naruto'), contains('Naruto%20-%20001')));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '3936',
        animeTitle: 'Naruto Shippuden',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, anyOf(contains('naruto%20episode%202'), contains('Naruto%20-%20002')));
      expect(ep2, isNot(equals(ep1)));

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '3936',
        animeTitle: 'Naruto Shippuden',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, anyOf(contains('S01E10'), contains('Naruto%20-%20010')));
      expect(ep10, isNot(contains('153'))); // Not Episode 153!
    });

    test('resolves Jujutsu Kaisen to authentic Season 1 streams for Ep 1, 2, and 10', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, anyOf(contains('Jujutsu'), contains('Jujustu')));
      expect(ep1, contains('.mp4'));
      expect(ep1, contains('S01E01'));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, anyOf(contains('Jujutsu'), contains('Jujustu')));
      expect(ep2, contains('S01E02'));

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, anyOf(contains('Jujutsu'), contains('Jujustu')));
      expect(ep10, contains('S01E10'));
      expect(ep10, isNot(equals(ep1)));
    });

    test('resolves Tokyo Ghoul Season 1 to 12 authentic episodes without falling back to movie', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '20605',
        animeTitle: 'Tokyo Ghoul',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('tokyo-ghoul-s01-sm'));
      expect(ep1, contains('S01E01.mp4'));
      expect(ep1, isNot(contains('TokyoGhoulS.mp4')));

      final ep12 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '20605',
        animeTitle: 'Tokyo Ghoul',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 12,
      );
      expect(ep12, contains('tokyo-ghoul-s01-sm'));
      expect(ep12, contains('S01E012.mp4'));
      expect(ep12, isNot(equals(ep1)));
    });

    test('resolves Chainsaw Man Season 1 episodes 1 and 10 accurately', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '40321',
        animeTitle: 'Chainsaw Man',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('Chainsaw_Man_S1_-_01'));
      expect(ep1, contains('.mp4'));

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '40321',
        animeTitle: 'Chainsaw Man',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, contains('Chainsaw_Man_S1_-_10'));
      expect(ep10, isNot(equals(ep1)));
    });

    test('resolves Solo Leveling to Season 1 without jumping to Season 2', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '46231',
        animeTitle: 'Solo Leveling',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('S01E01')); // Season 1 Episode 1
      expect(ep1, isNot(contains('s-02-e-01'))); // NOT Season 2!

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '46231',
        animeTitle: 'Solo Leveling',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, contains('S01E10')); // Season 1 Episode 10
      expect(ep10, isNot(equals(ep1)));
    });

    test('resolves Tokyo Revengers, Frieren, and My Hero Academia without collisions', () {
      final tokyo = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'tokyo-revengers',
        animeTitle: 'Tokyo Revengers',
        server: 'Server 1 (Fast HD)',
      );
      expect(tokyo, contains('Tokyo'));
      expect(tokyo, contains('Revengers'));

      final tokyoS2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'tokyo-revengers-s2',
        animeTitle: 'Tokyo Revengers Season 2',
        server: 'Server 1 (Fast HD)',
      );
      expect(tokyoS2, contains('Tokyo%20Revengers'));
      expect(tokyoS2, contains('S02'));

      final tokyoS3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'tokyo-revengers-s3',
        animeTitle: 'Tokyo Revengers Season 3',
        server: 'Server 1 (Fast HD)',
      );
      expect(tokyoS3, contains('Tokyo%20Revengers%20Tenjiku'));

      expect(
        AnimeStreamResolver.hasCompleteEpisodes('season-4-fallback', 'Unknown Anime Season 4'),
        isFalse,
      );
      final fallbackS4 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'season-4-fallback',
        animeTitle: 'Unknown Anime Season 4',
        server: 'Server 1 (Fast HD)',
      );
      expect(fallbackS4, isEmpty);

      final frieren = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'frieren',
        animeTitle: 'Sousou no Frieren',
        server: 'Server 1 (Fast HD)',
      );
      expect(frieren, contains('Frieren'));

      final mha = AnimeStreamResolver.resolveStreamUrl(
        animeId: '11469',
        animeTitle: 'Boku no Hero Academia',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(mha, contains('Boku_no_Hero_Academia'));
      expect(mha, contains('001'));
    });

    test('resolves Spy x Family Season 1 episodes accurately in MP4 format', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41992',
        animeTitle: 'Spy x Family',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('SPY%20x%20FAMILY%20-%20S01E01'));
      expect(ep1, contains('.mp4'));

      final ep12 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41992',
        animeTitle: 'Spy x Family',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 12,
      );
      expect(ep12, contains('SPY%20x%20FAMILY%20-%20S01E12'));
      expect(ep12, contains('.mp4'));
      expect(ep12, isNot(equals(ep1)));
    });

    test('resolves Bleach, Hunter x Hunter, and Fullmetal Alchemist to authentic 23-24m MP4 streams', () {
      final bleach1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'bleach',
        animeTitle: 'Bleach',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(bleach1, contains('.mp4'));
      expect(bleach1, contains('Bleach%20S01E01'));

      final bleach2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'bleach',
        animeTitle: 'Bleach',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(bleach2, contains('Bleach%20S01E02'));
      expect(bleach2, isNot(equals(bleach1)));

      final hxh1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'hunter-x-hunter',
        animeTitle: 'Hunter x Hunter',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(hxh1, contains('hxh11'));
      expect(hxh1, contains('001.ia.mp4'));

      final hxh2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'hunter-x-hunter',
        animeTitle: 'Hunter x Hunter',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(hxh2, contains('002.ia.mp4'));
      expect(hxh2, isNot(equals(hxh1)));

      final fmab1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'fullmetal-alchemist',
        animeTitle: 'Fullmetal Alchemist: Brotherhood',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(fmab1, contains('Fullmetal%20Alchemist%20Brotherhood%20S01E01'));
      expect(fmab1, contains('.mp4'));

      final fmab2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'fullmetal-alchemist',
        animeTitle: 'Fullmetal Alchemist: Brotherhood',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(fmab2, contains('Fullmetal%20Alchemist%20Brotherhood%20S01E02'));
      expect(fmab2, isNot(equals(fmab1)));
    });

    test('resolves full-length anime movies with dedicated authentic feature streams', () {
      final jjk0 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'jujutsu-kaisen-0',
        animeTitle: 'Jujutsu Kaisen 0 Movie',
        server: 'Server 1 (Fast HD)',
      );
      expect(jjk0, contains('Jujustu%20Kaisen%200'));
      expect(jjk0, contains('.mp4'));

      final yourName = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'your-name',
        animeTitle: 'Kimi no Na wa. (Your Name)',
        server: 'Server 1 (Fast HD)',
      );
      expect(yourName, contains('Kimi%20no%20na%20wa'));
      expect(yourName, contains('.mp4'));

      final csmMovie = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'chainsaw-man-movie',
        animeTitle: 'Chainsaw Man: Reze Arc',
        server: 'Server 1 (Fast HD)',
      );
      expect(csmMovie, contains('ssstwitter.com_1763419408768.mp4'));

      final knyMovie = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'kimetsu-no-yaiba-infinity',
        animeTitle: 'Kimetsu no Yaiba: Infinity Castle',
        server: 'Server 1 (Fast HD)',
      );
      expect(knyMovie, contains('Rengoku%20Kyojurou'));

      final haikyuuMovie = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'haikyuu-movie',
        animeTitle: 'Haikyuu!! The Dumpster Battle',
        server: 'Server 1 (Fast HD)',
      );
      expect(haikyuuMovie, contains('Dumpster%20Battle'));

      final gintama = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'gintama-final',
        animeTitle: 'Gintama: The Final',
        server: 'Server 1 (Fast HD)',
      );
      expect(gintama, contains('Gintama%20-%20The%20FINAL.mp4'));

      final silentVoice = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'silent-voice',
        animeTitle: 'A Silent Voice',
        server: 'Server 1 (Fast HD)',
      );
      expect(silentVoice, contains('Silent%20Voice'));
    });

    test('resolves Steins;Gate, Dan Da Dan, and Re:Zero sequential episodes', () {
      final sg1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'steins-gate',
        animeTitle: 'Steins;Gate',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(sg1, contains('Steins%3BGate%20-%2001.mp4'));

      final sg2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'steins-gate',
        animeTitle: 'Steins;Gate',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(sg2, contains('Steins%3BGate%20-%2002.mp4'));
      expect(sg2, isNot(equals(sg1)));

      final ddd1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'dandadan',
        animeTitle: 'Dandadan',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ddd1, contains('dandadan_S01-E01.mp4'));

      final rz1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'rezero',
        animeTitle: 'Re:Zero',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(rz1, contains('ReZeroEnglishDubSeason1Episode1.ia.mp4'));
    });

    test('never returns generic dummy 3D trailers for unknown titles', () {
      final fallback = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'unknown-anime-999',
        animeTitle: 'Unknown Random Title',
        server: 'Server 1 (Fast HD)',
      );
      expect(fallback, isNot(contains('sintel')));
      expect(fallback, isNot(contains('oceans')));
      expect(fallback, isNot(contains('BigBuckBunny')));
      expect(fallback, isEmpty);
    });

    test('season-specific routing: DandaDan S1 stays S1, S2 routes to S2', () {
      // S1 — id=dandadan, title=Dandadan
      final dddS1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'dandadan',
        animeTitle: 'Dandadan',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(dddS1, contains('S01-E01'));
      expect(dddS1, isNot(contains('S02')));

      // S2 — title contains Season 2
      final dddS2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'dandadan',
        animeTitle: 'Dandadan Season 2',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(dddS2, contains('S02-E01'));

      // S2 — id contains -s2
      final dddS2byId = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'dandadan-s2',
        animeTitle: 'Dandadan',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(dddS2byId, contains('S02-E01'));
    });

    test('season-specific routing: JJK S3 by id routes to jujutsu-kaisen-s3 and returns empty per atomicity', () {
      final key = AnimeStreamResolver.detectAnimeKey('jujutsu-kaisen-s3', 'Jujutsu Kaisen');
      expect(key, equals('jujutsu-kaisen-s3'));

      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'jujutsu-kaisen-s3',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, isEmpty);
    });

    test('season-specific routing: Solo Leveling S2 by id routes to solo-leveling-s2 and returns empty per atomicity', () {
      final key = AnimeStreamResolver.detectAnimeKey('solo-leveling-s2', 'Solo Leveling');
      expect(key, equals('solo-leveling-s2'));

      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'solo-leveling-s2',
        animeTitle: 'Solo Leveling',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, isEmpty);
    });

    test('season-specific routing: Bleach TYBW by id routes to bleach-tybw and returns empty per atomicity', () {
      final key = AnimeStreamResolver.detectAnimeKey('bleach-tybw-part3', 'Bleach: Thousand Year Blood War');
      expect(key, equals('bleach-tybw'));

      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'bleach-tybw-part3',
        animeTitle: 'Bleach: Thousand Year Blood War',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, isEmpty);
    });

    test('season-specific routing: Frieren S2 by id routes to frieren-s2 and returns empty per atomicity', () {
      final key = AnimeStreamResolver.detectAnimeKey('frieren-s2', 'Sousou no Frieren');
      expect(key, equals('frieren-s2'));

      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'frieren-s2',
        animeTitle: 'Sousou no Frieren Season 2',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, isEmpty);
    });

    test('season-specific routing: Frieren S1 (no season in title) stays frieren', () {
      final key = AnimeStreamResolver.detectAnimeKey('frieren', 'Sousou no Frieren');
      expect(key, equals('frieren'));
    });

    test('season-specific routing: Demon Slayer S1, S2, S3, S4 route to different stream collections', () {
      final s1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'demon-slayer',
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      final s2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'demon-slayer-s2',
        animeTitle: 'Kimetsu no Yaiba: Entertainment District Arc',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      final s3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'demon-slayer-s3',
        animeTitle: 'Kimetsu no Yaiba: Swordsmith Village Arc',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      final s4 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'demon-slayer-s4',
        animeTitle: 'Kimetsu no Yaiba Season 4 Hashira Training',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );

      // Verify each season has its distinct stream URL
      expect(s1, contains('Demon%20Slayer'));
      expect(s1, contains('S01E01'));
      expect(s2, contains('S02'));
      expect(s2, isNot(contains('S01')));
      expect(s3, contains('S03'));
      expect(s3, isNot(contains('S01')));
      expect(s4, isNot(contains('S01E01')));
    });

    test('atomicity rule: incomplete or arbitrary anime has hasCompleteEpisodes false and resolves to empty', () {
      expect(
        AnimeStreamResolver.hasCompleteEpisodes('arbitrary-anime-s2', 'My Random Anime Season 2'),
        isFalse,
      );
      final genericS2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'arbitrary-anime-s2',
        animeTitle: 'My Random Anime Season 2',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(genericS2, isEmpty);

      expect(
        AnimeStreamResolver.hasCompleteEpisodes('arbitrary-anime-s3', 'My Random Anime Season 3'),
        isFalse,
      );
      final genericS3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'arbitrary-anime-s3',
        animeTitle: 'My Random Anime Season 3',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(genericS3, isEmpty);
    });

    test('atomicity rule: authentic complete seasons have hasCompleteEpisodes true and play real streams', () {
      expect(
        AnimeStreamResolver.hasCompleteEpisodes('demon-slayer-s2', 'Kimetsu no Yaiba Entertainment District Arc'),
        isTrue,
      );
      final knyS2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'demon-slayer-s2',
        animeTitle: 'Kimetsu no Yaiba Entertainment District Arc',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(knyS2, contains('S02'));

      expect(
        AnimeStreamResolver.hasCompleteEpisodes('tokyo-revengers-s2', 'Tokyo Revengers Season 2'),
        isTrue,
      );
      expect(
        AnimeStreamResolver.hasCompleteEpisodes('tokyo-revengers-s3', 'Tokyo Revengers Season 3'),
        isTrue,
      );
    });

    test('resolves streams strictly matching AniList ID without season bleeding', () {
      // Tokyo Revengers Season 1 (AniList ID 120120)
      final trS1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '120120',
        animeTitle: 'Tokyo Revengers',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(trS1, contains('Tokyo%20Revengers'));

      // Tokyo Revengers Season 2 Christmas Showdown (AniList ID 142853)
      final trS2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '142853',
        animeTitle: 'Tokyo Revengers: Christmas Showdown',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(trS2, contains('Tokyo%20Revengers'));
      expect(trS2, contains('S02'));

      // Tokyo Revengers Season 3 Tenjiku Arc (AniList ID 163539)
      final trS3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '163539',
        animeTitle: 'Tokyo Revengers: Tenjiku Arc',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(trS3, contains('Tokyo%20Revengers%20Tenjiku'));

      // Unuploaded Season (AniList ID 999998 - Incomplete / No Episode)
      final unuploadedS4 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '999998',
        animeTitle: 'Unreleased Anime Season 4',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      // Strictly empty, no fallback to Season 1 or 2!
      expect(unuploadedS4, isEmpty);
      expect(AnimeStreamResolver.hasCompleteEpisodes('999998', 'Unreleased Anime Season 4'), isFalse);
    });

    test('logs audit records for stream resolution candidates', () {
      StreamAuditLogger.instance.clear();

      AnimeStreamResolver.resolveStreamUrl(
        animeId: '120120',
        animeTitle: 'Tokyo Revengers',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );

      final logs = StreamAuditLogger.instance.recentLogs;
      expect(logs, isNotEmpty);
      expect(logs.any((l) => l.searchedTitle.contains('Tokyo Revengers')), isTrue);
      expect(logs.any((l) => l.isAccepted == true), isTrue);
    });
  });

  group('AnimeSubtitleService Tests', () {
    test('returns Indonesian subtitle cues for Demon Slayer Ep 1', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        position: const Duration(seconds: 4),
      );
      expect(sub, contains('Nezuko'));
      expect(sub, isNotEmpty);
    });

    test('returns Indonesian subtitle cues for Demon Slayer Ep 2', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 2,
        position: const Duration(seconds: 20),
      );
      expect(sub, contains('Nezuko'));
      expect(sub, isNotEmpty);
    });

    test('returns episode-accurate Indonesian cues for Demon Slayer Ep 10 without leaking Ep 1 dialogue', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 10,
        position: const Duration(seconds: 4),
      );
      expect(sub, contains('Demon Slayer'));
      expect(sub, contains('Episode 10'));
      expect(sub, isNot(contains('Kie'))); // Must NOT show Episode 1 Kie dialogue on Episode 10!
    });

    test('returns Indonesian subtitle cues for Attack on Titan Ep 1', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'attack-on-titan',
        episodeNumber: 1,
        position: const Duration(seconds: 12),
      );
      expect(sub, contains('Titan'));
      expect(sub, isNotEmpty);
    });

    test('returns Indonesian subtitle cues for Tokyo Ghoul Ep 1 with episodic season title', () {
      final header = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'tokyo-ghoul',
        episodeNumber: 1,
        position: const Duration(seconds: 4),
      );
      expect(header, contains('Tokyo Ghoul'));
      expect(header, contains('Season 1 - Episode 1'));
      expect(header, isNot(contains('Full Movie')));

      final dialogue = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'tokyo-ghoul',
        episodeNumber: 1,
        position: const Duration(seconds: 18),
      );
      expect(dialogue, isNotEmpty);
      expect(dialogue, anyOf(contains('Kaneki'), contains('Rize'), contains('Anteiku'), contains('Ghoul')));
    });

    test('returns Indonesian subtitle cues for One Punch Man Ep 1', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'one-punch-man',
        episodeNumber: 1,
        position: const Duration(seconds: 18),
      );
      expect(sub, isNotEmpty);
      expect(sub, anyOf(contains('Saitama'), contains('Genos'), contains('Vaccine Man')));
    });

    test('returns empty string when position is outside active dialogue cues', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        position: const Duration(seconds: 5000),
      );
      expect(sub, isEmpty);
    });

    test('exports and parses SubRip (.srt) and WebVTT (.vtt) with accurate zero-based timestamps', () {
      final testCues = [
        const SubtitleCue(
          start: Duration(seconds: 0),
          end: Duration(seconds: 8),
          text: '[Sub Indo] Kimetsu no Yaiba - Episode 1',
        ),
        const SubtitleCue(
          start: Duration(seconds: 22, milliseconds: 500),
          end: Duration(seconds: 27, milliseconds: 500),
          text: 'Tanjiro: Nezuko, bertahanlah!',
        ),
      ];

      // Export to SRT
      final srt = AnimeSubtitleService.exportToSrt(testCues);
      expect(srt, contains('00:00:00,000 --> 00:00:08,000'));
      expect(srt, contains('00:00:22,500 --> 00:00:27,500'));
      expect(srt, contains('Tanjiro: Nezuko, bertahanlah!'));

      // Parse back from SRT
      final parsedSrt = AnimeSubtitleService.parseFromSrt(srt);
      expect(parsedSrt.length, equals(2));
      expect(parsedSrt[0].start, equals(Duration.zero));
      expect(parsedSrt[1].start, equals(const Duration(seconds: 22, milliseconds: 500)));
      expect(parsedSrt[1].text, equals('Tanjiro: Nezuko, bertahanlah!'));

      // Export to VTT
      final vtt = AnimeSubtitleService.exportToVtt(testCues);
      expect(vtt, startsWith('WEBVTT'));
      expect(vtt, contains('00:00:22.500 --> 00:00:27.500'));

      // Parse back from VTT
      final parsedVtt = AnimeSubtitleService.parseFromVtt(vtt);
      expect(parsedVtt.length, equals(2));
      expect(parsedVtt[1].start, equals(const Duration(seconds: 22, milliseconds: 500)));
    });

    test('SubtitleOffsetRepository stores, adjusts by 0.1s, and resets offsets per video', () {
      final repo = SubtitleOffsetRepository.instance;
      repo.clear();

      const videoKey = 'one-punch-man_ep1';
      expect(repo.getOffset(videoKey), equals(0.0));

      // Adjust +0.1s twice
      repo.adjustOffset(videoKey, 0.1);
      expect(repo.getOffset(videoKey), equals(0.1));
      repo.adjustOffset(videoKey, 0.1);
      expect(repo.getOffset(videoKey), equals(0.2));

      // Adjust -0.1s
      repo.adjustOffset(videoKey, -0.1);
      expect(repo.getOffset(videoKey), equals(0.1));

      // Reset
      repo.resetOffset(videoKey);
      expect(repo.getOffset(videoKey), equals(0.0));
    });

    test('SubtitleSyncValidator verifies time delta before and after alignment correction', () {
      // 1. Demon Slayer Ep 1
      final knyReport = SubtitleSyncValidator.verifySync(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        printToConsole: false,
      );
      // Before correction: subtitle was at 8.0s, audio at 22.5s (delta = -14.5s, early!)
      expect(knyReport.deltaBeforeCorrectionSeconds, equals(-14.5));
      expect(knyReport.autoAlignmentShiftSeconds, equals(14.5));
      expect(knyReport.deltaAfterCorrectionSeconds, equals(0.0));
      expect(knyReport.isSynchronized, isTrue);
      expect(knyReport.firstDialogue, contains('Nezuko'));
      expect(knyReport.logOutput, contains('SINKRON SEMPURNA 0.0s'));

      // 2. Attack on Titan Ep 1
      final aotReport = SubtitleSyncValidator.verifySync(
        animeKey: 'attack-on-titan',
        episodeNumber: 1,
        printToConsole: false,
      );
      expect(aotReport.deltaBeforeCorrectionSeconds, equals(-10.0));
      expect(aotReport.autoAlignmentShiftSeconds, equals(10.0));
      expect(aotReport.deltaAfterCorrectionSeconds, equals(0.0));
      expect(aotReport.isSynchronized, isTrue);

      // 3. One Punch Man Ep 1
      final opmReport = SubtitleSyncValidator.verifySync(
        animeKey: 'one-punch-man',
        episodeNumber: 1,
        printToConsole: false,
      );
      expect(opmReport.deltaBeforeCorrectionSeconds, equals(-10.0));
      expect(opmReport.deltaAfterCorrectionSeconds, equals(0.0));
      expect(opmReport.isSynchronized, isTrue);

      // 4. Solo Leveling Ep 1
      final soloReport = SubtitleSyncValidator.verifySync(
        animeKey: 'solo-leveling',
        episodeNumber: 1,
        printToConsole: false,
      );
      expect(soloReport.deltaBeforeCorrectionSeconds, equals(-9.5));
      expect(soloReport.deltaAfterCorrectionSeconds, equals(0.0));
      expect(soloReport.isSynchronized, isTrue);
    });

    test('manual offset shifts subtitle playback position accurately in 0.1s increments', () {
      // Audio speech onset for Demon Slayer Ep 1 is at 22.5s
      // With 0.0s manual offset, dialogue cue appears at 22.5s
      final normal = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        position: const Duration(milliseconds: 22500),
        manualOffsetSeconds: 0.0,
      );
      expect(normal, contains('Tanjiro: Kenapa harus jadi begini'));

      // If user sets +1.0s delay (subtitle delayed/muncul lebih lambat):
      // At 22.5s it hasn't appeared yet (effectivePosition = 21.5s, which is still in header)
      final delayedAt225 = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        position: const Duration(milliseconds: 22500),
        manualOffsetSeconds: 1.0,
      );
      expect(delayedAt225, contains('[Sub Indo] Demon Slayer'));

      // At 23.5s, with +1.0s delay, effectivePosition = 22.5s, so Tanjiro's line appears!
      final delayedAt235 = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        position: const Duration(milliseconds: 23500),
        manualOffsetSeconds: 1.0,
      );
      expect(delayedAt235, contains('Tanjiro: Kenapa harus jadi begini'));
    });
  });
}
