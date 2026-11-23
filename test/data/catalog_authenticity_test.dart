import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/mock/mock_explore_data.dart';
import 'package:nimeva/data/services/anime_api_client.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';

void main() {
  group('Catalog Authenticity & Atomicity Audit Tests', () {
    test('all items in cachedTrendingAnime have authentic verified episodes and working posters', () {
      expect(AnimeApiClient.cachedTrendingAnime, isNotEmpty);
      for (final anime in AnimeApiClient.cachedTrendingAnime) {
        // Poster & backdrop must exist and not use broken avac.moe
        expect(anime.posterUrl, isNotEmpty, reason: '${anime.title} missing posterUrl');
        expect(anime.backdropUrl, isNotEmpty, reason: '${anime.title} missing backdropUrl');
        expect(anime.posterUrl, isNot(contains('avac.moe')), reason: '${anime.title} uses broken avac.moe');
        expect(anime.backdropUrl, isNot(contains('avac.moe')), reason: '${anime.title} uses broken avac.moe');

        // Atomicity check
        final hasEpisodes = AnimeStreamResolver.hasCompleteEpisodes(anime.id, anime.title);
        expect(hasEpisodes, isTrue, reason: '${anime.title} (${anime.id}) must have 100% complete episodes');

        // Stream URL resolution must be authentic and non-empty
        final streamUrl = AnimeStreamResolver.resolveStreamUrl(
          animeId: anime.id,
          animeTitle: anime.title,
          server: 'Server 1 (Fast HD)',
          episodeNumber: 1,
        );
        expect(streamUrl, isNotEmpty, reason: '${anime.title} stream URL must not be empty');
      }
    });

    test('allCatalogAnime contains only verified anime with real posters and no fake fallbacks', () {
      expect(allCatalogAnime, isNotEmpty);
      for (final anime in allCatalogAnime) {
        expect(anime.posterUrl, isNotEmpty, reason: '${anime.title} missing posterUrl');
        expect(anime.backdropUrl, isNotEmpty, reason: '${anime.title} missing backdropUrl');
        expect(anime.posterUrl, isNot(contains('avac.moe')), reason: '${anime.title} uses broken avac.moe');
        expect(anime.backdropUrl, isNot(contains('avac.moe')), reason: '${anime.title} uses broken avac.moe');

        final hasEpisodes = AnimeStreamResolver.hasCompleteEpisodes(anime.id, anime.title);
        expect(hasEpisodes, isTrue, reason: '${anime.title} (${anime.id}) is in catalog but lacks complete episodes');
      }
    });

    test('inauthentic anime and fake season fallbacks are strictly rejected by hasCompleteEpisodes', () {
      final fakeAnime = [
        ('hunter-x-hunter', 'Hunter x Hunter (2011)'),
        ('bleach', 'Bleach'),
        ('unreleased-season-s4', 'Unreleased Season 4'),
        ('blue-lock', 'Blue Lock'),
        ('oshi-no-ko', 'Oshi no Ko'),
        ('kaiju-no-8', 'Kaiju No. 8'),
        ('tensura', 'Tensei Shitara Slime Datta Ken'),
        ('mushoku-tensei', 'Mushoku Tensei'),
        ('solo-leveling-s2', 'Solo Leveling Season 2'),
        ('attack-on-titan-s2', 'Attack on Titan Season 2'),
        ('jujutsu-kaisen-s2', 'Jujutsu Kaisen Season 2'),
        ('jujutsu-kaisen-s3', 'Jujutsu Kaisen Season 3'),
        ('frieren-s2', 'Sousou no Frieren Season 2'),
        ('spy-x-family', 'Spy x Family'),
        ('spy-x-family-s2', 'Spy x Family Season 2'),
        ('my-hero-academia-s2', 'Boku no Hero Academia Season 2'),
        ('rezero-s2', 'Re:Zero Season 2'),
        ('horimiya', 'Horimiya'),
        ('eighty-six', '86: Eighty Six'),
        ('code-geass', 'Code Geass'),
        ('monster', 'Monster'),
        ('parasyte', 'Parasyte'),
        ('kuroko-no-basket', 'Kuroko no Basket'),
      ];

      for (final (id, title) in fakeAnime) {
        final result = AnimeStreamResolver.hasCompleteEpisodes(id, title);
        expect(result, isFalse, reason: '$title ($id) should be rejected because it lacks genuine episodes');

        final stream = AnimeStreamResolver.resolveStreamUrl(
          animeId: id,
          animeTitle: title,
          server: 'Server 1 (Fast HD)',
          episodeNumber: 1,
        );
        expect(stream, isEmpty, reason: '$title ($id) stream URL must be empty under Atomicity rule');
      }
    });
  });
}

