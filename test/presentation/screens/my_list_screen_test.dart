import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/data/models/my_list_entry.dart';
import 'package:nimeva/data/services/my_list_repository.dart';
import 'package:nimeva/presentation/screens/my_list_screen.dart';
import 'package:nimeva/presentation/widgets/my_list_anime_card.dart';

void main() {
  MyListRepository createRepo() => MyListRepository(disablePersistence: true);

  Widget wrapScreen(
    MyListRepository repo, {
    VoidCallback? onExploreTap,
    Size size = const Size(400, 844),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: MyListScreen(
            repository: repo,
            onExploreTap: onExploreTap,
          ),
        ),
      ),
    );
  }

  group('MyListScreen', () {
    testWidgets('renders 3 filter tabs with counts, callout banner, and filters by Watching/Saved/Completed', (tester) async {
      final repo = createRepo();
      await repo.init();

      await repo.restoreEntry(
        MyListEntry(
          canonicalKey: 'frieren',
          animeId: '154587',
          aniListId: 154587,
          title: 'Frieren',
          totalEpisodes: 28,
          watchedEpisode: 8,
          status: MyListStatus.watching,
          hasVideoAvailable: true,
          updatedAt: DateTime(2026, 11, 25, 10),
        ),
      );
      await repo.toggleSaveAnime(
        const AnimeItem(
          id: '21',
          aniListId: 21,
          title: 'One Piece',
          japaneseTitle: 'ワンピース',
          rating: 8.8,
          releaseYear: 1999,
          genres: ['Action', 'Adventure'],
          description: 'Pirate adventure',
          posterUrl: '',
          backdropUrl: '',
        ),
        totalEpisodes: 1100,
      );
      await repo.restoreEntry(
        MyListEntry(
          canonicalKey: 'deathnote',
          animeId: '1535',
          aniListId: 1535,
          title: 'Death Note',
          totalEpisodes: 37,
          watchedEpisode: 37,
          status: MyListStatus.completed,
          hasVideoAvailable: true,
          updatedAt: DateTime(2026, 11, 24),
        ),
      );

      await tester.pumpWidget(wrapScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Daftarku'), findsOneWidget);
      expect(find.text('Ditonton · 1'), findsOneWidget);
      expect(find.text('Disimpan · 1'), findsOneWidget);
      expect(find.text('Selesai · 1'), findsOneWidget);

      // Default tab is Ditonton
      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('One Piece'), findsNothing);
      expect(find.text('Death Note'), findsNothing);
      expect(find.textContaining('1 anime'), findsOneWidget);

      // Switch to Disimpan
      await tester.tap(find.text('Disimpan · 1'));
      await tester.pumpAndSettle();
      expect(find.text('One Piece'), findsOneWidget);
      expect(find.text('Frieren'), findsNothing);

      // Switch to Selesai
      await tester.tap(find.text('Selesai · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Death Note'), findsOneWidget);
      expect(find.text('One Piece'), findsNothing);
    });

    testWidgets('shows empty state with Jelajahi Anime CTA and triggers onExploreTap', (tester) async {
      final repo = createRepo();
      await repo.init();
      bool exploreTapped = false;

      await tester.pumpWidget(
        wrapScreen(
          repo,
          onExploreTap: () => exploreTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jelajahi Anime'), findsOneWidget);
      await tester.tap(find.text('Jelajahi Anime'));
      expect(exploreTapped, isTrue);
    });

    testWidgets('updates status via card menu, edits episode via dialog, and deletes with Undo SnackBar', (tester) async {
      final repo = createRepo();
      await repo.init();
      await repo.restoreEntry(
        MyListEntry(
          canonicalKey: 'frieren',
          animeId: '154587',
          aniListId: 154587,
          title: 'Frieren',
          totalEpisodes: 28,
          watchedEpisode: 8,
          status: MyListStatus.watching,
          hasVideoAvailable: true,
          updatedAt: DateTime(2026, 11, 25, 10),
        ),
      );

      await tester.pumpWidget(wrapScreen(repo));
      await tester.pumpAndSettle();

      // Edit episode via dialog
      final menuBtn = find.byKey(const Key('my_list_menu_button_frieren'));
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atur Episode'));
      await tester.pumpAndSettle();

      expect(find.text('Atur Progres Episode'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(repo.findEntry('154587', title: 'Frieren')?.watchedEpisode, equals(12));

      // Change status to Selesai
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tandai Selesai'));
      await tester.pumpAndSettle();

      expect(repo.countByStatus(MyListStatus.watching), equals(0));
      expect(repo.countByStatus(MyListStatus.completed), equals(1));

      // Switch to Selesai tab and delete with Undo
      await tester.tap(find.text('Selesai · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Frieren'), findsOneWidget);

      await tester.tap(menuBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus dari Daftarku'));
      await tester.pumpAndSettle();

      expect(repo.countByStatus(MyListStatus.completed), equals(0));
      expect(find.text('Urungkan'), findsOneWidget);

      await tester.tap(find.text('Urungkan'));
      await tester.pumpAndSettle();
      expect(repo.countByStatus(MyListStatus.completed), equals(1));
      expect(find.text('Frieren'), findsOneWidget);
    });

    testWidgets('renders responsive 2-column layout above 600px without overflow', (tester) async {
      final repo = createRepo();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.restoreEntry(
          MyListEntry(
            canonicalKey: 'anime-$i',
            animeId: '${100 + i}',
            title: 'Anime $i',
            totalEpisodes: 12,
            watchedEpisode: 3,
            status: MyListStatus.watching,
            hasVideoAvailable: true,
            updatedAt: DateTime(2026, 11, 25, 10 - i),
          ),
        );
      }

      await tester.pumpWidget(
        wrapScreen(repo, size: const Size(800, 900)),
      );
      await tester.pumpAndSettle();

      final card0 = tester.getTopLeft(find.byType(MyListAnimeCard).at(0));
      final card1 = tester.getTopLeft(find.byType(MyListAnimeCard).at(1));
      expect(card0.dy, equals(card1.dy));
      expect(card1.dx, greaterThan(card0.dx));
    });
  });
}
