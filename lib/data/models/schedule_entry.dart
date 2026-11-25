import 'anime_item.dart';

/// Release state of a scheduled anime episode relative to a reference time.
enum ScheduleReleaseStatus {
  released,
  upcoming,
  delayedOrHiatus,
}

/// Pure local-calendar date and rolling Sunday-to-Saturday week helpers.
abstract final class ScheduleDateHelper {
  static const List<String> _shortDays = [
    'Min',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
  ];

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _upperMonths = [
    'JANUARI',
    'FEBRUARI',
    'MARET',
    'APRIL',
    'MEI',
    'JUNI',
    'JULI',
    'AGUSTUS',
    'SEPTEMBER',
    'OKTOBER',
    'NOVEMBER',
    'DESEMBER',
  ];

  /// Returns Sunday 00:00:00 local time for the rolling week containing [now].
  static DateTime weekStartSunday(DateTime now) {
    final daysFromSunday = now.weekday % 7;
    return DateTime(now.year, now.month, now.day - daysFromSunday);
  }

  /// Returns 7 consecutive local midnight dates from Sunday through Saturday.
  static List<DateTime> weekDays(DateTime now) {
    final start = weekStartSunday(now);
    return List<DateTime>.generate(
      7,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  /// Formats [dt] as a `YYYY-MM-DD` date key in its local calendar date.
  static String dateKey(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Maps Sunday..Saturday to Indonesian short day labels (`Min`..`Sab`).
  static String shortDayLabel(DateTime dt) => _shortDays[dt.weekday % 7];

  /// Formats a short Indonesian month name (e.g. `Nov`, `Des`).
  static String shortMonthLabel(int month) => _shortMonths[month - 1];

  /// Formats an uppercase Indonesian month and year header (e.g. `NOVEMBER 2026`).
  static String monthYearHeader(DateTime dt) =>
      '${_upperMonths[dt.month - 1]} ${dt.year}';

  /// Formats the device's local GMT offset label (e.g. `Waktu Lokal · GMT+8`).
  static String gmtOffsetLabel(DateTime dt) {
    final totalMinutes = dt.timeZoneOffset.inMinutes;
    if (totalMinutes == 0) {
      return 'Waktu Lokal · GMT+0';
    }
    final sign = totalMinutes >= 0 ? '+' : '-';
    final absMinutes = totalMinutes.abs();
    final hours = absMinutes ~/ 60;
    final mins = absMinutes % 60;
    final offset = mins == 0
        ? '$sign$hours'
        : '$sign$hours:${mins.toString().padLeft(2, '0')}';
    return 'Waktu Lokal · GMT$offset';
  }

  /// Builds the daily section header title relative to [now].
  static String sectionHeaderTitle(DateTime selectedDate, DateTime now) {
    final selectedDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final today = DateTime(now.year, now.month, now.day);

    if (selectedDay == today) {
      return 'Tayang Hari Ini';
    }

    final formattedDate =
        '${shortDayLabel(selectedDay)}, ${selectedDay.day} ${shortMonthLabel(selectedDay.month)}';
    if (selectedDay.isBefore(today)) {
      return 'Sudah Tayang · $formattedDate';
    }
    return 'Akan Tayang · $formattedDate';
  }
}

/// Represents a single scheduled or delayed anime episode entry in a week.
class ScheduleEntry {
  final int scheduleId;
  final int mediaId;
  final String title;
  final String japaneseTitle;
  final String posterUrl;
  final String? bannerUrl;
  final double rating;
  final List<String> genres;
  final String synopsis;
  final String format;
  final int episodeNumber;
  final DateTime airingAt;
  final bool isHiatusOrDelayed;
  final DateTime? nextAiringAt;
  final String? delayNote;
  final bool hasVideoAvailable;

  const ScheduleEntry({
    required this.scheduleId,
    required this.mediaId,
    required this.title,
    this.japaneseTitle = '',
    this.posterUrl = '',
    this.bannerUrl,
    this.rating = 0.0,
    this.genres = const [],
    this.synopsis = '',
    this.format = 'TV',
    required this.episodeNumber,
    required this.airingAt,
    this.isHiatusOrDelayed = false,
    this.nextAiringAt,
    this.delayNote,
    this.hasVideoAvailable = false,
  });

  /// Determines release status at [now].
  ScheduleReleaseStatus statusAt(DateTime now) {
    if (isHiatusOrDelayed) {
      return ScheduleReleaseStatus.delayedOrHiatus;
    }
    if (!airingAt.isAfter(now)) {
      return ScheduleReleaseStatus.released;
    }
    return ScheduleReleaseStatus.upcoming;
  }

  /// Formats [airingAt] local time as `HH:mm`.
  String formattedTime() {
    final hh = airingAt.hour.toString().padLeft(2, '0');
    final mm = airingAt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Formats status text relative to [now] without em-dash characters.
  String formatStatusText(DateTime now) {
    switch (statusAt(now)) {
      case ScheduleReleaseStatus.delayedOrHiatus:
        final note = delayNote?.trim();
        if (note != null && note.isNotEmpty) {
          return note;
        }
        if (nextAiringAt != null) {
          final next = nextAiringAt!;
          return 'Libur minggu ini · Tayang lagi ${next.day} ${ScheduleDateHelper.shortMonthLabel(next.month)}';
        }
        return 'Libur minggu ini';

      case ScheduleReleaseStatus.released:
        final elapsed = now.difference(airingAt);
        final prefix = elapsed.inMinutes < 60 ? 'Baru rilis' : 'Sudah rilis';
        return '$prefix · ${formattedTime()}';

      case ScheduleReleaseStatus.upcoming:
        final remaining = airingAt.difference(now);
        final countdown = _formatCountdown(remaining);
        return 'Rilis ${formattedTime()} · Dalam $countdown';
    }
  }

  String _formatCountdown(Duration remaining) {
    if (remaining.inDays >= 1) {
      final days = remaining.inDays;
      final hours = remaining.inHours % 24;
      return hours > 0 ? '${days}h ${hours}j' : '${days}h';
    }
    if (remaining.inHours >= 1) {
      final hours = remaining.inHours;
      final mins = remaining.inMinutes % 60;
      return mins > 0 ? '${hours}j ${mins}m' : '${hours}j';
    }
    final mins = remaining.inMinutes < 1 ? 1 : remaining.inMinutes;
    return '${mins}m';
  }

  /// Converts this schedule entry into an [AnimeItem] for detail navigation.
  AnimeItem toAnimeItem() {
    final resolvedBackdrop =
        (bannerUrl != null && bannerUrl!.isNotEmpty) ? bannerUrl! : posterUrl;
    return AnimeItem(
      id: mediaId.toString(),
      title: title,
      japaneseTitle: japaneseTitle,
      rating: rating,
      releaseYear: airingAt.year,
      genres: genres,
      description: synopsis,
      posterUrl: posterUrl,
      backdropUrl: resolvedBackdrop,
      episodeInfo: '$format · EP $episodeNumber',
      statusLabel: isHiatusOrDelayed ? 'Hiatus / Tertunda' : 'Ongoing',
      aniListId: mediaId,
      hasVideoAvailable: hasVideoAvailable,
      bannerUrl: bannerUrl,
    );
  }
}

/// Aggregated weekly schedule entries keyed by `YYYY-MM-DD`.
class WeeklyScheduleResult {
  final DateTime weekStart;
  final DateTime weekEnd;
  final Map<String, List<ScheduleEntry>> entriesByDateKey;
  final bool isStaleCache;

  const WeeklyScheduleResult({
    required this.weekStart,
    required this.weekEnd,
    required this.entriesByDateKey,
    this.isStaleCache = false,
  });

  /// Returns all schedule entries for [date], or an empty list if none exist.
  List<ScheduleEntry> entriesForDate(DateTime date) =>
      entriesByDateKey[ScheduleDateHelper.dateKey(date)] ?? const [];
}
