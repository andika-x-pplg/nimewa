import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/consumet_api_client.dart';

class _FakeConsumetClient extends ConsumetApiClient {
  final String? fakeStreamUrl;
  final bool shouldThrow;

  _FakeConsumetClient({this.fakeStreamUrl, this.shouldThrow = false});

  @override
  Future<String?> resolveLatestStream({
    required String title,
    required int episodeNumber,
    int? seasonNumber,
    String provider = 'gogoanime',
  }) async {
    if (shouldThrow) throw const SocketException('Connection failed');
    return fakeStreamUrl;
  }
}

void main() {
  group('Consumet Models Serialization Tests', () {
    test('ConsumetAnimeResult parses json accurately', () {
      final json = {
        'id': 'tokyo-revengers-s4',
        'title': 'Tokyo Revengers: Santen Sensou-hen',
        'url': 'https://gogoanime3.co/category/tokyo-revengers-season-4',
        'image': 'https://gogoanime3.co/cover/tokyo-revengers.jpg',
        'releaseDate': '2026',
        'subOrDub': 'sub',
      };
      final result = ConsumetAnimeResult.fromJson(json);

      expect(result.id, equals('tokyo-revengers-s4'));
      expect(result.title, contains('Tokyo Revengers'));
      expect(result.subOrDub, equals('sub'));
      expect(result.releaseDate, equals('2026'));
    });

    test('ConsumetEpisode parses string and num episode numbers safely', () {
      final ep1 = ConsumetEpisode.fromJson({
        'id': 'tokyo-revengers-episode-1',
        'number': 1,
        'title': 'Episode 1',
      });
      expect(ep1.number, equals(1));

      final ep2 = ConsumetEpisode.fromJson({
        'id': 'tokyo-revengers-episode-2',
        'number': '2',
        'title': 'Episode 2',
      });
      expect(ep2.number, equals(2));
    });

    test('ConsumetStreamSource detects m3u8 and qualities', () {
      final m3u8 = ConsumetStreamSource.fromJson({
        'url': 'https://stream.server.org/master.m3u8',
        'isM3U8': true,
        'quality': '1080p',
      });
      expect(m3u8.isM3U8, isTrue);
      expect(m3u8.quality, equals('1080p'));

      final mp4 = ConsumetStreamSource.fromJson({
        'url': 'https://stream.server.org/video.mp4',
        'quality': '720p',
      });
      expect(mp4.isM3U8, isFalse);
      expect(mp4.quality, equals('720p'));
    });
  });

  group('ConsumetApiClient Resilience Tests', () {
    test('searchAnime returns empty list when network is offline', () async {
      final client = ConsumetApiClient(
        baseUrls: ['https://127.0.0.1:9999/invalid'],
        timeout: const Duration(milliseconds: 200),
      );

      final results = await client.searchAnime('Demon Slayer');
      expect(results, isEmpty);
    });

    test('getEpisodes returns empty list when network is offline', () async {
      final client = ConsumetApiClient(
        baseUrls: ['https://127.0.0.1:9999/invalid'],
        timeout: const Duration(milliseconds: 200),
      );

      final episodes = await client.getEpisodes('demon-slayer');
      expect(episodes, isEmpty);
    });

    test('getEpisodeStreams returns empty list when network is offline', () async {
      final client = ConsumetApiClient(
        baseUrls: ['https://127.0.0.1:9999/invalid'],
        timeout: const Duration(milliseconds: 200),
      );

      final streams = await client.getEpisodeStreams('demon-slayer-episode-1');
      expect(streams, isEmpty);
    });

    test('resolveLatestStream returns null on unreachable server without throwing', () async {
      final client = ConsumetApiClient(
        baseUrls: ['https://127.0.0.1:9999/invalid'],
        timeout: const Duration(milliseconds: 200),
      );

      final url = await client.resolveLatestStream(
        title: 'Demon Slayer',
        episodeNumber: 1,
      );
      expect(url, isNull);
    });
  });

  group('AnimeStreamResolver Hybrid Async Resolution Tests', () {
    test('returns online stream URL when Consumet client finds fresh source', () async {
      const mockStreamUrl = 'https://stream.consumet.org/live/stream-720p.m3u8';
      final mockClient = _FakeConsumetClient(fakeStreamUrl: mockStreamUrl);

      final streamUrl = await AnimeStreamResolver.resolveStreamUrlAsync(
        animeId: 'tokyo-revengers-s4',
        animeTitle: 'Tokyo Revengers: Season 4',
        server: 'Server 4 (Consumet Cloud)',
        episodeNumber: 1,
        client: mockClient,
      );

      expect(streamUrl, equals(mockStreamUrl));
    });

    test('gracefully falls back to local archive stream when Consumet client fails or throws', () async {
      final throwingClient = _FakeConsumetClient(shouldThrow: true);

      final streamUrl = await AnimeStreamResolver.resolveStreamUrlAsync(
        animeId: 'demon-slayer',
        animeTitle: 'Demon Slayer',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
        client: throwingClient,
      );

      // Successfully falls back to authentic local stream
      expect(streamUrl, contains('Cruelty'));
      expect(streamUrl, contains('.mp4'));
    });

    test('falls back to Season 4 fallback for Tokyo Revengers S4 when online is null', () async {
      final nullClient = _FakeConsumetClient(fakeStreamUrl: null);

      final streamUrl = await AnimeStreamResolver.resolveStreamUrlAsync(
        animeId: 'tokyo-revengers-s4',
        animeTitle: 'Tokyo Revengers: Season 4',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
        client: nullClient,
      );

      expect(streamUrl, isNot(contains('S01')));
      expect(streamUrl, contains('.mp4'));
    });
  });
}
