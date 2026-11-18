import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/anime_subtitle_service.dart';

void main() {
  group('AnimeStreamResolver Tests', () {
    test('resolves Demon Slayer Season 1 sequential episodes accurately (Cruelty Ep 1, Ep 2, Ep 10)', () {
      final ep1Server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370', // Kitsu ID for Kimetsu no Yaiba
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      // Episode 1 must be Cruelty (full 23m 40s)
      expect(ep1Server1, contains('Cruelty'));
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
      expect(ep1, contains('Enter%20Naruto'));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '3936',
        animeTitle: 'Naruto Shippuden',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, contains('naruto%20episode%202'));
      expect(ep2, isNot(equals(ep1)));

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '3936',
        animeTitle: 'Naruto Shippuden',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, contains('S01E10'));
      expect(ep10, isNot(contains('153'))); // Not Episode 153!
    });

    test('resolves Jujutsu Kaisen to authentic Season 1 streams for Ep 1, 2, and 10', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('JUJUTSU%20KAISEN%20Season%201%20Episode%201'));
      expect(ep1, contains('.mp4'));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, contains('JUJUTSU%20KAISEN%20Season%201%20Episode%202'));
      expect(ep2, isNot(equals(ep1)));

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, contains('JUJUTSU%20KAISEN%20Season%201%20Episode%2010'));
      expect(ep10, isNot(equals(ep2)));
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
      expect(ep1, contains('%D0%A11%D0%AD01')); // Season 1 Episode 1
      expect(ep1, isNot(contains('s-02-e-01'))); // NOT Season 2!

      final ep10 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '46231',
        animeTitle: 'Solo Leveling',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 10,
      );
      expect(ep10, contains('%D0%A11%D0%AD10')); // Season 1 Episode 10
      expect(ep10, isNot(equals(ep1)));
    });

    test('resolves Tokyo Revengers, Frieren, and My Hero Academia without collisions', () {
      final tokyo = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'tokyo-revengers-s4',
        animeTitle: 'Tokyo Revengers: Season 4',
        server: 'Server 1 (Fast HD)',
      );
      expect(tokyo, contains('Tokyo.Revengers'));

      final frieren = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'frieren-s2',
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

    test('never returns generic dummy 3D trailers for unknown titles', () {
      final fallback = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'unknown-anime-999',
        animeTitle: 'Unknown Random Title',
        server: 'Server 1 (Fast HD)',
      );
      expect(fallback, isNot(contains('sintel')));
      expect(fallback, isNot(contains('oceans')));
      expect(fallback, isNot(contains('BigBuckBunny')));
      expect(fallback, contains('Cruelty'));
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

    test('returns empty string when position is outside active dialogue cues', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        position: const Duration(seconds: 5000),
      );
      expect(sub, isEmpty);
    });
  });
}
