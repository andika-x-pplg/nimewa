import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';

void main() {
  group('AnimeStreamService Tests', () {
    late AnimeStreamService service;

    setUp(() {
      service = AnimeStreamService();
    });

    test('getAnimeDetail returns rich details and episode list for valid id', () async {
      final detail = await service.getAnimeDetail('solo-leveling');

      expect(detail.id, equals('solo-leveling'));
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
      expect(detail.episodes.first.streamUrl, isEmpty);
    });

    test('getEpisodeStreamUrl returns valid video stream endpoint', () async {
      final streamUrl = await service.getEpisodeStreamUrl('solo-leveling-eps-1');
      expect(streamUrl, isNotEmpty);
      expect(streamUrl.startsWith('http'), isTrue);
    });

    test('getSpotlightAnime returns list of curated spotlight anime items', () async {
      final spotlight = await service.getSpotlightAnime();
      expect(spotlight, isNotEmpty);
      expect(spotlight.length, equals(10));
      expect(spotlight.first.title, isNotEmpty);
      expect(spotlight.first.rating, greaterThan(0));
    });

    test('getExploreAnimeList filters by tab and genre accurately', () async {
      final popularList = await service.getExploreAnimeList(filter: 'popular', limit: 6);
      expect(popularList.length, equals(6));
      expect(popularList.first.title, isNotEmpty);

      final latestList = await service.getExploreAnimeList(filter: 'latest', limit: 6);
      expect(latestList.length, equals(6));
      expect(latestList.first.title, isNotEmpty);

      final romanceList = await service.getExploreAnimeList(filter: 'popular', genre: 'Romance');
      expect(romanceList, isNotEmpty);
    });

    test('getExploreAnimeList searches dynamically with query matching title or genre', () async {
      final searchResult = await service.getExploreAnimeList(
        filter: 'popular',
        query: 'Frieren',
      );
      expect(searchResult, isNotEmpty);
      expect(searchResult.any((a) => a.title.contains('Frieren')), isTrue);

      final emptyResult = await service.getExploreAnimeList(
        filter: 'popular',
        query: 'nonexistentanimequery123xyz',
      );
      expect(emptyResult, isEmpty);
    });

    test('getAnimeDetail returns relations for franchise anime', () async {
      final detail = await service.getAnimeDetail('tokyo-revengers-s3');
      expect(detail.relations, isNotEmpty);
      expect(detail.relations.any((r) => r.relationType == 'PREQUEL'), isTrue);
      expect(detail.relations.any((r) => r.relationType == 'SEQUEL'), isTrue);
      expect(detail.hasVideoAvailable, isTrue);
    });

    test('getAnimeDetail for incomplete anime returns hasVideoAvailable false and empty episodes', () async {
      final detail = await service.getAnimeDetail('tokyo-revengers-s4');
      expect(detail.hasVideoAvailable, isFalse);
      expect(detail.episodes, isEmpty);
      expect(detail.relations, isNotEmpty);
    });
  });
}

