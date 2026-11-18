import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';

void main() {
  group('AnimeStreamService Tests', () {
    late AnimeStreamService service;

    setUp(() {
      service = AnimeStreamService();
    });

    test('getAnimeDetail returns rich details and episode list for valid id', () async {
      final detail = await service.getAnimeDetail('solo-leveling-s2');

      expect(detail.id, equals('solo-leveling-s2'));
      expect(detail.title, contains('Solo Leveling'));
      expect(detail.synopsis, isNotEmpty);
      expect(detail.episodes.length, greaterThanOrEqualTo(8));
      expect(detail.episodes.first.episodeNumber, equals(1));
      expect(detail.episodes.first.streamUrl, isNotEmpty);
    });

    test('getAnimeDetail returns generated fallback detail for unknown id without crashing', () async {
      final detail = await service.getAnimeDetail('unknown-anime-id');

      expect(detail.id, equals('unknown-anime-id'));
      expect(detail.episodes, isNotEmpty);
      expect(detail.episodes.first.streamUrl, isNotEmpty);
    });

    test('getEpisodeStreamUrl returns valid video stream endpoint', () async {
      final streamUrl = await service.getEpisodeStreamUrl('solo-leveling-s2-eps-1');
      expect(streamUrl, isNotEmpty);
      expect(streamUrl.startsWith('http'), isTrue);
    });

    test('getSpotlightAnime returns list of curated spotlight anime items', () async {
      final spotlight = await service.getSpotlightAnime();
      expect(spotlight, isNotEmpty);
      expect(spotlight.length, greaterThanOrEqualTo(5));
      expect(spotlight.first.title, contains('Tokyo Revengers'));
    });

    test('getExploreAnimeList filters by tab and genre accurately', () async {
      final popularList = await service.getExploreAnimeList(filter: 'popular');
      expect(popularList.length, equals(6));
      expect(popularList.first.title, contains('Solo Leveling'));

      final latestList = await service.getExploreAnimeList(filter: 'latest');
      expect(latestList.length, equals(6));
      expect(latestList.first.title, contains('Kaiju No. 8'));

      final romanceList = await service.getExploreAnimeList(filter: 'popular', genre: 'Romance');
      expect(romanceList.length, equals(6));
      expect(romanceList.any((a) => a.title.contains('Kaguya-sama')), isTrue);
    });

    test('getExploreAnimeList searches dynamically with query matching title or genre', () async {
      final searchResult = await service.getExploreAnimeList(
        filter: 'popular',
        query: 'Frieren',
      );
      expect(searchResult.length, equals(1));
      expect(searchResult.first.title, contains('Frieren'));

      final emptyResult = await service.getExploreAnimeList(
        filter: 'popular',
        query: 'nonexistentanimequery123xyz',
      );
      expect(emptyResult, isEmpty);
    });
  });
}

