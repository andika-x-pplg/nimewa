import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/anime_detail.dart';
import 'package:nimeva/data/models/anime_external_link.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';
import 'package:nimeva/presentation/screens/anime_detail_screen.dart';

class _FakeAnimeStreamService extends AnimeStreamService {
  final AnimeDetail detail;

  const _FakeAnimeStreamService(this.detail);

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    return detail;
  }
}

void main() {
  group('Official Streaming Button & Availability Status Tests', () {
    testWidgets('renders "Tonton di platform resmi" button when streaming externalLinks exist', (tester) async {
      final sampleDetailWithOfficialLinks = AnimeDetail(
        id: '151807',
        title: 'Solo Leveling',
        japaneseTitle: '俺だけレベルアップな件',
        rating: 8.4,
        releaseYear: 2024,
        genres: const ['Action', 'Fantasy'],
        synopsis: 'Sung Jinwoo bangkit menjadi Hunter terkuat.',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        status: 'Ongoing',
        studio: 'A-1 Pictures',
        totalEpisodes: 12,
        episodes: [
          const EpisodeItem(
            id: '151807-eps-1',
            episodeNumber: 1,
            title: 'Episode 1 Sub Indo',
            releaseDate: '2024-01-01',
            streamUrl: 'https://example.com/video.mp4',
          ),
        ],
        hasVideoAvailable: true,
        externalLinks: const [
          AnimeExternalLink(
            id: 1,
            url: 'https://www.crunchyroll.com/series/solo-leveling',
            site: 'Crunchyroll',
            type: 'STREAMING',
          ),
          AnimeExternalLink(
            id: 2,
            url: 'https://www.netflix.com/title/solo-leveling',
            site: 'Netflix',
            type: 'STREAMING',
          ),
          AnimeExternalLink(
            id: 3,
            url: 'https://twitter.com/sololeveling_pr',
            site: 'Twitter',
            type: 'SOCIAL',
          ),
        ],
      );

      final fakeService = _FakeAnimeStreamService(sampleDetailWithOfficialLinks);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AnimeDetailScreen(
            animeId: '151807',
            service: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check availability badge
      expect(find.text('Video tersedia'), findsOneWidget);

      // Check official streaming button
      expect(find.text('Tonton di platform resmi'), findsOneWidget);

      // Verify watch button is enabled and says "Mulai Nonton"
      expect(find.text('Mulai Nonton'), findsOneWidget);
    });

    testWidgets('hides "Tonton di platform resmi" button when externalLinks has no streaming sources', (tester) async {
      final sampleDetailNoOfficialLinks = AnimeDetail(
        id: '120120',
        title: 'Tokyo Revengers',
        japaneseTitle: '東京卍リベンジャーズ',
        rating: 8.2,
        releaseYear: 2021,
        genres: const ['Action', 'Drama'],
        synopsis: 'Takemichi Hanagaki melompati waktu.',
        posterUrl: 'https://example.com/tr.jpg',
        backdropUrl: 'https://example.com/tr-bg.jpg',
        status: 'Tamat',
        studio: 'LIDENFILMS',
        totalEpisodes: 24,
        episodes: [
          const EpisodeItem(
            id: '120120-eps-1',
            episodeNumber: 1,
            title: 'Episode 1 Sub Indo',
            releaseDate: '2021-04-11',
            streamUrl: 'https://example.com/tr-ep1.mp4',
          ),
        ],
        hasVideoAvailable: true,
        externalLinks: const [
          AnimeExternalLink(
            id: 10,
            url: 'https://twitter.com/anime_toman',
            site: 'Twitter',
            type: 'SOCIAL',
          ),
        ],
      );

      final fakeService = _FakeAnimeStreamService(sampleDetailNoOfficialLinks);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AnimeDetailScreen(
            animeId: '120120',
            service: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Official streaming button should NOT be rendered
      expect(find.text('Tonton di platform resmi'), findsNothing);
    });

    testWidgets('shows "Belum tersedia" badge and disables watch button when hasVideoAvailable is false', (tester) async {
      final sampleDetailNoVideo = AnimeDetail(
        id: '178945',
        title: 'Tokyo Revengers: Season 4',
        japaneseTitle: '東京卍リベンジャーズ 第4期',
        rating: 7.9,
        releaseYear: 2026,
        genres: const ['Action', 'Supernatural'],
        synopsis: 'Arc Santen Sensou.',
        posterUrl: '',
        backdropUrl: '',
        status: 'Ongoing',
        studio: 'LIDENFILMS',
        totalEpisodes: 0,
        episodes: const [],
        hasVideoAvailable: false,
        externalLinks: const [
          AnimeExternalLink(
            id: 99,
            url: 'https://www.disneyplus.com/series/tokyo-revengers',
            site: 'Disney Plus',
            type: 'STREAMING',
          ),
        ],
      );

      final fakeService = _FakeAnimeStreamService(sampleDetailNoVideo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AnimeDetailScreen(
            animeId: '178945',
            service: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Availability badge in metadata
      expect(find.text('Belum tersedia'), findsOneWidget);

      // Primary watch button should display "Video Belum Tersedia"
      expect(find.text('Video Belum Tersedia'), findsOneWidget);

      // Verify ElevatedButton is disabled (onPressed is null)
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('Video Belum Tersedia'), matching: find.byType(ElevatedButton)),
      );
      expect(elevatedButton.onPressed, isNull);

      // Official streaming button is still present because STREAMING link exists in AniList
      expect(find.text('Tonton di platform resmi (Disney Plus)'), findsOneWidget);
    });
  });
}

