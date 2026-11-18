import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/anime_subtitle_service.dart';

void main() {
  group('AnimeStreamResolver Tests', () {
    test('resolves Demon Slayer to authentic Demon Slayer streams for Ep 1 and Ep 2', () {
      final ep1Server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370', // Kitsu ID for Kimetsu no Yaiba
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1Server1, contains('Tanjiro'));
      expect(ep1Server1, contains('.mp4'));
      expect(ep1Server1, isNot(contains('sintel')));
      expect(ep1Server1, isNot(contains('oceans')));

      final ep1Server3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370',
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 3 (Otaku)',
        episodeNumber: 1,
      );
      expect(ep1Server3, contains('Tanjiro'));
      expect(ep1Server3, contains('.mp4'));

      final ep2Server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '41370',
        animeTitle: 'Kimetsu no Yaiba: Yuukaku-hen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      // Episode 2 must return a distinct authentic episode stream
      expect(ep2Server1, contains('.mp4'));
      expect(ep2Server1, isNot(equals(ep1Server1)));

      final japaneseTitle = AnimeStreamResolver.detectAnimeKey('unknown-id', '鬼滅の刃');
      expect(japaneseTitle, equals('demon-slayer'));
    });

    test('resolves Attack on Titan to authentic Shingeki no Kyojin streams for Ep 1 & 2', () {
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

      final japaneseKey = AnimeStreamResolver.detectAnimeKey('7442', '進撃の巨人');
      expect(japaneseKey, equals('attack-on-titan'));
    });

    test('resolves Death Note distinct episodes 1 and 2', () {
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
    });

    test('resolves Naruto distinct episodes 1 and 2', () {
      final ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '3936',
        animeTitle: 'Naruto Shippuden',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(ep1, contains('151'));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '3936',
        animeTitle: 'Naruto Shippuden',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, contains('152'));
      expect(ep2, isNot(equals(ep1)));
    });

    test('resolves Jujutsu Kaisen to authentic Jujutsu Kaisen streams', () {
      final server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen Season 3',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(server1, contains('Jujutsu%20Kaisen'));
      expect(server1, contains('.mp4'));

      final ep2 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '43806',
        animeTitle: 'Jujutsu Kaisen',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 2,
      );
      expect(ep2, contains('Jujutsu%20Kaisen'));
      expect(ep2, isNot(equals(server1)));
    });

    test('resolves Tokyo Revengers, Frieren, and Solo Leveling accurately without collisions', () {
      final tokyo = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'tokyo-revengers-s4',
        animeTitle: 'Tokyo Revengers: Season 4',
        server: 'Server 1 (Fast HD)',
      );
      expect(tokyo, contains('Tokyo.Revengers'));

      // Ensure Frieren is NOT mistakenly mapped to Eren/Attack on Titan
      final frieren = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'frieren-s2',
        animeTitle: 'Sousou no Frieren',
        server: 'Server 1 (Fast HD)',
      );
      expect(frieren, contains('frieren'));

      final solo = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'solo-leveling-s2',
        animeTitle: 'Solo Leveling',
        server: 'Server 1 (Fast HD)',
      );
      expect(solo, contains('SoloLeveling'));
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
      expect(fallback, contains('.mp4'));
    });
  });

  group('AnimeSubtitleService Tests', () {
    test('returns Indonesian subtitle cues for Demon Slayer Ep 1', () {
      final sub = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'demon-slayer',
        episodeNumber: 1,
        position: const Duration(seconds: 12),
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
        position: const Duration(seconds: 500),
      );
      expect(sub, isEmpty);
    });
  });
}
