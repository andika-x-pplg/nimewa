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
      expect(detail.totalEpisodes, 25);
      expect(detail.episodes.length, 25);
      expect(detail.status, 'Tamat');
    });

    test('resolveAnimeMetadata correctly differentiates finished, movie, and ongoing metadata', () {
      // 1. Finished series with authentic count
      final finishedMeta = AnimeApiClient.resolveAnimeMetadata(
        id: '41370',
        title: 'Kimetsu no Yaiba',
        rawStatus: 'finished',
        subtype: 'TV',
        rawEpisodeCount: 26,
        startDate: '2019-04-06',
      );
      expect(finishedMeta.episodeInfo, 'SUB · 26 EPS (Tamat)');
      expect(finishedMeta.statusLabel, 'Tamat');
      expect(finishedMeta.displayEpisodes, 26);
      expect(finishedMeta.totalEpisodes, 26);

      // 2. Long running finished series (HxH)
      final hxhMeta = AnimeApiClient.resolveAnimeMetadata(
        id: '6448',
        title: 'Hunter x Hunter (2011)',
        rawStatus: 'finished',
        subtype: 'TV',
        rawEpisodeCount: 148,
        startDate: '2011-10-02',
      );
      expect(hxhMeta.episodeInfo, 'SUB · 148 EPS (Tamat)');
      expect(hxhMeta.statusLabel, 'Tamat');
      expect(hxhMeta.displayEpisodes, 148);

      // 3. Movie
      final movieMeta = AnimeApiClient.resolveAnimeMetadata(
        id: '11614',
        title: 'Kimi no Na wa.',
        rawStatus: 'finished',
        subtype: 'movie',
        rawEpisodeCount: 1,
        startDate: '2016-08-26',
      );
      expect(movieMeta.episodeInfo, 'SUB · MOVIE');
      expect(movieMeta.displayEpisodes, 1);
      expect(movieMeta.totalEpisodes, 1);

      // 4. New ongoing seasonal anime (not generic 12)
      final ongoingMeta = AnimeApiClient.resolveAnimeMetadata(
        id: 'new-2026-anime',
        title: 'New Aired Fantasy Anime',
        rawStatus: 'current',
        subtype: 'TV',
        rawEpisodeCount: 12,
        startDate: '2026-01-01',
      );
      expect(ongoingMeta.statusLabel, 'Ongoing');
      expect(ongoingMeta.episodeInfo.contains('(Ongoing)'), isTrue);
      expect(ongoingMeta.episodeInfo, isNot('SUB · EP 12'));
    });

    test('cachedTrendingAnime items have authentic and specific episode info', () {
      for (final item in AnimeApiClient.cachedTrendingAnime) {
        expect(item.episodeInfo, isNotEmpty);
        expect(item.episodeInfo, isNot('SUB · EP 12')); // No generic defaults
      }

      final soloLeveling = AnimeApiClient.cachedTrendingAnime.firstWhere((a) => a.id == 'solo-leveling');
      expect(soloLeveling.episodeInfo, 'SUB · 12 EPS (Tamat)');
      expect(soloLeveling.statusLabel, 'Tamat');

      final demonSlayer = AnimeApiClient.cachedTrendingAnime.firstWhere((a) => a.id == 'demon-slayer');
      expect(demonSlayer.episodeInfo, 'SUB · 26 EPS (Tamat)');
      expect(demonSlayer.statusLabel, 'Tamat');

      final aot = AnimeApiClient.cachedTrendingAnime.firstWhere((a) => a.id == 'attack-on-titan');
      expect(aot.episodeInfo, 'SUB · 25 EPS (Tamat)');
      expect(aot.statusLabel, 'Tamat');
    });
  });
}

