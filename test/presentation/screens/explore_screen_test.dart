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

    // Verify exactly 6 anime cards are displayed initially (Popular)
    expect(find.byType(AnimeGridCard), findsNWidgets(6));
    expect(find.text('Solo Leveling: Arise from the Shadow'), findsOneWidget);

    // Tap "Latest" tab and verify dynamic content switch
    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimeGridCard), findsNWidgets(6));
    expect(find.text('Kaiju No. 8 Season 2'), findsOneWidget);
    expect(find.text('Solo Leveling: Arise from the Shadow'), findsNothing);

    // Tap "Romance" genre chip and verify dynamic content switch
    await tester.tap(find.text('Romance'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimeGridCard), findsNWidgets(6));
    expect(find.text('Hotaru no Yomeiri'), findsOneWidget);
  });
}
