import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/data/models/schedule_entry.dart';
import 'package:nimeva/data/services/schedule_service.dart';
import 'package:nimeva/presentation/screens/anime_detail_screen.dart';
import 'package:nimeva/presentation/screens/home_screen.dart';
import 'package:nimeva/presentation/screens/schedule_screen.dart';
import 'package:nimeva/presentation/widgets/schedule_timeline_card.dart';

class _FakeScheduleService extends ScheduleService {
  Future<WeeklyScheduleResult> Function({
    DateTime? now,
    bool forceRefresh,
  }) handler;

  int callCount = 0;
  DateTime? lastNow;
  bool? lastForceRefresh;

  _FakeScheduleService(this.handler)
      : super(
          graphQLRequester: (_, __) async => const {},
        );

  @override
  Future<WeeklyScheduleResult> fetchWeeklySchedule({
    DateTime? now,
    bool forceRefresh = false,
  }) {
    callCount++;
    lastNow = now;
    lastForceRefresh = forceRefresh;
    return handler(now: now, forceRefresh: forceRefresh);
  }
}

void main() {
  final fixedNow = DateTime(2026, 11, 25, 7, 0);

  ScheduleEntry makeEntry({
    required int scheduleId,
    required int mediaId,
    required String title,
    required DateTime airingAt,
    int episodeNumber = 8,
    String format = 'TV',
    bool isHiatusOrDelayed = false,
    DateTime? nextAiringAt,
    String? delayNote,
    bool hasVideoAvailable = false,
  }) {
    return ScheduleEntry(
      scheduleId: scheduleId,
      mediaId: mediaId,
      title: title,
      episodeNumber: episodeNumber,
      format: format,
      airingAt: airingAt,
      isHiatusOrDelayed: isHiatusOrDelayed,
      nextAiringAt: nextAiringAt,
      delayNote: delayNote,
      hasVideoAvailable: hasVideoAvailable,
    );
  }

  WeeklyScheduleResult buildSampleWeekResult({
    bool isStaleCache = false,
    DateTime? now,
  }) {
    final ref = now ?? fixedNow;
    final weekStart = ScheduleDateHelper.weekStartSunday(ref);
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
      23,
      59,
      59,
    );

    final sunEntry = makeEntry(
      scheduleId: 10,
      mediaId: 1001,
      title: 'Blue Box',
      episodeNumber: 7,
      airingAt: DateTime(2026, 11, 22, 20, 0),
      hasVideoAvailable: true,
    );

    final wedReleased = makeEntry(
      scheduleId: 20,
      mediaId: 1002,
      title: 'Sousou no Frieren',
      episodeNumber: 8,
      airingAt: DateTime(2026, 11, 25, 6, 28),
      hasVideoAvailable: true,
    );

    final wedUpcoming = makeEntry(
      scheduleId: 21,
      mediaId: 1003,
      title: 'Solo Leveling',
      episodeNumber: 9,
      airingAt: DateTime(2026, 11, 25, 19, 30),
      hasVideoAvailable: false,
    );

    final thuUpcoming = makeEntry(
      scheduleId: 30,
      mediaId: 1004,
      title: 'Dandadan',
      episodeNumber: 10,
      airingAt: DateTime(2026, 11, 26, 22, 0),
    );

    final thuDelayed = makeEntry(
      scheduleId: 31,
      mediaId: 1005,
      title: 'One Piece',
      episodeNumber: 1123,
      airingAt: DateTime(2026, 11, 26, 23, 0),
      isHiatusOrDelayed: true,
      nextAiringAt: DateTime(2026, 12, 3, 23, 0),
      delayNote: 'Libur minggu ini · Tayang lagi 3 Des',
    );

    final map = <String, List<ScheduleEntry>>{
      '2026-11-22': [sunEntry],
      '2026-11-25': [wedReleased, wedUpcoming],
      '2026-11-26': [thuUpcoming, thuDelayed],
    };

    return WeeklyScheduleResult(
      weekStart: weekStart,
      weekEnd: weekEnd,
      entriesByDateKey: map,
      isStaleCache: isStaleCache,
    );
  }

  Widget wrapScreen(
    Widget child, {
    Size surfaceSize = const Size(390, 844),
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: surfaceSize.width,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('ScheduleScreen Widget Tests', () {
    testWidgets('shows loading state initially before data arrives', (tester) async {
      final completer = Completer<WeeklyScheduleResult>();
      final service = _FakeScheduleService(
        ({now, forceRefresh = false}) => completer.future,
      );

      await tester.pumpWidget(
        wrapScreen(
          ScheduleScreen(
            scheduleService: service,
            nowProvider: () => fixedNow,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Memuat jadwal anime...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(buildSampleWeekResult());
      await tester.pumpAndSettle();

      expect(find.text('Memuat jadwal anime...'), findsNothing);
    });

    testWidgets(
      'displays header, NOVEMBER 2026, default Wednesday 25 Tayang Hari Ini, released 06:28 and upcoming 19:30 items',
      (tester) async {
        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => buildSampleWeekResult(),
        );

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => fixedNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jadwal Rilis'), findsOneWidget);
        expect(find.text('NOVEMBER 2026'), findsOneWidget);
        expect(find.text('Tayang Hari Ini'), findsOneWidget);
        expect(find.text('2 episode'), findsOneWidget);

        expect(find.text('Sousou no Frieren'), findsOneWidget);
        expect(find.text('Baru rilis · 06:28'), findsOneWidget);
        expect(find.text('Solo Leveling'), findsOneWidget);
        expect(find.text('Rilis 19:30 · Dalam 12j 30m'), findsOneWidget);
        expect(service.lastNow, fixedNow);
      },
    );

    testWidgets(
      'tapping past day Min 22 and future day Kam 26 updates section header and lineup including delayed badge',
      (tester) async {
        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => buildSampleWeekResult(),
        );

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => fixedNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Sunday (Min 22)
        await tester.tap(find.text('22'));
        await tester.pumpAndSettle();

        expect(find.text('Sudah Tayang · Min, 22 Nov'), findsOneWidget);
        expect(find.text('Blue Box'), findsOneWidget);
        expect(find.text('Sousou no Frieren'), findsNothing);

        // Tap Thursday (Kam 26)
        await tester.tap(find.text('26'));
        await tester.pumpAndSettle();

        expect(find.text('Akan Tayang · Kam, 26 Nov'), findsOneWidget);
        expect(find.text('Dandadan'), findsOneWidget);
        expect(find.text('One Piece'), findsOneWidget);
        expect(
          find.text('Libur minggu ini · Tayang lagi 3 Des'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'rolls over week automatically on Sunday 2026-11-29 showing Min 29..Sab 5 and hiding 22',
      (tester) async {
        final rolloverNow = DateTime(2026, 11, 29, 9, 0);
        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => WeeklyScheduleResult(
            weekStart: DateTime(2026, 11, 29),
            weekEnd: DateTime(2026, 12, 5, 23, 59, 59),
            entriesByDateKey: {
              '2026-11-29': [
                makeEntry(
                  scheduleId: 99,
                  mediaId: 2001,
                  title: 'Shangri-La Frontier',
                  episodeNumber: 12,
                  airingAt: DateTime(2026, 11, 29, 17, 0),
                ),
              ],
            },
          ),
        );

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => rolloverNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('29'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('22'), findsNothing);
        expect(find.text('Tayang Hari Ini'), findsOneWidget);
        expect(find.text('Shangri-La Frontier'), findsOneWidget);
      },
    );

    testWidgets(
      'toggles episode reminder with SnackBar, filters with header Hanya Pengingat button, and offers reset on empty reminder day',
      (tester) async {
        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => buildSampleWeekResult(),
        );

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => fixedNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap bell on upcoming Solo Leveling card
        final cardBell = find
            .descendant(
              of: find.byType(ScheduleTimelineCard),
              matching: find.byIcon(Icons.notifications_none_rounded),
            )
            .first;
        await tester.tap(cardBell);
        await tester.pumpAndSettle();

        // SnackBar appears and card icon becomes active bell
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ScheduleTimelineCard),
            matching: find.byIcon(Icons.notifications_active_rounded),
          ),
          findsOneWidget,
        );

        // Tap header filter bell (>= 44x44)
        final headerFilterFinder = find.ancestor(
          of: find.byIcon(Icons.notifications_none_rounded),
          matching: find.byType(InkWell),
        ).first;
        final filterSize = tester.getSize(headerFilterFinder);
        expect(filterSize.width, greaterThanOrEqualTo(44));
        expect(filterSize.height, greaterThanOrEqualTo(44));

        await tester.tap(headerFilterFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Hanya Pengingat'), findsOneWidget);
        expect(find.text('Solo Leveling'), findsOneWidget);
        expect(find.text('Sousou no Frieren'), findsNothing);

        // Switch to Thursday (26) which has no reminded entries -> empty reminder state
        await tester.tap(find.text('26'));
        await tester.pumpAndSettle();

        expect(find.text('Dandadan'), findsNothing);
        expect(find.text('Reset Filter'), findsOneWidget);

        // Tap Reset Filter restores full Thursday lineup
        await tester.tap(find.text('Reset Filter'));
        await tester.pumpAndSettle();

        expect(find.text('Dandadan'), findsOneWidget);
        expect(find.text('One Piece'), findsOneWidget);
        expect(find.textContaining('Hanya Pengingat'), findsNothing);
      },
    );

    testWidgets(
      'tapping card triggers onAnimeTap with converted AnimeItem and empty day allows returning to today',
      (tester) async {
        AnimeItem? tappedAnime;
        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => buildSampleWeekResult(),
        );

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => fixedNow,
              onAnimeTap: (anime) => tappedAnime = anime,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sousou no Frieren'));
        await tester.pumpAndSettle();

        expect(tappedAnime, isNotNull);
        expect(tappedAnime!.id, '1002');
        expect(tappedAnime!.aniListId, 1002);
        expect(tappedAnime!.title, 'Sousou no Frieren');
        expect(tappedAnime!.hasVideoAvailable, isTrue);

        // Switch to empty Tuesday (Sel 24)
        await tester.tap(find.text('24'));
        await tester.pumpAndSettle();

        expect(find.text('Tidak ada jadwal tayang pada hari ini.'), findsOneWidget);
        expect(find.text('Kembali ke Hari Ini'), findsOneWidget);

        await tester.tap(find.text('Kembali ke Hari Ini'));
        await tester.pumpAndSettle();

        expect(find.text('Tayang Hari Ini'), findsOneWidget);
        expect(find.text('Sousou no Frieren'), findsOneWidget);
      },
    );

    testWidgets(
      'error state displays Coba Lagi button and retries on tap; stale cache displays offline banner',
      (tester) async {
        var shouldFail = true;
        final service = _FakeScheduleService(({now, forceRefresh = false}) async {
          if (shouldFail) {
            throw Exception('Network timeout');
          }
          return buildSampleWeekResult(isStaleCache: true);
        });

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => fixedNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Coba Lagi'), findsOneWidget);
        expect(service.callCount, 1);

        // Retry with stale cache fallback
        shouldFail = false;
        await tester.tap(find.text('Coba Lagi'));
        await tester.pumpAndSettle();

        expect(service.callCount, 2);
        expect(service.lastForceRefresh, isTrue);
        expect(find.text('Sousou no Frieren'), findsOneWidget);
        expect(
          find.text('Mode offline. Menampilkan jadwal tersimpan.'),
          findsOneWidget,
        );
        expect(find.text('Segarkan'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly without overflow at 320x640, 360x780 (1-column), and 900x800 (2-column constrained <= 960px)',
      (tester) async {
        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => WeeklyScheduleResult(
            weekStart: DateTime(2026, 11, 22),
            weekEnd: DateTime(2026, 11, 28, 23, 59, 59),
            entriesByDateKey: {
              '2026-11-25': [
                makeEntry(
                  scheduleId: 1,
                  mediaId: 101,
                  title:
                      'Shuumatsu Nani Shitemasu ka? Isogashii Desu ka? Sukutte Moratte Ii Desu ka? Extended Title',
                  airingAt: DateTime(2026, 11, 25, 6, 28),
                  hasVideoAvailable: true,
                ),
                makeEntry(
                  scheduleId: 2,
                  mediaId: 102,
                  title: 'Solo Leveling Season 2 Arise from the Shadow',
                  airingAt: DateTime(2026, 11, 25, 19, 30),
                ),
              ],
            },
          ),
        );

        // 1. Narrow 320x640 check: all 7 week cells stay >= 44x44 without overflow
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ScheduleScreen(
                scheduleService: service,
                nowProvider: () => fixedNow,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (final dayNum in ['22', '23', '24', '25', '26', '27', '28']) {
          final cellInk = find.ancestor(
            of: find.text(dayNum),
            matching: find.byType(InkWell),
          );
          final size = tester.getSize(cellInk);
          expect(size.width, greaterThanOrEqualTo(44));
          expect(size.height, greaterThanOrEqualTo(44));
        }

        // 2. Mobile 360x780 check: 1-column timeline (cards stacked vertically)
        tester.view.physicalSize = const Size(360, 780);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final cardsMobile = find.byType(ScheduleTimelineCard);
        expect(cardsMobile, findsNWidgets(2));
        final firstMobilePos = tester.getTopLeft(cardsMobile.at(0));
        final secondMobilePos = tester.getTopLeft(cardsMobile.at(1));
        expect(secondMobilePos.dy, greaterThan(firstMobilePos.dy));
        expect(secondMobilePos.dx, equals(firstMobilePos.dx));

        // 3. Tablet/Desktop 900x800 (and 1200x800 for <= 960 constraint)
        tester.view.physicalSize = const Size(900, 800);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final cardsWide = find.byType(ScheduleTimelineCard);
        expect(cardsWide, findsNWidgets(2));
        final firstWidePos = tester.getTopLeft(cardsWide.at(0));
        final secondWidePos = tester.getTopLeft(cardsWide.at(1));
        expect(secondWidePos.dx, greaterThan(firstWidePos.dx));
        expect(secondWidePos.dy, equals(firstWidePos.dy));

        // Check maxWidth <= 960 constraint on extra-wide viewport
        tester.view.physicalSize = const Size(1200, 800);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final constrainedFinder = find.byKey(const Key('schedule_max_width_container'));
        expect(constrainedFinder, findsOneWidget);
        expect(tester.getSize(constrainedFinder).width, lessThanOrEqualTo(960));
      },
    );

    testWidgets(
      'HomeScreen Jadwal tab renders ScheduleScreen with injected ScheduleService and navigates to AnimeDetailScreen on card tap',
      (tester) async {
        final currentNow = DateTime.now();
        final todayKey = ScheduleDateHelper.dateKey(currentNow);
        final weekStart = ScheduleDateHelper.weekStartSunday(currentNow);
        final weekEnd = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
          23,
          59,
          59,
        );
        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => WeeklyScheduleResult(
            weekStart: weekStart,
            weekEnd: weekEnd,
            entriesByDateKey: {
              todayKey: [
                makeEntry(
                  scheduleId: 501,
                  mediaId: 154587,
                  title: 'Sousou no Frieren',
                  episodeNumber: 8,
                  airingAt: DateTime(
                    currentNow.year,
                    currentNow.month,
                    currentNow.day,
                    23,
                    55,
                  ),
                  hasVideoAvailable: true,
                ),
              ],
            },
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: HomeScreen(scheduleService: service),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Jadwal'));
        await tester.pumpAndSettle();

        expect(find.byType(ScheduleScreen), findsOneWidget);
        expect(find.text('Jadwal Rilis'), findsOneWidget);
        expect(find.text('Sousou no Frieren'), findsOneWidget);

        await tester.tap(find.text('Sousou no Frieren'));
        await tester.pumpAndSettle();
        expect(find.byType(AnimeDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      '601x800 2-column grid hides timeline rail, tightens padding to 16px, preserves delayed time, and gives adequate text width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(601, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = _FakeScheduleService(
          ({now, forceRefresh = false}) async => WeeklyScheduleResult(
            weekStart: DateTime(2026, 11, 22),
            weekEnd: DateTime(2026, 11, 28, 23, 59, 59),
            entriesByDateKey: {
              '2026-11-25': [
                makeEntry(
                  scheduleId: 1,
                  mediaId: 101,
                  title: 'Sousou no Frieren',
                  episodeNumber: 8,
                  airingAt: DateTime(2026, 11, 25, 6, 28),
                  hasVideoAvailable: true,
                ),
                makeEntry(
                  scheduleId: 2,
                  mediaId: 102,
                  title: 'Shangri-La Frontier',
                  episodeNumber: 12,
                  airingAt: DateTime(2026, 11, 25, 17, 0),
                  isHiatusOrDelayed: true,
                  nextAiringAt: DateTime(2026, 12, 2, 17, 0),
                ),
              ],
            },
          ),
        );

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => fixedNow,
            ),
            surfaceSize: const Size(601, 800),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final cards = find.byType(ScheduleTimelineCard);
        expect(cards, findsNWidgets(2));

        // 2-column horizontal arrangement with 16px side padding
        final firstTopLeft = tester.getTopLeft(cards.at(0));
        final secondTopLeft = tester.getTopLeft(cards.at(1));
        expect(firstTopLeft.dx, equals(16.0));
        expect(secondTopLeft.dx, greaterThan(firstTopLeft.dx));
        expect(secondTopLeft.dy, equals(firstTopLeft.dy));

        // Both cards hide timeline rail
        for (var i = 0; i < 2; i++) {
          final cardWidget = tester.widget<ScheduleTimelineCard>(cards.at(i));
          expect(cardWidget.showTimelineRail, isFalse);
        }

        // Delayed card preserves clock time alongside delay status
        expect(find.text('17:00'), findsNothing);
        expect(
          find.text('17:00 · Libur minggu ini · Tayang lagi 2 Des'),
          findsOneWidget,
        );

        // Text column has adequate width (>= 110px, not cramped ~58px)
        final titleTextWidth =
            tester.getSize(find.text('Sousou no Frieren')).width;
        expect(titleTextWidth, greaterThanOrEqualTo(110.0));
      },
    );

    testWidgets(
      'refetches new week when nowProvider advances across Sunday midnight while ScheduleScreen remains mounted',
      (tester) async {
        var currentNow = DateTime(2026, 11, 25, 23, 58);
        Completer<WeeklyScheduleResult>? rolloverCompleter;
        final service = _FakeScheduleService(({now, forceRefresh = false}) {
          final target = now ?? currentNow;
          final weekStart = ScheduleDateHelper.weekStartSunday(target);
          if (ScheduleDateHelper.dateKey(weekStart) == '2026-11-29') {
            rolloverCompleter = Completer<WeeklyScheduleResult>();
            return rolloverCompleter!.future;
          }
          return Future.value(buildSampleWeekResult(now: target));
        });

        late StateSetter setHostState;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return wrapScreen(
                ScheduleScreen(
                  scheduleService: service,
                  nowProvider: () => currentNow,
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(service.callCount, 1);
        expect(find.text('Sousou no Frieren'), findsOneWidget);
        expect(find.text('22'), findsOneWidget);

        // Advance past Sunday midnight while mounted
        setHostState(() {
          currentNow = DateTime(2026, 11, 29, 0, 5);
        });
        await tester.pump();
        await tester.pump();

        expect(service.callCount, 2);

        // Extra rebuild while rollover is in flight must not trigger duplicate load
        setHostState(() {});
        await tester.pump();
        expect(service.callCount, 2);

        rolloverCompleter!.complete(
          WeeklyScheduleResult(
            weekStart: DateTime(2026, 11, 29),
            weekEnd: DateTime(2026, 12, 5, 23, 59, 59),
            entriesByDateKey: {
              '2026-11-29': [
                makeEntry(
                  scheduleId: 99,
                  mediaId: 2001,
                  title: 'Shangri-La Frontier',
                  episodeNumber: 12,
                  airingAt: DateTime(2026, 11, 29, 17, 0),
                ),
              ],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(service.callCount, 2);
        expect(find.text('29'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('22'), findsNothing);
        expect(find.text('Shangri-La Frontier'), findsOneWidget);
        expect(find.text('Tidak ada jadwal tayang pada hari ini.'), findsNothing);
      },
    );

    testWidgets(
      'refetches new week on AppLifecycleState.resumed when week rolled over in background',
      (tester) async {
        var currentNow = DateTime(2026, 11, 25, 23, 58);
        final service = _FakeScheduleService(({now, forceRefresh = false}) async {
          final target = now ?? currentNow;
          final weekStart = ScheduleDateHelper.weekStartSunday(target);
          if (ScheduleDateHelper.dateKey(weekStart) == '2026-11-29') {
            return WeeklyScheduleResult(
              weekStart: weekStart,
              weekEnd: DateTime(2026, 12, 5, 23, 59, 59),
              entriesByDateKey: {
                '2026-11-29': [
                  makeEntry(
                    scheduleId: 99,
                    mediaId: 2001,
                    title: 'Shangri-La Frontier',
                    episodeNumber: 12,
                    airingAt: DateTime(2026, 11, 29, 17, 0),
                  ),
                ],
              },
            );
          }
          return buildSampleWeekResult(now: target);
        });

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => currentNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(service.callCount, 1);
        expect(find.text('Sousou no Frieren'), findsOneWidget);

        currentNow = DateTime(2026, 11, 29, 8, 0);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        expect(service.callCount, 2);
        expect(find.text('29'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('22'), findsNothing);
        expect(find.text('Shangri-La Frontier'), findsOneWidget);
      },
    );

    testWidgets(
      'disables Segarkan button and shows Memuat... loading feedback while stale-cache refresh is in flight',
      (tester) async {
        Completer<WeeklyScheduleResult>? refreshCompleter;
        var fetchNum = 0;
        final service = _FakeScheduleService(({now, forceRefresh = false}) {
          fetchNum++;
          if (fetchNum == 1) {
            return Future.value(buildSampleWeekResult(isStaleCache: true));
          }
          refreshCompleter = Completer<WeeklyScheduleResult>();
          return refreshCompleter!.future;
        });

        await tester.pumpWidget(
          wrapScreen(
            ScheduleScreen(
              scheduleService: service,
              nowProvider: () => fixedNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Segarkan'), findsOneWidget);
        expect(find.text('Memuat...'), findsNothing);
        expect(service.callCount, 1);

        // Tap Segarkan to start refresh
        await tester.tap(find.text('Segarkan'));
        await tester.pump();

        expect(service.callCount, 2);
        expect(service.lastForceRefresh, isTrue);
        expect(find.text('Segarkan'), findsNothing);
        expect(find.text('Memuat...'), findsOneWidget);

        final loadingButton = find.ancestor(
          of: find.text('Memuat...'),
          matching: find.byType(TextButton),
        );
        expect(loadingButton, findsOneWidget);
        expect(tester.widget<TextButton>(loadingButton).onPressed, isNull);

        final indicatorFinder = find.descendant(
          of: loadingButton,
          matching: find.byType(CircularProgressIndicator),
        );
        expect(indicatorFinder, findsOneWidget);
        final indicatorSize = tester.getSize(indicatorFinder);
        expect(indicatorSize.width, 14);
        expect(indicatorSize.height, 14);

        // Repeated tap while loading must be ignored
        await tester.tap(loadingButton, warnIfMissed: false);
        await tester.pump();
        expect(service.callCount, 2);

        // Complete refresh with fresh non-stale data
        refreshCompleter!.complete(buildSampleWeekResult(isStaleCache: false));
        await tester.pumpAndSettle();

        expect(find.text('Memuat...'), findsNothing);
        expect(
          find.text('Mode offline. Menampilkan jadwal tersimpan.'),
          findsNothing,
        );
      },
    );
  });
}
