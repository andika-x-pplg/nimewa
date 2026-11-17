import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/presentation/widgets/empty_continue_watching.dart';

void main() {
  group('EmptyContinueWatching Widget', () {
    testWidgets('renders default section title "Continue watching"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: EmptyContinueWatching(),
          ),
        ),
      );

      expect(find.text('Continue watching'), findsOneWidget);
    });

    testWidgets('renders exact text "Tidak ada riwayat tonton saat ini."', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: EmptyContinueWatching(),
          ),
        ),
      );

      expect(find.text('Tidak ada riwayat tonton saat ini.'), findsOneWidget);
    });

    testWidgets('renders hint subtext and history icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: EmptyContinueWatching(),
          ),
        ),
      );

      expect(
        find.text('Mulai tonton anime favoritmu untuk melihat riwayat di sini.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });

    testWidgets('renders custom section title when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: EmptyContinueWatching(
              sectionTitle: 'Lanjutkan Menonton',
            ),
          ),
        ),
      );

      expect(find.text('Lanjutkan Menonton'), findsOneWidget);
      expect(find.text('Continue watching'), findsNothing);
    });

    testWidgets('triggers onExploreTap when explore action is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: EmptyContinueWatching(
              onExploreTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      final exploreButtonFinder = find.byKey(const Key('empty_continue_watching_explore_btn'));
      expect(exploreButtonFinder, findsOneWidget);

      await tester.tap(exploreButtonFinder);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not render explore button when onExploreTap is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: EmptyContinueWatching(
              onExploreTap: null,
            ),
          ),
        ),
      );

      final exploreButtonFinder = find.byKey(const Key('empty_continue_watching_explore_btn'));
      expect(exploreButtonFinder, findsNothing);
    });
  });
}
