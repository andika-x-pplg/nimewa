import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';

void main() {
  group('AnimeStreamResolver Tests', () {
    test('resolves Demon Slayer to authentic Demon Slayer streams', () {
      final server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '13745',
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(server1, contains('Kimetsu.no.Yaiba'));
      expect(server1, contains('.mp4'));
      expect(server1, isNot(contains('sintel')));
      expect(server1, isNot(contains('oceans')));

      final server3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: 'demon-slayer',
        animeTitle: 'Demon Slayer: Kimetsu no Yaiba Swordsmith Village Arc',
        server: 'Server 3 (Otaku)',
        episodeNumber: 1,
      );
      expect(server3, contains('Demon%20Slayer%20Kimetsu%20no%20Yaiba'));
      expect(server3, contains('.mp4'));
      expect(server3, isNot(contains('sintel')));
      expect(server3, isNot(contains('oceans')));
    });

    test('resolves Attack on Titan to authentic Shingeki no Kyojin streams', () {
      final server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '7442',
        animeTitle: 'Attack on Titan',
        server: 'Server 1 (Fast HD)',
      );
      expect(server1, contains('shingeki-no-kyojin'));
      expect(server1, contains('.mp4'));

      final server3 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '7442',
        animeTitle: 'Attack on Titan',
        server: 'Server 3 (Otaku)',
      );
      expect(server3, contains('Shingeki%20no%20Kyojin'));
      expect(server3, contains('.mp4'));
    });

    test('resolves Jujutsu Kaisen to authentic Jujutsu Kaisen streams', () {
      final server1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '42765',
        animeTitle: 'Jujutsu Kaisen Season 3',
        server: 'Server 1 (Fast HD)',
      );
      expect(server1, contains('Jujutsu%20Kaisen'));
      expect(server1, contains('.mp4'));
    });

    test('resolves Tokyo Revengers, Frieren, and Solo Leveling accurately', () {
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
}
