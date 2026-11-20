import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/mock/mock_anime_data.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/presentation/widgets/spotlight_carousel.dart';

void main() {
  group('SpotlightCarousel Widget', () {
    testWidgets('renders section badge and anime metadata for first item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCarousel(
                items: mockPopularAnime,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Section headers / badges
      expect(find.text('ANIME POPULER'), findsOneWidget);
      expect(find.text('HOT SPOTLIGHT'), findsOneWidget);

      // Metadata for first item (Solo Leveling)
      expect(find.text('Solo Leveling'), findsOneWidget);
      expect(find.text('8.8'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('renders action buttons "Tonton Sekarang" and add to watchlist button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCarousel(
                items: mockPopularAnime,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tonton Sekarang'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('triggers onWatchNow callback with current item when "Tonton Sekarang" is tapped', (tester) async {
      AnimeItem? watchedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCarousel(
                items: mockPopularAnime,
                onWatchNow: (item) {
                  watchedItem = item;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tonton Sekarang'));
      await tester.pumpAndSettle();

      expect(watchedItem, isNotNull);
      expect(watchedItem!.id, 'solo-leveling');
      expect(watchedItem!.title, 'Solo Leveling');
    });

    testWidgets('triggers onAddList callback with current item when "+" button is tapped', (tester) async {
      AnimeItem? addedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCarousel(
                items: mockPopularAnime,
                onAddList: (item) {
                  addedItem = item;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(addedItem, isNotNull);
      expect(addedItem!.id, 'solo-leveling');
    });

    testWidgets('renders dot indicators corresponding to items length', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCarousel(
                items: mockPopularAnime,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Look for 5 indicator dots
      for (var i = 0; i < mockPopularAnime.length; i++) {
        expect(find.byKey(Key('carousel_dot_$i')), findsOneWidget);
      }
    });

    testWidgets('swiping horizontally changes page and reveals next anime item', (tester) async {
      AnimeItem? watchedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCarousel(
                items: mockPopularAnime,
                onWatchNow: (item) {
                  watchedItem = item;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Solo Leveling'), findsOneWidget);

      // Swipe left on PageView to go to next item
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      // Second item is Demon Slayer: Kimetsu no Yaiba
      expect(find.text('Demon Slayer: Kimetsu no Yaiba'), findsOneWidget);

      // Tap "Tonton Sekarang" on second item
      await tester.tap(find.text('Tonton Sekarang'));
      await tester.pumpAndSettle();

      expect(watchedItem, isNotNull);
      expect(watchedItem!.id, 'demon-slayer');
    });

    testWidgets('tapping indicator dot animates to corresponding page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCarousel(
                items: mockPopularAnime,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap dot index 2 (Attack on Titan)
      await tester.tap(find.byKey(const Key('carousel_dot_2')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Attack on Titan'), findsOneWidget);
    });

    testWidgets('handles empty items list gracefully without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SpotlightCarousel(
              items: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpotlightCarousel), findsOneWidget);
      expect(find.text('Tonton Sekarang'), findsNothing);
    });
  });
}
