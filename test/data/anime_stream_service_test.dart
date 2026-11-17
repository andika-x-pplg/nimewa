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
  });
}
