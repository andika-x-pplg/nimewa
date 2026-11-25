import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anilist_api_client.dart';
import 'package:nimeva/data/services/schedule_service.dart';

void main() {
  group('AniListApiClient.executeGraphQL', () {
    test('exposes executeGraphQL method with expected signature', () {
      const client = AniListApiClient();
      final Future<Map<String, dynamic>> Function(
        String,
        Map<String, dynamic>,
      ) fn = client.executeGraphQL;
      expect(fn, isNotNull);
    });
  });

  group('ScheduleService', () {
    final referenceNow = DateTime(2026, 11, 25, 12, 0); // Wednesday
    final currentWeekStart = DateTime(2026, 11, 22, 0, 0); // Sunday
    final nextWeekStart = DateTime(2026, 11, 29, 0, 0); // Next Sunday

    int toEpochSeconds(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

    Map<String, dynamic> makeScheduleNode({
      required int scheduleId,
      required int mediaId,
      required DateTime airingAt,
      required int episode,
      String? englishTitle,
      String romajiTitle = 'Sample Anime',
      String nativeTitle = 'サンプルアニメ',
      bool isAdult = false,
      String status = 'RELEASING',
      String format = 'TV',
      int? averageScore = 84,
      String description = '<p>Synopsis text.</p>',
      List<String> genres = const ['Action', 'Fantasy'],
      String posterUrl = 'https://s4.anilist.co/cover.jpg',
      String? bannerUrl = 'https://s4.anilist.co/banner.jpg',
      Map<String, dynamic>? nextAiringEpisode,
    }) {
      return {
        'id': scheduleId,
        'airingAt': toEpochSeconds(airingAt),
        'episode': episode,
        'media': {
          'id': mediaId,
          'isAdult': isAdult,
          'status': status,
          'format': format,
          'averageScore': averageScore,
          'description': description,
          'genres': genres,
          'bannerImage': bannerUrl,
          'coverImage': {
            'extraLarge': posterUrl,
            'large': posterUrl,
          },
          'title': {
            'english': englishTitle,
            'romaji': romajiTitle,
            'native': nativeTitle,
          },
          'nextAiringEpisode': nextAiringEpisode,
        },
      };
    }

    Map<String, dynamic> makePageResponse({
      required List<Map<String, dynamic>> schedules,
      bool hasNextPage = false,
      int currentPage = 1,
    }) {
      return {
        'data': {
          'Page': {
            'pageInfo': {
              'hasNextPage': hasNextPage,
              'currentPage': currentPage,
            },
            'airingSchedules': schedules,
          },
        },
      };
    }

    bool isCurrentWeekQuery(Map<String, dynamic> variables) {
      final lesser = variables['airingAtLesser'] as int?;
      return lesser != null && lesser >= toEpochSeconds(nextWeekStart);
    }

    test('auto-paginates across multiple pages and sorts entries chronologically', () async {
      final calls = <Map<String, dynamic>>[];
      final service = ScheduleService(
        graphQLRequester: (query, variables) async {
          calls.add(Map<String, dynamic>.from(variables));
          if (!isCurrentWeekQuery(variables)) {
            return makePageResponse(schedules: []);
          }

          final page = variables['page'] as int;
          if (page == 1) {
            return makePageResponse(
              currentPage: 1,
              hasNextPage: true,
              schedules: [
                makeScheduleNode(
                  scheduleId: 101,
                  mediaId: 151807,
                  englishTitle: 'Solo Leveling',
                  airingAt: DateTime(2026, 11, 22, 21, 0), // Sunday
                  episode: 5,
                ),
                makeScheduleNode(
                  scheduleId: 102,
                  mediaId: 154587,
                  englishTitle: 'Frieren',
                  airingAt: DateTime(2026, 11, 23, 18, 0), // Monday
                  episode: 10,
                ),
              ],
            );
          }

          return makePageResponse(
            currentPage: 2,
            hasNextPage: false,
            schedules: [
              makeScheduleNode(
                scheduleId: 103,
                mediaId: 21,
                englishTitle: 'One Piece',
                airingAt: DateTime(2026, 11, 26, 20, 0), // Thursday
                episode: 1122,
              ),
              makeScheduleNode(
                scheduleId: 104,
                mediaId: 16498,
                englishTitle: 'Attack on Titan',
                airingAt: DateTime(2026, 11, 28, 19, 30), // Saturday
                episode: 12,
              ),
              makeScheduleNode(
                scheduleId: 105,
                mediaId: 120120,
                englishTitle: 'Tokyo Revengers',
                airingAt: DateTime(2026, 11, 28, 10, 0), // Earlier Saturday
                episode: 3,
              ),
            ],
          );
        },
      );

      final result = await service.fetchWeeklySchedule(now: referenceNow);

      expect(result.weekStart, currentWeekStart);
      expect(result.weekEnd, DateTime(2026, 11, 28, 23, 59, 59));
      expect(result.isStaleCache, isFalse);

      expect(result.entriesForDate(DateTime(2026, 11, 22)).single.title, 'Solo Leveling');
      expect(result.entriesForDate(DateTime(2026, 11, 23)).single.title, 'Frieren');
      expect(result.entriesForDate(DateTime(2026, 11, 26)).single.title, 'One Piece');

      final saturdayEntries = result.entriesForDate(DateTime(2026, 11, 28));
      expect(saturdayEntries.map((e) => e.title).toList(), [
        'Tokyo Revengers',
        'Attack on Titan',
      ]);

      // 2 pages for current week + 1 page for previous week
      expect(calls.length, 3);
    });

    test('filters out isAdult entries and empty titles, and assigns hasVideoAvailable', () async {
      final service = ScheduleService(
        graphQLRequester: (query, variables) async {
          if (!isCurrentWeekQuery(variables)) {
            return makePageResponse(schedules: []);
          }
          return makePageResponse(
            schedules: [
              makeScheduleNode(
                scheduleId: 201,
                mediaId: 8861,
                englishTitle: 'Adult Title',
                isAdult: true,
                airingAt: DateTime(2026, 11, 24, 23, 0),
                episode: 1,
              ),
              makeScheduleNode(
                scheduleId: 202,
                mediaId: 50001,
                englishTitle: '   ',
                romajiTitle: '',
                nativeTitle: '',
                airingAt: DateTime(2026, 11, 24, 22, 0),
                episode: 1,
              ),
              makeScheduleNode(
                scheduleId: 203,
                mediaId: 151807,
                englishTitle: 'Solo Leveling',
                airingAt: DateTime(2026, 11, 24, 20, 0),
                episode: 6,
              ),
              makeScheduleNode(
                scheduleId: 204,
                mediaId: 999998,
                englishTitle: 'Unreleased Anime Project',
                airingAt: DateTime(2026, 11, 24, 21, 0),
                episode: 1,
              ),
            ],
          );
        },
      );

      final result = await service.fetchWeeklySchedule(now: referenceNow);
      final tuesdayEntries = result.entriesForDate(DateTime(2026, 11, 24));

      expect(tuesdayEntries.length, 2);
      expect(tuesdayEntries[0].mediaId, 151807);
      expect(tuesdayEntries[0].hasVideoAvailable, isTrue);
      expect(tuesdayEntries[1].mediaId, 999998);
      expect(tuesdayEntries[1].hasVideoAvailable, isFalse);
    });

    test('groups Sunday 00:30 local timestamp under Sunday dateKey, not Saturday', () async {
      final service = ScheduleService(
        graphQLRequester: (query, variables) async {
          if (!isCurrentWeekQuery(variables)) {
            return makePageResponse(schedules: []);
          }
          return makePageResponse(
            schedules: [
              makeScheduleNode(
                scheduleId: 301,
                mediaId: 154587,
                englishTitle: 'Frieren',
                airingAt: DateTime(2026, 11, 22, 0, 30), // Sunday 00:30
                episode: 11,
              ),
            ],
          );
        },
      );

      final result = await service.fetchWeeklySchedule(now: referenceNow);

      expect(result.entriesForDate(DateTime(2026, 11, 21)), isEmpty);
      expect(result.entriesForDate(DateTime(2026, 11, 22)).single.title, 'Frieren');
      expect(result.entriesForDate(DateTime(2026, 11, 22)).single.formattedTime(), '00:30');
    });

    test('detects delayed RELEASING anime from previousWeek when absent in currentWeek with nextAiringEpisode >= 10 days', () async {
      final service = ScheduleService(
        graphQLRequester: (query, variables) async {
          if (isCurrentWeekQuery(variables)) {
            return makePageResponse(schedules: []);
          }

          // Previous week (Nov 15 - Nov 21)
          return makePageResponse(
            schedules: [
              // Delayed RELEASING anime: aired Sat Nov 21 17:00 ep 1221, next ep 1222 on Dec 5 (14 days)
              makeScheduleNode(
                scheduleId: 401,
                mediaId: 21,
                englishTitle: 'One Piece',
                status: 'RELEASING',
                airingAt: DateTime(2026, 11, 21, 17, 0),
                episode: 1221,
                nextAiringEpisode: {
                  'airingAt': toEpochSeconds(DateTime(2026, 12, 5, 17, 0)),
                  'episode': 1222,
                },
              ),
              // Finished anime with no next episode: should NOT be marked delayed
              makeScheduleNode(
                scheduleId: 402,
                mediaId: 101922,
                englishTitle: 'Demon Slayer: Kimetsu no Yaiba',
                status: 'FINISHED',
                airingAt: DateTime(2026, 11, 21, 19, 0),
                episode: 26,
                nextAiringEpisode: null,
              ),
              // RELEASING anime with next episode < 10 days later (Nov 30, 9 days): should NOT be marked delayed
              makeScheduleNode(
                scheduleId: 403,
                mediaId: 113415,
                englishTitle: 'Jujutsu Kaisen',
                status: 'RELEASING',
                airingAt: DateTime(2026, 11, 21, 20, 0),
                episode: 23,
                nextAiringEpisode: {
                  'airingAt': toEpochSeconds(DateTime(2026, 11, 30, 20, 0)),
                  'episode': 24,
                },
              ),
            ],
          );
        },
      );

      final result = await service.fetchWeeklySchedule(now: referenceNow);
      final saturdayNov28 = result.entriesForDate(DateTime(2026, 11, 28));

      expect(saturdayNov28.length, 1);
      final delayedEntry = saturdayNov28.single;
      expect(delayedEntry.mediaId, 21);
      expect(delayedEntry.isHiatusOrDelayed, isTrue);
      expect(delayedEntry.episodeNumber, 1222);
      expect(delayedEntry.airingAt, DateTime(2026, 11, 28, 17, 0));
      expect(delayedEntry.delayNote, 'Libur minggu ini · Tayang lagi 5 Des');
      expect(delayedEntry.delayNote!.contains('\u2014'), isFalse);
    });

    test('caches within TTL, bypasses on forceRefresh, returns stale cache on error, and rethrows when uncached', () async {
      var clockTime = DateTime(2026, 11, 25, 12, 0);
      var callCount = 0;
      var shouldThrow = false;

      final service = ScheduleService(
        cacheTtl: const Duration(minutes: 10),
        clock: () => clockTime,
        graphQLRequester: (query, variables) async {
          callCount++;
          if (shouldThrow) {
            throw Exception('Network unavailable');
          }
          if (!isCurrentWeekQuery(variables)) {
            return makePageResponse(schedules: []);
          }
          return makePageResponse(
            schedules: [
              makeScheduleNode(
                scheduleId: 501,
                mediaId: 151807,
                englishTitle: 'Solo Leveling',
                airingAt: DateTime(2026, 11, 25, 18, 0),
                episode: 7,
              ),
            ],
          );
        },
      );

      // First call populates cache (2 GraphQL calls: current + previous week)
      final first = await service.fetchWeeklySchedule(now: referenceNow);
      expect(first.isStaleCache, isFalse);
      expect(callCount, 2);

      // Second call within TTL uses cache (no new GraphQL calls)
      clockTime = clockTime.add(const Duration(minutes: 5));
      final second = await service.fetchWeeklySchedule(now: referenceNow);
      expect(second.isStaleCache, isFalse);
      expect(callCount, 2);

      // forceRefresh bypasses cache
      final refreshed = await service.fetchWeeklySchedule(
        now: referenceNow,
        forceRefresh: true,
      );
      expect(refreshed.isStaleCache, isFalse);
      expect(callCount, 4);

      // Expired cache + network failure returns stale cache
      clockTime = clockTime.add(const Duration(minutes: 15));
      shouldThrow = true;
      final stale = await service.fetchWeeklySchedule(now: referenceNow);
      expect(stale.isStaleCache, isTrue);
      expect(stale.entriesForDate(DateTime(2026, 11, 25)).single.title, 'Solo Leveling');

      // Different uncached week + network failure rethrows exception
      final otherWeekNow = DateTime(2026, 12, 9, 12, 0);
      await expectLater(
        () => service.fetchWeeklySchedule(now: otherWeekNow),
        throwsException,
      );
    });
  });
}
