import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/presentation/screens/explore_screen.dart';
import 'package:nimeva/presentation/widgets/anime_grid_card.dart';

void main() {
  testWidgets('ExploreScreen renders header, search, filter tabs, genre chips, and 6 anime cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: ExploreScreen(),
        ),
      ),
    );

    // Verify Header
    expect(find.text('Jelajah'), findsOneWidget);
    expect(find.text('Temukan anime favoritmu'), findsOneWidget);

    // Verify Search Bar
    expect(find.text('Cari anime, genre, atau studio...'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Verify Filter Tabs
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Top rated'), findsOneWidget);

    // Verify Genre Chips
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Romance'), findsOneWidget);

    // Verify multiple anime cards are displayed from API/catalog (more than 6, unlimited)
    expect(find.byType(AnimeGridCard), findsWidgets);
    // Verify "6 anime" or counter label is completely removed
    expect(find.text('6 anime'), findsNothing);

    // Tap "Latest" tab and verify dynamic content switch
    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimeGridCard), findsWidgets);
    expect(find.text('Dan Da Dan Season 1'), findsOneWidget);

    // Tap "Romance" genre chip and verify dynamic content switch
    await tester.tap(find.text('Romance'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimeGridCard), findsWidgets);
    expect(find.text('Kimi no Na wa (Your Name)'), findsOneWidget);

    // Search query dynamically filters list
    await tester.enterText(find.byType(TextField), 'Kimi no Na wa');
    await tester.pumpAndSettle();

    expect(find.text('Kimi no Na wa (Your Name)'), findsOneWidget);

    // Search query with no match shows empty state gracefully
    await tester.enterText(find.byType(TextField), 'xyznonexistentanime');
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada anime yang cocok.'), findsOneWidget);
    expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
  });
}

