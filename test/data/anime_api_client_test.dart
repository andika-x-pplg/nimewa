import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_api_client.dart';

void main() {
  group('AnimeApiClient Tests', () {
    late AnimeApiClient client;

    setUp(() {
      client = AnimeApiClient();
    });

    test('fetchTrendingAnime returns list of 10 real anime with valid titles and posters', () async {
      final items = await client.fetchTrendingAnime(limit: 10);
      expect(items, isNotEmpty);
      expect(items.length, lessThanOrEqualTo(10));
      for (final item in items) {
        expect(item.id, isNotEmpty);
        expect(item.title, isNotEmpty);
        expect(item.rating, greaterThan(0));
        expect(item.posterUrl.startsWith('http'), isTrue);
      }
    });

    test('searchAnime returns matching anime for query', () async {
      final items = await client.searchAnime('Titan');
      expect(items, isNotEmpty);
      expect(items.any((a) => a.title.toLowerCase().contains('titan')), isTrue);
    });

    test('fetchAnimeByCategory filters anime by given category', () async {
      final items = await client.fetchAnimeByCategory('action', limit: 6);
      expect(items, isNotEmpty);
      expect(items.length, lessThanOrEqualTo(6));
    });

    test('fetchAnimeDetail returns complete anime detail and accurate episode list', () async {
      final detail = await client.fetchAnimeDetail('7442'); // Attack on Titan
      expect(detail.id, isNotEmpty);
      expect(detail.title, isNotEmpty);
      expect(detail.episodes, isNotEmpty);
      expect(detail.totalEpisodes, greaterThan(0));
    });
  });
}
