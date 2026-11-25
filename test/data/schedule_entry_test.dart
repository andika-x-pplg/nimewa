import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/data/models/schedule_entry.dart';

void main() {
  group('ScheduleDateHelper', () {
    test('weekStartSunday returns Sunday 00:00:00 for mid-week date', () {
      final wednesday = DateTime(2026, 11, 25, 14, 30);
      final start = ScheduleDateHelper.weekStartSunday(wednesday);

      expect(start, DateTime(2026, 11, 22, 0, 0, 0));
      expect(start.weekday, DateTime.sunday);
    });

    test('weekStartSunday rolls over to new week on Sunday', () {
      final nextSunday = DateTime(2026, 11, 29, 0, 30);
      final start = ScheduleDateHelper.weekStartSunday(nextSunday);

      expect(start, DateTime(2026, 11, 29, 0, 0, 0));
      expect(start.weekday, DateTime.sunday);
    });

    test('weekStartSunday handles month boundary crossing back to October', () {
      final wednesday = DateTime(2026, 11, 4, 10, 0);
      final start = ScheduleDateHelper.weekStartSunday(wednesday);

      expect(start, DateTime(2026, 11, 1, 0, 0, 0));

      final monday = DateTime(2026, 11, 2, 10, 0);
      expect(
        ScheduleDateHelper.weekStartSunday(monday),
        DateTime(2026, 11, 1),
      );

      final tuesdayDec = DateTime(2026, 12, 1, 9, 0);
      expect(
        ScheduleDateHelper.weekStartSunday(tuesdayDec),
        DateTime(2026, 11, 29),
      );
    });

    test('weekDays returns 7 consecutive days starting Min (22) through Sab (28)', () {
      final wednesday = DateTime(2026, 11, 25, 7, 0);
      final days = ScheduleDateHelper.weekDays(wednesday);

      expect(days.length, 7);
      expect(days.first, DateTime(2026, 11, 22));
      expect(days.last, DateTime(2026, 11, 28));
      expect(
        days.map(ScheduleDateHelper.shortDayLabel).toList(),
        ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'],
      );
      expect(days.map((d) => d.day).toList(), [22, 23, 24, 25, 26, 27, 28]);
    });

    test('shortDayLabel maps Sunday..Saturday to Indonesian short labels', () {
      expect(ScheduleDateHelper.shortDayLabel(DateTime(2026, 11, 22)), 'Min');
      expect(ScheduleDateHelper.shortDayLabel(DateTime(2026, 11, 23)), 'Sen');
      expect(ScheduleDateHelper.shortDayLabel(DateTime(2026, 11, 24)), 'Sel');
      expect(ScheduleDateHelper.shortDayLabel(DateTime(2026, 11, 25)), 'Rab');
      expect(ScheduleDateHelper.shortDayLabel(DateTime(2026, 11, 26)), 'Kam');
      expect(ScheduleDateHelper.shortDayLabel(DateTime(2026, 11, 27)), 'Jum');
      expect(ScheduleDateHelper.shortDayLabel(DateTime(2026, 11, 28)), 'Sab');
    });

    test('dateKey formats YYYY-MM-DD with zero padding', () {
      expect(
        ScheduleDateHelper.dateKey(DateTime(2026, 11, 25, 23, 59)),
        '2026-11-25',
      );
      expect(
        ScheduleDateHelper.dateKey(DateTime(2026, 1, 5, 0, 30)),
        '2026-01-05',
      );
    });

    test('monthYearHeader formats uppercase Indonesian month and year', () {
      expect(
        ScheduleDateHelper.monthYearHeader(DateTime(2026, 11, 25)),
        'NOVEMBER 2026',
      );
      expect(
        ScheduleDateHelper.monthYearHeader(DateTime(2026, 8, 1)),
        'AGUSTUS 2026',
      );
      expect(
        ScheduleDateHelper.monthYearHeader(DateTime(2026, 12, 31)),
        'DESEMBER 2026',
      );
    });

    test('gmtOffsetLabel formats local timezone offset dynamically', () {
      final now = DateTime(2026, 11, 25, 7, 0);
      final label = ScheduleDateHelper.gmtOffsetLabel(now);

      expect(label, startsWith('Waktu Lokal · GMT'));
      expect(label.contains('\u2014'), isFalse);

      final utcLabel = ScheduleDateHelper.gmtOffsetLabel(
        DateTime.utc(2026, 11, 25, 7, 0),
      );
      expect(utcLabel, 'Waktu Lokal · GMT+0');
    });

    test('sectionHeaderTitle formats today, past, and future dates without em-dash', () {
      final now = DateTime(2026, 11, 25, 7, 0);

      expect(
        ScheduleDateHelper.sectionHeaderTitle(DateTime(2026, 11, 25, 22, 0), now),
        'Tayang Hari Ini',
      );
      expect(
        ScheduleDateHelper.sectionHeaderTitle(DateTime(2026, 11, 22), now),
        'Sudah Tayang · Min, 22 Nov',
      );
      expect(
        ScheduleDateHelper.sectionHeaderTitle(DateTime(2026, 11, 26), now),
        'Akan Tayang · Kam, 26 Nov',
      );
    });
  });

  group('ScheduleEntry', () {
    ScheduleEntry makeEntry({
      int scheduleId = 101,
      int mediaId = 154587,
      String title = 'Frieren',
      String japaneseTitle = '葬送のフリーレン',
      String posterUrl = 'https://example.com/poster.jpg',
      String? bannerUrl = 'https://example.com/banner.jpg',
      double rating = 9.1,
      List<String> genres = const ['Adventure', 'Fantasy'],
      String synopsis = 'An elven mage travels.',
      String format = 'TV',
      int episodeNumber = 8,
      required DateTime airingAt,
      bool isHiatusOrDelayed = false,
      DateTime? nextAiringAt,
      String? delayNote,
      bool hasVideoAvailable = true,
    }) {
      return ScheduleEntry(
        scheduleId: scheduleId,
        mediaId: mediaId,
        title: title,
        japaneseTitle: japaneseTitle,
        posterUrl: posterUrl,
        bannerUrl: bannerUrl,
        rating: rating,
        genres: genres,
        synopsis: synopsis,
        format: format,
        episodeNumber: episodeNumber,
        airingAt: airingAt,
        isHiatusOrDelayed: isHiatusOrDelayed,
        nextAiringAt: nextAiringAt,
        delayNote: delayNote,
        hasVideoAvailable: hasVideoAvailable,
      );
    }

    test('statusAt and formatStatusText handle released, upcoming, and delayed items', () {
      final now = DateTime(2026, 11, 25, 7, 0);

      final justReleased = makeEntry(
        airingAt: DateTime(2026, 11, 25, 6, 28),
      );
      expect(justReleased.statusAt(now), ScheduleReleaseStatus.released);
      expect(justReleased.formattedTime(), '06:28');
      expect(justReleased.formatStatusText(now), 'Baru rilis · 06:28');

      final earlierReleased = makeEntry(
        airingAt: DateTime(2026, 11, 25, 5, 0),
      );
      expect(earlierReleased.statusAt(now), ScheduleReleaseStatus.released);
      expect(earlierReleased.formattedTime(), '05:00');
      expect(earlierReleased.formatStatusText(now), 'Sudah rilis · 05:00');

      final upcomingNextDay = makeEntry(
        airingAt: DateTime(2026, 11, 26, 6, 28),
      );
      expect(upcomingNextDay.statusAt(now), ScheduleReleaseStatus.upcoming);
      expect(
        upcomingNextDay.formatStatusText(now),
        'Rilis 06:28 · Dalam 23j 28m',
      );

      final upcomingSameDay = makeEntry(
        airingAt: DateTime(2026, 11, 25, 19, 30),
      );
      expect(upcomingSameDay.statusAt(now), ScheduleReleaseStatus.upcoming);
      expect(
        upcomingSameDay.formatStatusText(now),
        'Rilis 19:30 · Dalam 12j 30m',
      );

      final upcomingMultiDay = makeEntry(
        airingAt: DateTime(2026, 11, 27, 10, 0),
      );
      expect(upcomingMultiDay.statusAt(now), ScheduleReleaseStatus.upcoming);
      expect(
        upcomingMultiDay.formatStatusText(now),
        'Rilis 10:00 · Dalam 2h 3j',
      );

      final delayed = makeEntry(
        airingAt: DateTime(2026, 11, 28, 17, 0),
        isHiatusOrDelayed: true,
        nextAiringAt: DateTime(2026, 12, 5, 17, 0),
        delayNote: 'Libur minggu ini · Tayang lagi 5 Des',
      );
      expect(delayed.statusAt(now), ScheduleReleaseStatus.delayedOrHiatus);
      expect(
        delayed.formatStatusText(now),
        'Libur minggu ini · Tayang lagi 5 Des',
      );
    });

    test('toAnimeItem preserves id, aniListId, title, posterUrl, and hasVideoAvailable', () {
      final entry = makeEntry(
        mediaId: 21,
        title: 'One Piece',
        japaneseTitle: 'ワンピース',
        posterUrl: 'https://example.com/op.jpg',
        bannerUrl: null,
        rating: 8.7,
        genres: const ['Action', 'Adventure'],
        synopsis: 'Pirates set sail.',
        format: 'TV',
        episodeNumber: 1122,
        airingAt: DateTime(2026, 11, 22, 9, 30),
        hasVideoAvailable: false,
      );

      final animeItem = entry.toAnimeItem();

      expect(animeItem, isA<AnimeItem>());
      expect(animeItem.id, '21');
      expect(animeItem.aniListId, 21);
      expect(animeItem.title, 'One Piece');
      expect(animeItem.japaneseTitle, 'ワンピース');
      expect(animeItem.posterUrl, 'https://example.com/op.jpg');
      expect(animeItem.backdropUrl, 'https://example.com/op.jpg');
      expect(animeItem.hasVideoAvailable, isFalse);
      expect(animeItem.rating, 8.7);
      expect(animeItem.genres, ['Action', 'Adventure']);
      expect(animeItem.description, 'Pirates set sail.');
    });
  });

  group('WeeklyScheduleResult', () {
    test('entriesForDate returns entries matching dateKey or empty list', () {
      final entry = ScheduleEntry(
        scheduleId: 1,
        mediaId: 10,
        title: 'Dandadan',
        japaneseTitle: 'ダンダダン',
        posterUrl: 'https://example.com/ddd.jpg',
        episodeNumber: 9,
        airingAt: DateTime(2026, 11, 26, 22, 0),
      );

      final result = WeeklyScheduleResult(
        weekStart: DateTime(2026, 11, 22),
        weekEnd: DateTime(2026, 11, 28, 23, 59, 59),
        entriesByDateKey: {
          '2026-11-26': [entry],
        },
        isStaleCache: false,
      );

      expect(result.entriesForDate(DateTime(2026, 11, 26, 8, 0)), [entry]);
      expect(result.entriesForDate(DateTime(2026, 11, 25)), isEmpty);
    });
  });
}
