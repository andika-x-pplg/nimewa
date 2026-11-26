import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_detail.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';
import 'package:nimeva/data/services/my_list_repository.dart';
import 'package:nimeva/data/services/user_profile_repository.dart';
import 'package:nimeva/presentation/screens/anime_watch_screen.dart';
import 'package:nimeva/presentation/screens/profile_screen.dart';
import 'package:nimeva/presentation/screens/rank_list_screen.dart';
import 'package:nimeva/presentation/screens/watched_anime_list_screen.dart';

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
      await tester.tap(find.text('Daftar Saya'));
      expect(navigatedTab, equals(3));

      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(AnimeWatchScreen), findsOneWidget);
      final watchWidget =
          tester.widget<AnimeWatchScreen>(find.byType(AnimeWatchScreen));
      expect(watchWidget.initialEpisode.episodeNumber, equals(2));
      expect(watchWidget.initialPosition, equals(const Duration(seconds: 125)));
    });

    testWidgets('long-pressing history card shows Simpan ke My List, Buang dari My List, and Hapus dari Histori', (tester) async {
      final profileRepo = UserProfileRepository(disablePersistence: true);
      final myListRepo = MyListRepository(disablePersistence: true);
      await profileRepo.init();
      await myListRepo.init();

      final detail = makeDetail();
      await profileRepo.recordWatchHistory(
        detail: detail,
        episodeNumber: 1,
        episodeTitle: 'Episode 1',
        positionSeconds: 45,
        durationSeconds: 1440,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            profileRepository: profileRepo,
            myListRepository: myListRepo,
            streamService: _FakeStreamService(detail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long-press -> Simpan ke My List
      await tester.longPress(find.text('Frieren'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan ke My List'), findsOneWidget);
      expect(find.text('Hapus dari Histori'), findsOneWidget);

      await tester.tap(find.text('Simpan ke My List'));
      await tester.pumpAndSettle();
      expect(myListRepo.contains('154587', aniListId: 154587, title: 'Frieren'), isTrue);

      // Long-press again -> Buang dari My List
      await tester.longPress(find.text('Frieren'));
      await tester.pumpAndSettle();
      expect(find.text('Buang dari My List'), findsOneWidget);

      await tester.tap(find.text('Buang dari My List'));
      await tester.pumpAndSettle();
      expect(myListRepo.contains('154587', aniListId: 154587, title: 'Frieren'), isFalse);

      // Long-press again -> Hapus dari Histori
      await tester.longPress(find.text('Frieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus dari Histori'));
      await tester.pumpAndSettle();
      expect(profileRepo.watchHistory, isEmpty);
    });

    testWidgets('tapping EXP opens RankListScreen and tapping Total Anime opens WatchedAnimeListScreen', (tester) async {
      final profileRepo = UserProfileRepository(disablePersistence: true);
      final myListRepo = MyListRepository(disablePersistence: true);
      await profileRepo.init();
      await myListRepo.init();

      final detail = makeDetail();
      await profileRepo.addWatchExp(watchedSeconds: 15); // 150 EXP -> Lv. 2
      await profileRepo.recordWatchHistory(
        detail: detail,
        episodeNumber: 1,
        episodeTitle: 'Episode 1',
        positionSeconds: 60,
        durationSeconds: 1440,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            profileRepository: profileRepo,
            myListRepository: myListRepo,
            streamService: _FakeStreamService(detail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap EXP -> opens RankListScreen
      await tester.tap(find.text('EXP'));
      await tester.pumpAndSettle();
      expect(find.byType(RankListScreen), findsOneWidget);
      expect(find.text('Daftar 16 Rank Nimeva'), findsOneWidget);
      expect(find.text('50 / 100 EXP'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Wibu'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Wibu'), findsOneWidget);

      // Back and tap Total Anime -> opens WatchedAnimeListScreen
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Total Anime'));
      await tester.pumpAndSettle();
      expect(find.byType(WatchedAnimeListScreen), findsOneWidget);
      expect(find.text('Frieren'), findsOneWidget);
    });
  });
}

