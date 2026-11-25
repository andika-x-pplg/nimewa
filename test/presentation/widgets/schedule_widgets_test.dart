import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_colors.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/schedule_entry.dart';
import 'package:nimeva/presentation/widgets/anime_image_placeholder.dart';
import 'package:nimeva/presentation/widgets/schedule_timeline_card.dart';
import 'package:nimeva/presentation/widgets/schedule_week_bar.dart';

void main() {
  final today = DateTime(2026, 11, 25, 7, 0);
  final weekDays = ScheduleDateHelper.weekDays(today);

  ScheduleEntry buildEntry({
    int scheduleId = 1,
    int mediaId = 101,
    String title = 'Sousou no Frieren',
    String posterUrl = '',
    String format = 'TV',
    int episodeNumber = 8,
    required DateTime airingAt,
    bool isHiatusOrDelayed = false,
    DateTime? nextAiringAt,
    String? delayNote,
    bool hasVideoAvailable = false,
  }) {
    return ScheduleEntry(
      scheduleId: scheduleId,
      mediaId: mediaId,
      title: title,
      posterUrl: posterUrl,
      format: format,
      episodeNumber: episodeNumber,
      airingAt: airingAt,
      isHiatusOrDelayed: isHiatusOrDelayed,
      nextAiringAt: nextAiringAt,
      delayNote: delayNote,
      hasVideoAvailable: hasVideoAvailable,
    );
  }

  group('ScheduleWeekBar', () {
    testWidgets(
      'renders month header, local timezone, all 7 days Min..Sab left-to-right on 320px width with >= 44dp touch target and active blue styling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        DateTime? tappedDay;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleWeekBar(
                days: weekDays,
                selectedDate: DateTime(2026, 11, 25),
                today: today,
                reminderDateKeys: const {'2026-11-26'},
                onDaySelected: (day) => tappedDay = day,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('NOVEMBER 2026'), findsOneWidget);
        expect(find.text(ScheduleDateHelper.gmtOffsetLabel(today)), findsOneWidget);

        const expectedLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
        const expectedNumbers = ['22', '23', '24', '25', '26', '27', '28'];

        double previousDx = -1;
        for (var i = 0; i < 7; i++) {
          final labelFinder = find.text(expectedLabels[i]);
          final numberFinder = find.text(expectedNumbers[i]);
          expect(labelFinder, findsOneWidget);
          expect(numberFinder, findsOneWidget);

          final dx = tester.getTopLeft(labelFinder).dx;
          expect(dx, greaterThan(previousDx));
          previousDx = dx;

          final cellInkWell = find.ancestor(
            of: numberFinder,
            matching: find.byType(InkWell),
          );
          expect(cellInkWell, findsOneWidget);
          final cellSize = tester.getSize(cellInkWell);
          expect(cellSize.width, greaterThanOrEqualTo(44));
          expect(cellSize.height, greaterThanOrEqualTo(44));
        }

        // Active blue styling on selectedDate (Rab 25)
        final selectedContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('25'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final selectedDecoration = selectedContainer.decoration! as BoxDecoration;
        expect(selectedDecoration.color, AppColors.accentBlue);

        // Inactive styling on Thursday (26)
        final inactiveContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('26'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final inactiveDecoration = inactiveContainer.decoration! as BoxDecoration;
        expect(inactiveDecoration.color, AppColors.surfaceCard);

        // Tap Thursday (26)
        await tester.tap(find.text('26'));
        await tester.pumpAndSettle();
        expect(tappedDay, isNotNull);
        expect(
          ScheduleDateHelper.dateKey(tappedDay!),
          equals('2026-11-26'),
        );
      },
    );
  });

  group('ScheduleTimelineCard', () {
    testWidgets(
      'renders placeholder when poster is empty, Episode 8, time 06:28, status Baru rilis · 06:28, and play icon when released with video',
      (tester) async {
        var tapped = false;
        final entry = buildEntry(
          airingAt: DateTime(2026, 11, 25, 6, 28),
          hasVideoAvailable: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleTimelineCard(
                entry: entry,
                now: today,
                isReminded: false,
                isLastInColumn: false,
                showTimelineRail: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byType(AnimeImagePlaceholder), findsOneWidget);
        expect(find.text('Sousou no Frieren'), findsOneWidget);
        expect(find.text('Episode 8'), findsOneWidget);
        expect(find.text('Tersedia'), findsOneWidget);
        expect(find.text('06:28'), findsOneWidget);
        expect(find.text('Baru rilis · 06:28'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);

        final playButton = find
            .ancestor(
              of: find.byIcon(Icons.play_arrow_rounded),
              matching: find.byType(InkWell),
            )
            .first;
        expect(tester.getSize(playButton).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(playButton).height, greaterThanOrEqualTo(44));

        await tester.tap(playButton);
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'renders Image.network and chevron when released without video',
      (tester) async {
        var tapped = false;
        final entry = buildEntry(
          posterUrl: 'https://example.com/poster.jpg',
          airingAt: DateTime(2026, 11, 25, 5, 0),
          hasVideoAvailable: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleTimelineCard(
                entry: entry,
                now: today,
                isReminded: false,
                isLastInColumn: true,
                showTimelineRail: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Sudah rilis · 05:00'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

        final chevronButton = find
            .ancestor(
              of: find.byIcon(Icons.chevron_right_rounded),
              matching: find.byType(InkWell),
            )
            .first;
        expect(tester.getSize(chevronButton).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(chevronButton).height, greaterThanOrEqualTo(44));

        await tester.tap(find.text('Sousou no Frieren'));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'renders reminder bell toggle with >= 44x44 target on upcoming card',
      (tester) async {
        var cardTapped = false;
        var reminderToggled = false;
        final entry = buildEntry(
          airingAt: DateTime(2026, 11, 25, 19, 30),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleTimelineCard(
                entry: entry,
                now: today,
                isReminded: false,
                isLastInColumn: false,
                showTimelineRail: true,
                onTap: () => cardTapped = true,
                onReminderToggle: () => reminderToggled = true,
              ),
            ),
          ),
        );

        expect(find.text('Rilis 19:30 · Dalam 12j 30m'), findsOneWidget);
        final bellIcon = find.byIcon(Icons.notifications_none_rounded);
        expect(bellIcon, findsOneWidget);

        final bellTarget = find
            .ancestor(
              of: bellIcon,
              matching: find.byType(InkWell),
            )
            .first;
        final size = tester.getSize(bellTarget);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));

        await tester.tap(bellTarget);
        await tester.pumpAndSettle();
        expect(reminderToggled, isTrue);
        expect(cardTapped, isFalse);
      },
    );

    testWidgets(
      'renders amber Libur minggu ini status and active bell on delayed/hiatus card',
      (tester) async {
        var reminderToggled = false;
        final entry = buildEntry(
          airingAt: DateTime(2026, 11, 28, 17, 0),
          isHiatusOrDelayed: true,
          nextAiringAt: DateTime(2026, 12, 5, 17, 0),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleTimelineCard(
                entry: entry,
                now: today,
                isReminded: true,
                isLastInColumn: false,
                showTimelineRail: true,
                onTap: () {},
                onReminderToggle: () => reminderToggled = true,
              ),
            ),
          ),
        );

        final statusFinder = find.textContaining('Libur minggu ini');
        expect(statusFinder, findsOneWidget);
        final statusText = tester.widget<Text>(statusFinder);
        expect(statusText.style?.color, AppColors.accentAmber);

        final activeBell = find.byIcon(Icons.notifications_active_rounded);
        expect(activeBell, findsOneWidget);
        final bellTarget = find
            .ancestor(
              of: activeBell,
              matching: find.byType(InkWell),
            )
            .first;
        expect(tester.getSize(bellTarget).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(bellTarget).height, greaterThanOrEqualTo(44));

        await tester.tap(bellTarget);
        await tester.pumpAndSettle();
        expect(reminderToggled, isTrue);
      },
    );

    testWidgets(
      'handles very long anime titles without overflow on 320px width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const longTitle =
            'Shuumatsu Nani Shitemasu ka? Isogashii Desu ka? Sukutte Moratte Ii Desu ka? Season 2 Extended Edition';
        final entry = buildEntry(
          title: longTitle,
          format: 'ONA',
          episodeNumber: 12,
          airingAt: DateTime(2026, 11, 25, 19, 30),
          hasVideoAvailable: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleTimelineCard(
                entry: entry,
                now: today,
                isReminded: false,
                isLastInColumn: false,
                showTimelineRail: true,
                onTap: () {},
                onReminderToggle: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleWidget = tester.widget<Text>(find.text(longTitle));
        expect(titleWidget.maxLines, 2);
        expect(titleWidget.overflow, TextOverflow.ellipsis);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'hides left timeline rail when showTimelineRail is false',
      (tester) async {
        final entry = buildEntry(
          airingAt: DateTime(2026, 11, 25, 19, 30),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleTimelineCard(
                entry: entry,
                now: today,
                isReminded: false,
                isLastInColumn: true,
                showTimelineRail: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('19:30'), findsNothing);
        expect(find.text('Rilis 19:30 · Dalam 12j 30m'), findsOneWidget);
      },
    );
  });
}
