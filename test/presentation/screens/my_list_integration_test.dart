import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_detail.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/data/models/my_list_entry.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';
import 'package:nimeva/data/services/my_list_repository.dart';
import 'package:nimeva/data/services/schedule_service.dart';
import 'package:nimeva/presentation/screens/anime_detail_screen.dart';
import 'package:nimeva/presentation/screens/anime_watch_screen.dart';
import 'package:nimeva/presentation/screens/home_screen.dart';
import 'package:nimeva/presentation/screens/my_list_screen.dart';
import 'package:nimeva/presentation/widgets/continue_watching_strip.dart';
import 'package:nimeva/presentation/widgets/empty_continue_watching.dart';

class _FakeStreamService extends AnimeStreamService {
  final AnimeDetail detailToReturn;
  final List<AnimeItem> spotlightItems;

  const _FakeStreamService({
    required this.detailToReturn,
    this.spotlightItems = const [],
  }) : super(networkDelay: Duration.zero);

  @override
  Future<List<AnimeItem>> getSpotlightAnime() async => spotlightItems;

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async => detailToReturn;
}

class _FakeScheduleService extends ScheduleService {
  _FakeScheduleService() : super();
}

void main() {
  AnimeItem makeItem({String id = '154587', int aniListId = 154587, String title = 'Frieren'}) {
    return AnimeItem(
      id: id,
      aniListId: aniListId,
      title: title,
      japaneseTitle: '葬送のフリーレン',
      rating: 9.1,
      releaseYear: 2023,
      genres: const ['Adventure', 'Fantasy'],
      description: 'Elf mage journey.',
      posterUrl: '',
      backdropUrl: '',
      episodeInfo: 'SUB · 28 EP',
    );
  }

  AnimeDetail makeDetail({
    String id = '154587',
    int aniListId = 154587,
    String title = 'Frieren',
    int totalEpisodes = 3,
  }) {
    return AnimeDetail(
      id: id,
      aniListId: aniListId,
      title: title,
      japaneseTitle: '葬送のフリーレン',
      synopsis: 'Elf mage journey.',
      rating: 9.1,
      releaseYear: 2023,
      status: 'Completed',
      genres: const ['Adventure', 'Fantasy'],
      studio: 'Madhouse',
      posterUrl: '',
      backdropUrl: '',
      totalEpisodes: totalEpisodes,
      hasVideoAvailable: true,
      episodes: List.generate(
        totalEpisodes,
        (i) => EpisodeItem(
          id: 'ep-${i + 1}',
          episodeNumber: i + 1,
          title: 'Episode ${i + 1}',
          releaseDate: '2023',
          streamUrl: '',
        ),
      ),
    );
  }

  group('My List Integration', () {
    testWidgets('AnimeDetailScreen shows Simpan Anime (not Daftar Tonton) and syncs both bookmark buttons with MyListRepository', (tester) async {
      final repo = MyListRepository(disablePersistence: true);
      await repo.init();
      final detail = makeDetail();
      final service = _FakeStreamService(detailToReturn: detail);

      await tester.pumpWidget(
        MaterialApp(
          home: AnimeDetailScreen(
            animeId: detail.id,
            previewItem: makeItem(),
            service: service,
            myListRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daftar Tonton'), findsNothing);
      expect(find.text('Simpan Anime'), findsOneWidget);
      expect(repo.contains(detail.id, aniListId: detail.aniListId, title: detail.title), isFalse);

      // Tap main Simpan Anime button
      await tester.tap(find.text('Simpan Anime'));
      await tester.pumpAndSettle();

      expect(find.text('Tersimpan'), findsOneWidget);
      expect(repo.contains(detail.id, aniListId: detail.aniListId, title: detail.title), isTrue);

      // Tap AppBar bookmark icon to remove -> shows Urungkan SnackBar
      expect(find.byIcon(Icons.bookmark_rounded), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.bookmark_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Simpan Anime'), findsOneWidget);
      expect(find.text('Urungkan'), findsOneWidget);
      expect(repo.contains(detail.id, aniListId: detail.aniListId, title: detail.title), isFalse);
    });

    testWidgets('AnimeWatchScreen auto-records episode progress on init and next episode', (tester) async {
      final repo = MyListRepository(disablePersistence: true);
      await repo.init();
      final detail = makeDetail(totalEpisodes: 3);
      await repo.toggleSaveFromDetail(detail);

      await tester.pumpWidget(
        MaterialApp(
          home: AnimeWatchScreen(
            anime: detail,
            initialEpisode: detail.episodes[0],
            myListRepository: repo,
          ),
        ),
      );
      await tester.pump();

      final entry1 = repo.findEntry(detail.id, aniListId: detail.aniListId, title: detail.title);
      expect(entry1, isNotNull);
      expect(entry1!.watchedEpisode, equals(1));
      expect(entry1.status, equals(MyListStatus.watching));

      // Navigate to next episode (episode 2)
      final nextBtn = find.byIcon(Icons.skip_next_rounded);
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(nextBtn.first);
        await tester.pumpAndSettle();
        await tester.tap(nextBtn.first);
        await tester.pump();
        final entry2 = repo.findEntry(detail.id, aniListId: detail.aniListId, title: detail.title);
        expect(entry2!.watchedEpisode, equals(2));
      }
    });

    testWidgets('HomeScreen toggles Spotlight + button, shows ContinueWatchingStrip when watching exists, and opens MyListScreen on tab 3', (tester) async {
      final repo = MyListRepository(disablePersistence: true);
      await repo.init();
      final item = makeItem();
      final service = _FakeStreamService(
        detailToReturn: makeDetail(),
        spotlightItems: [item],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            streamService: service,
            scheduleService: _FakeScheduleService(),
            myListRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially empty -> EmptyContinueWatching shown
      expect(find.byType(EmptyContinueWatching), findsOneWidget);
      expect(find.byType(ContinueWatchingStrip), findsNothing);

      // Tap Spotlight + button -> saves anime and switches icon to check
      final addBtn = find.byIcon(Icons.add_rounded).first;
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(repo.contains(item.id, aniListId: item.aniListId, title: item.title), isTrue);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Add a watching entry -> ContinueWatchingStrip appears
      await repo.recordWatchProgress(
        detail: makeDetail(totalEpisodes: 12),
        episodeNumber: 4,
        episodeTitle: 'Episode 4',
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContinueWatchingStrip), findsOneWidget);
      expect(find.byType(EmptyContinueWatching), findsNothing);

      // Tap Lihat semua -> navigates to MyListScreen (tab 3)
      final seeAllFinder = find.text('Lihat semua');
      await tester.ensureVisible(seeAllFinder);
      await tester.pumpAndSettle();
      await tester.tap(seeAllFinder);
      await tester.pumpAndSettle();
      expect(find.byType(MyListScreen), findsOneWidget);
    });
  });
}
