import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anilist_api_client.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';
import 'package:nimeva/data/services/anime_subtitle_service.dart';
import 'package:nimeva/data/services/owner_video_repository.dart';

void main() {
  group('One Punch Man Integration Tests', () {
    setUp(() {
      OwnerVideoRepository.instance.resetToDefaults();
    });

    test('One Punch Man Season 1 and Season 2 are mapped in OwnerVideoRepository', () {
      final repo = OwnerVideoRepository.instance;

      // Season 1 (AniList ID 21087)
      expect(repo.hasVideosForAnime(21087, seasonNumber: 1), isTrue);
      final s1Videos = repo.getVideosForAnime(21087, seasonNumber: 1);
      expect(s1Videos.length, equals(12));

      // Check episode titles are accurate
      expect(s1Videos[0].episodeTitle, contains('Pria Terkuat'));
      expect(s1Videos[1].episodeTitle, contains('Siklon Soliter'));
      expect(s1Videos[11].episodeTitle, contains('Pahlawan Terkuat'));

      // Check video URL matches authentic OPM pattern
      expect(s1Videos[0].videoUrl, contains('One%20Punch%20Man'));
      expect(s1Videos[0].videoUrl, contains('S01E01'));
      expect(s1Videos[11].videoUrl, contains('S01E12'));

      // Season 2 (AniList ID 102194)
      expect(repo.hasVideosForAnime(102194, seasonNumber: 2), isTrue);
      final s2Videos = repo.getVideosForAnime(102194, seasonNumber: 2);
      expect(s2Videos.length, equals(12));
      expect(s2Videos[0].episodeTitle, contains('Kembalinya Sang Pahlawan'));
      expect(s2Videos[0].videoUrl, contains('One%20Punch%20Man'));
      expect(s2Videos[0].videoUrl, contains('S02E01'));
    });

    test('AnimeStreamResolver resolves One Punch Man episodes accurately without season bleeding', () {
      // Season 1 Episode 1
      final s1Ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '21087',
        animeTitle: 'One Punch Man',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(s1Ep1, contains('S01E01'));
      expect(s1Ep1, contains('One%20Punch%20Man'));

      // Season 1 Episode 12
      final s1Ep12 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '21087',
        animeTitle: 'One Punch Man',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 12,
      );
      expect(s1Ep12, contains('S01E12'));
      expect(s1Ep12, isNot(equals(s1Ep1)));

      // Season 2 Episode 1 (ID 102194)
      final s2Ep1 = AnimeStreamResolver.resolveStreamUrl(
        animeId: '102194',
        animeTitle: 'One Punch Man Season 2',
        server: 'Server 1 (Fast HD)',
        episodeNumber: 1,
      );
      expect(s2Ep1, contains('S02E01'));
      expect(s2Ep1, contains('One%20Punch%20Man'));
      expect(s2Ep1, isNot(equals(s1Ep1)));

      // Anime key detection
      expect(AnimeStreamResolver.detectAnimeKey('21087', 'One Punch Man'), equals('one-punch-man'));
      expect(AnimeStreamResolver.detectAnimeKey('102194', 'One Punch Man 2nd Season'), equals('one-punch-man-s2'));
    });

    test('AnimeStreamService returns curated detail for One Punch Man with 12 sequential episodes', () async {
      const service = AnimeStreamService(networkDelay: Duration.zero);
      final detail = await service.getAnimeDetail('21087');

      expect(detail.aniListId, equals(21087));
      expect(detail.title, anyOf(contains('One Punch Man'), contains('One-Punch Man')));
      expect(detail.hasVideoAvailable, isTrue);
      expect(detail.totalEpisodes, equals(12));
      expect(detail.episodes.length, equals(12));
      expect(detail.episodes[0].title, contains('Pria Terkuat'));
      expect(detail.episodes[0].streamUrl, contains('S01E01'));
      expect(detail.studio.toUpperCase(), equals('MADHOUSE'));

      // Check relation to Season 2 (AniList SEQUEL relation is either 102194 or 97668)
      expect(
        detail.relations.any((r) => (r.id == 102194 || r.id == 97668) && r.relationType == 'SEQUEL'),
        isTrue,
      );
    });

    test('AnimeSubtitleService returns authentic Indonesian dialogue cues for One Punch Man Ep 1', () {
      final cue = AnimeSubtitleService.getSubtitleForPosition(
        animeKey: 'one-punch-man',
        episodeNumber: 1,
        position: const Duration(seconds: 2),
      );

      expect(cue, isNotEmpty);
      expect(cue.toLowerCase(), contains('bumi'));
    });

    test('AniList search resolves "opm" acronym to One Punch Man', () {
      final items = AniListApiClient.cachedPopularAnime;
      final match = items.any((item) => item.matchesSearch('opm'));
      expect(match, isTrue);
    });
  });
}
