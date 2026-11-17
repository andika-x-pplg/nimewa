import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/main.dart';
import 'package:nimeva/presentation/screens/home_screen.dart';
import 'package:nimeva/presentation/widgets/custom_bottom_nav.dart';
import 'package:nimeva/presentation/widgets/empty_continue_watching.dart';
import 'package:nimeva/presentation/widgets/home_header.dart';
import 'package:nimeva/presentation/widgets/spotlight_carousel.dart';

void main() {
  group('HomeScreen & NimevaApp Integration Tests', () {
    testWidgets('NimevaApp initializes and renders HomeScreen with all core components', (tester) async {
      await tester.pumpWidget(const NimevaApp());
      await tester.pumpAndSettle();

      // Verify HomeScreen is present
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify Header and user profile elements
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.text('dikzzz'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);

      // Verify Spotlight Carousel and first popular anime item
      expect(find.byType(SpotlightCarousel), findsOneWidget);
      expect(find.textContaining('Tokyo Revengers'), findsOneWidget);
      expect(find.text('Tonton Sekarang'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Verify Continue Watching empty state
      expect(find.byType(EmptyContinueWatching), findsOneWidget);
      expect(find.text('Continue watching'), findsOneWidget);
      expect(find.text('Tidak ada riwayat tonton saat ini.'), findsOneWidget);

      // Verify CustomBottomNavBar and all 5 tabs
      expect(find.byType(CustomBottomNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Jadwal'), findsOneWidget);
      expect(find.text('My list'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('tapping navigation tabs updates the active selected index', (tester) async {
      await tester.pumpWidget(const NimevaApp());
      await tester.pumpAndSettle();

      final navBarFinder = find.byType(CustomBottomNavBar);
      expect(navBarFinder, findsOneWidget);

      CustomBottomNavBar navBar = tester.widget<CustomBottomNavBar>(navBarFinder);
      expect(navBar.currentIndex, equals(0));

      // Tap Explore tab (index 1)
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      navBar = tester.widget<CustomBottomNavBar>(navBarFinder);
      expect(navBar.currentIndex, equals(1));

      // Tap Jadwal tab (index 2)
      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();

      navBar = tester.widget<CustomBottomNavBar>(navBarFinder);
      expect(navBar.currentIndex, equals(2));

      // Tap My list tab (index 3)
      await tester.tap(find.text('My list'));
      await tester.pumpAndSettle();

      navBar = tester.widget<CustomBottomNavBar>(navBarFinder);
      expect(navBar.currentIndex, equals(3));

      // Tap Profile tab (index 4)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      navBar = tester.widget<CustomBottomNavBar>(navBarFinder);
      expect(navBar.currentIndex, equals(4));

      // Tap Home tab (index 0)
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      navBar = tester.widget<CustomBottomNavBar>(navBarFinder);
      expect(navBar.currentIndex, equals(0));
    });

    testWidgets('HomeScreen body is scrollable and displays content without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const NimevaApp());
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // EmptyContinueWatching should remain visible/accessible
      expect(find.byType(EmptyContinueWatching), findsOneWidget);
      expect(find.text('Tidak ada riwayat tonton saat ini.'), findsOneWidget);
    });

    testWidgets('tapping Explore tab transitions view to ExploreScreen with 2-column grid', (tester) async {
      await tester.pumpWidget(const NimevaApp());
      await tester.pumpAndSettle();

      // Initially on Home
      expect(find.text('dikzzz'), findsOneWidget);
      expect(find.text('Jelajah'), findsNothing);

      // Tap Explore
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      // Now ExploreScreen is rendered
      expect(find.text('Jelajah'), findsOneWidget);
      expect(find.text('Temukan anime favoritmu'), findsOneWidget);
      expect(find.text('Solo Leveling: Arise from the Shadow'), findsOneWidget);

      // Tap Home again
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('dikzzz'), findsOneWidget);
      expect(find.text('Jelajah'), findsNothing);
    });
  });
}
