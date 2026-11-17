import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_colors.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/presentation/widgets/custom_bottom_nav.dart';

void main() {
  group('CustomBottomNavBar Widget', () {
    testWidgets('renders all 5 navigation tabs with labels and icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Jadwal'), findsOneWidget);
      expect(find.text('My list'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('triggers onTap with correct index when each tab is tapped', (tester) async {
      final tappedIndices = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                tappedIndices.add(index);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My list'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(tappedIndices, equals([1, 2, 3, 4, 0]));
    });

    testWidgets('applies active styling to the selected tab and muted styling to others', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: 2, // Jadwal active
              onTap: (_) {},
            ),
          ),
        ),
      );

      final jadwalText = tester.widget<Text>(find.text('Jadwal'));
      expect(jadwalText.style?.color, equals(AppColors.accentCrimson));

      final homeText = tester.widget<Text>(find.text('Home'));
      expect(homeText.style?.color, equals(AppColors.textMuted));

      final exploreText = tester.widget<Text>(find.text('Explore'));
      expect(exploreText.style?.color, equals(AppColors.textMuted));

      final myListText = tester.widget<Text>(find.text('My list'));
      expect(myListText.style?.color, equals(AppColors.textMuted));

      final profileText = tester.widget<Text>(find.text('Profile'));
      expect(profileText.style?.color, equals(AppColors.textMuted));

      // Active indicator dot should be visible for the active tab
      expect(find.byKey(const Key('active_indicator_2')), findsOneWidget);
      expect(find.byKey(const Key('active_indicator_0')), findsNothing);
    });

    testWidgets('renders top border with borderSubtle color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      final containerFinder = find.byKey(const Key('custom_bottom_nav_container'));
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final boxDecoration = container.decoration as BoxDecoration?;
      expect(boxDecoration, isNotNull);
      expect(boxDecoration?.color, equals(AppColors.surfaceCard));
      expect(boxDecoration?.border?.top.color, equals(AppColors.borderSubtle));
      expect(boxDecoration?.border?.top.width, equals(1.0));
    });
  });
}
