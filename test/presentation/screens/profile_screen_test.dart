import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_detail.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';
import 'package:nimeva/data/services/my_list_repository.dart';
import 'package:nimeva/data/services/user_profile_repository.dart';
import 'package:nimeva/presentation/screens/anime_watch_screen.dart';
import 'package:nimeva/presentation/screens/profile_screen.dart';

class _FakeStreamService extends AnimeStreamService {
  final AnimeDetail detail;
  const _FakeStreamService(this.detail) : super(networkDelay: Duration.zero);

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async => detail;
}

void main() {
  AnimeDetail makeDetail() => const AnimeDetail(
        id: '154587',
        aniListId: 154587,
        title: 'Frieren',
        japaneseTitle: '葬送のフリーレン',
        synopsis: 'Elf mage.',
        rating: 9.1,
        releaseYear: 2023,
        status: 'Completed',
        genres: ['Adventure'],
        studio: 'Madhouse',
        posterUrl: '',
        backdropUrl: '',
        totalEpisodes: 28,
        hasVideoAvailable: true,
        episodes: [
          EpisodeItem(
            id: 'ep-1',
            episodeNumber: 1,
            title: 'Episode 1',
            releaseDate: '2023',
            streamUrl: '',
          ),
          EpisodeItem(
            id: 'ep-2',
            episodeNumber: 2,
            title: 'Episode 2',
            releaseDate: '2023',
            streamUrl: '',
          ),
        ],
      );

  group('ProfileScreen', () {
    testWidgets('edits username and updates initial avatar, stats, and watch history resume', (tester) async {
      final profileRepo = UserProfileRepository(disablePersistence: true);
      final myListRepo = MyListRepository(disablePersistence: true);
      await profileRepo.init();
      await myListRepo.init();

      final detail = makeDetail();
      await profileRepo.recordWatchHistory(
        detail: detail,
        episodeNumber: 2,
        episodeTitle: 'Episode 2',
        positionSeconds: 125, // 02:05
        durationSeconds: 1440,
      );

      int? navigatedTab;
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            profileRepository: profileRepo,
            myListRepository: myListRepo,
            streamService: _FakeStreamService(detail),
            onNavigateTab: (tab) => navigatedTab = tab,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial avatar 'D' and username 'dikzzz'
      expect(find.text('D'), findsOneWidget);
      expect(find.text('dikzzz'), findsOneWidget);
      expect(find.text('EXP'), findsOneWidget);
      expect(find.text('Bulan'), findsOneWidget);
      expect(find.text('Total Anime'), findsOneWidget);

      // Edit name -> 'Rina' updates initial to 'R'
      await tester.tap(find.byKey(const Key('profile_edit_name_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Rina');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Rina'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);

      // History entry shows exact timestamp and resumes AnimeWatchScreen with initialPosition
      expect(find.textContaining('02:05'), findsOneWidget);
      await tester.tap(find.text('My List Saya'));
      expect(navigatedTab, equals(3));

      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(AnimeWatchScreen), findsOneWidget);
      final watchWidget =
          tester.widget<AnimeWatchScreen>(find.byType(AnimeWatchScreen));
      expect(watchWidget.initialEpisode.episodeNumber, equals(2));
      expect(watchWidget.initialPosition, equals(const Duration(seconds: 125)));
    });
  });
}

