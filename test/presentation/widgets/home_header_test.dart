import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/presentation/widgets/home_header.dart';

void main() {
  group('HomeHeader Widget', () {
    testWidgets('renders default username "dikzzz" and initial "D"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: HomeHeader(),
          ),
        ),
      );

      expect(find.text('dikzzz'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Selamat Menonton'), findsOneWidget);
    });

    testWidgets('renders custom username and correct uppercase initial', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: HomeHeader(
              username: 'akira',
              greeting: 'Konnichiwa',
            ),
          ),
        ),
      );

      expect(find.text('akira'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Konnichiwa'), findsOneWidget);
    });

    testWidgets('handles empty username gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: HomeHeader(username: ''),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('triggers onNotificationTap when notification icon is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HomeHeader(
              onNotificationTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onProfileTap when avatar is tapped', (tester) async {
      var profileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HomeHeader(
              onProfileTap: () {
                profileTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('D'));
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
    });

    testWidgets('displays notification badge indicator by default and hides when false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: HomeHeader(showNotificationBadge: true),
          ),
        ),
      );

      expect(find.byKey(const Key('notification_badge')), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: HomeHeader(showNotificationBadge: false),
          ),
        ),
      );

      expect(find.byKey(const Key('notification_badge')), findsNothing);
    });
  });
}
