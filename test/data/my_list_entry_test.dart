import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/my_list_entry.dart';

void main() {
  group('MyListEntry & MyListStatus', () {
    test('calculates completedPercent, remainingPercent, and progressFraction accurately', () {
      final entry = MyListEntry(
        canonicalKey: 'jujutsu-kaisen',
        animeId: 'jujutsu-kaisen',
        aniListId: 113415,
        title: 'Jujutsu Kaisen',
        japaneseTitle: '呪術廻戦',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        rating: 8.7,
        releaseYear: 2020,
        genres: const ['Action', 'Supernatural'],
        description: 'Yuji Itadori enters Jujutsu High.',
        totalEpisodes: 12,
        watchedEpisode: 8,
        currentEpisodeTitle: 'Episode 8',
        status: MyListStatus.watching,
        hasVideoAvailable: true,
        updatedAt: DateTime(2026, 11, 25, 10, 0),
      );

      expect(entry.completedPercent, equals(67));
      expect(entry.remainingPercent, equals(33));
      expect(entry.progressFraction, closeTo(0.67, 0.01));
      expect(entry.progressSummaryText, equals('8 dari 12 episode'));
      expect(entry.percentSummaryText, equals('67% selesai · Sisa 33%'));
    });

    test('handles 0 watched, totalEpisodes 0, and completed status safely without NaN', () {
      final saved = MyListEntry(
        canonicalKey: 'solo-leveling',
        animeId: 'solo-leveling',
        aniListId: 151807,
        title: 'Solo Leveling',
        japaneseTitle: '',
        posterUrl: '',
        backdropUrl: '',
        rating: 8.7,
        releaseYear: 2024,
        genres: const ['Action'],
        description: '',
        totalEpisodes: 0,
        watchedEpisode: 0,
        status: MyListStatus.saved,
        hasVideoAvailable: true,
        updatedAt: DateTime(2026, 11, 25),
      );

      expect(saved.completedPercent, equals(0));
      expect(saved.remainingPercent, equals(100));
      expect(saved.progressFraction, equals(0.0));
      expect(saved.percentSummaryText, equals('0% selesai · Sisa 100%'));

      final completed = saved.copyWith(
        totalEpisodes: 12,
        watchedEpisode: 15, // clamped
        status: MyListStatus.completed,
      );
      expect(completed.completedPercent, equals(100));
      expect(completed.remainingPercent, equals(0));
      expect(completed.progressFraction, equals(1.0));
    });

    test('shows external platform 0% message for unavailable-video anime in saved state', () {
      final external = MyListEntry(
        canonicalKey: 'dandadan',
        animeId: 'dandadan',
        aniListId: 166240,
        title: 'Dan Da Dan',
        japaneseTitle: 'ダンダダン',
        posterUrl: '',
        backdropUrl: '',
        rating: 8.6,
        releaseYear: 2024,
        genres: const ['Action'],
        description: '',
        totalEpisodes: 12,
        watchedEpisode: 0,
        status: MyListStatus.saved,
        hasVideoAvailable: false,
        updatedAt: DateTime(2026, 11, 25),
      );

      expect(external.progressSummaryText, equals('Platform resmi · Progres 0%'));
      expect(external.percentSummaryText, equals('0% selesai · Sisa 100%'));
    });

    test('parseTotalEpisodesFromInfo extracts episode count or 1 for movie', () {
      expect(MyListEntry.parseTotalEpisodesFromInfo('SUB · 24 EPS (Tamat)'), equals(24));
      expect(MyListEntry.parseTotalEpisodesFromInfo('SUB · MOVIE'), equals(1));
      expect(MyListEntry.parseTotalEpisodesFromInfo('Ongoing'), equals(0));
    });

    test('serializes to/from JSON and converts to AnimeItem', () {
      final original = MyListEntry(
        canonicalKey: 'demon-slayer',
        animeId: '101922',
        aniListId: 101922,
        title: 'Demon Slayer',
        japaneseTitle: '鬼滅の刃',
        posterUrl: 'https://example.com/kny.jpg',
        backdropUrl: 'https://example.com/kny-bg.jpg',
        rating: 8.5,
        releaseYear: 2019,
        genres: const ['Action', 'Fantasy'],
        description: 'Tanjiro becomes a Demon Slayer.',
        totalEpisodes: 26,
        watchedEpisode: 5,
        currentEpisodeTitle: 'Episode 5',
        status: MyListStatus.watching,
        hasVideoAvailable: true,
        updatedAt: DateTime(2026, 11, 25, 13, 30),
      );

      final roundtrip = MyListEntry.fromJson(original.toJson());
      expect(roundtrip.canonicalKey, equals('demon-slayer'));
      expect(roundtrip.aniListId, equals(101922));
      expect(roundtrip.watchedEpisode, equals(5));
      expect(roundtrip.totalEpisodes, equals(26));
      expect(roundtrip.status, equals(MyListStatus.watching));
      expect(roundtrip.hasVideoAvailable, isTrue);

      final item = roundtrip.toAnimeItem();
      expect(item.id, equals('101922'));
      expect(item.aniListId, equals(101922));
      expect(item.title, equals('Demon Slayer'));
      expect(item.hasVideoAvailable, isTrue);
      expect(item.episodeInfo, equals('SUB · 26 EPS'));
    });
  });
}

