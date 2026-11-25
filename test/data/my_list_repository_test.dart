import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_detail.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/data/models/my_list_entry.dart';
import 'package:nimeva/data/services/my_list_repository.dart';

void main() {
  group('MyListRepository', () {
    late DateTime currentClock;

    setUp(() {
      currentClock = DateTime(2026, 11, 25, 14, 0);
    });

    AnimeItem makePlayableItem({
      String id = 'demon-slayer',
      int aniListId = 0,
      String title = 'Demon Slayer: Kimetsu no Yaiba',
      String episodeInfo = 'SUB · 26 EPS (Tamat)',
    }) {
      return AnimeItem(
        id: id,
        title: title,
        japaneseTitle: '鬼滅の刃',
        rating: 8.5,
        releaseYear: 2019,
        genres: const ['Action', 'Fantasy'],
        description: 'Tanjiro becomes a Demon Slayer.',
        posterUrl: 'https://example.com/ds.jpg',
        backdropUrl: 'https://example.com/ds-bg.jpg',
        episodeInfo: episodeInfo,
        aniListId: aniListId,
        hasVideoAvailable: true,
      );
    }

    AnimeDetail makeDetail({
      String id = '101922',
      int aniListId = 101922,
      String title = 'Demon Slayer: Kimetsu no Yaiba',
      int totalEpisodes = 26,
      bool hasVideoAvailable = true,
    }) {
      return AnimeDetail(
        id: id,
        title: title,
        japaneseTitle: '鬼滅の刃',
        rating: 8.5,
        releaseYear: 2019,
        genres: const ['Action', 'Fantasy'],
        synopsis: 'Tanjiro becomes a Demon Slayer.',
        posterUrl: 'https://example.com/ds.jpg',
        backdropUrl: 'https://example.com/ds-bg.jpg',
        status: 'Tamat',
        studio: 'ufotable',
        totalEpisodes: totalEpisodes,
        aniListId: aniListId,
        hasVideoAvailable: hasVideoAvailable,
        episodes: hasVideoAvailable
            ? List.generate(
                totalEpisodes,
                (i) => EpisodeItem(
                  id: '$id-ep-${i + 1}',
                  episodeNumber: i + 1,
                  title: 'Episode ${i + 1}',
                  releaseDate: '2019-04-06',
                  streamUrl: 'https://archive.org/download/knys1/ep${i + 1}.mp4',
                ),
              )
            : const [],
      );
    }

    test('deduplicates canonical keys across Home slug, AniList ID, and Detail', () async {
      final repo = MyListRepository(
        disablePersistence: true,
        clock: () => currentClock,
      );

      final added = await repo.toggleSaveAnime(
        makePlayableItem(id: 'demon-slayer', aniListId: 0),
      );
      expect(added, isTrue);
      expect(repo.countByStatus(MyListStatus.saved), equals(1));
      expect(repo.contains('101922', aniListId: 101922, title: 'Demon Slayer: Kimetsu no Yaiba'), isTrue);

      // Toggling from Detail using AniList ID 101922 removes the exact same entry
      final stillSaved = await repo.toggleSaveFromDetail(makeDetail(id: '101922', aniListId: 101922));
      expect(stillSaved, isFalse);
      expect(repo.allEntries, isEmpty);
    });

    test('recordWatchProgress advances Saved -> Watching -> Completed automatically for playable anime', () async {
      final repo = MyListRepository(
        disablePersistence: true,
        clock: () => currentClock,
      );

      final detail = makeDetail(
        id: '101922',
        aniListId: 101922,
        title: 'Demon Slayer: Kimetsu no Yaiba',
        totalEpisodes: 12,
        hasVideoAvailable: true,
      );

      // Save first -> Saved (0%)
      await repo.toggleSaveFromDetail(detail);
      expect(repo.entriesByStatus(MyListStatus.saved).length, equals(1));

      // Play Episode 1 -> moves to Watching
      currentClock = currentClock.add(const Duration(minutes: 5));
      await repo.recordWatchProgress(detail: detail, episodeNumber: 1, episodeTitle: 'Episode 1 - Kekejaman');
      expect(repo.entriesByStatus(MyListStatus.saved), isEmpty);
      expect(repo.entriesByStatus(MyListStatus.watching).length, equals(1));
      var entry = repo.findEntry('101922', aniListId: 101922, title: detail.title)!;
      expect(entry.watchedEpisode, equals(1));
      expect(entry.completedPercent, equals(8));

      // Play Episode 2 -> advances to 2/12
      currentClock = currentClock.add(const Duration(minutes: 20));
      await repo.recordWatchProgress(detail: detail, episodeNumber: 2, episodeTitle: 'Episode 2');
      entry = repo.findEntry('101922', aniListId: 101922, title: detail.title)!;
      expect(entry.watchedEpisode, equals(2));

      // Re-opening Episode 1 does not regress watchedEpisode
      await repo.recordWatchProgress(detail: detail, episodeNumber: 1, episodeTitle: 'Episode 1');
      entry = repo.findEntry('101922', aniListId: 101922, title: detail.title)!;
      expect(entry.watchedEpisode, equals(2));

      // Play Episode 12 -> automatically Completed (100%)
      await repo.recordWatchProgress(detail: detail, episodeNumber: 12, episodeTitle: 'Episode 12');
      expect(repo.entriesByStatus(MyListStatus.watching), isEmpty);
      expect(repo.entriesByStatus(MyListStatus.completed).length, equals(1));
      entry = repo.findEntry('101922', aniListId: 101922, title: detail.title)!;
      expect(entry.completedPercent, equals(100));
    });

    test('unavailable-video anime can be saved at 0% and is ignored by automatic watch tracking', () async {
      final repo = MyListRepository(
        disablePersistence: true,
        clock: () => currentClock,
      );

      const externalItem = AnimeItem(
        id: '166240',
        title: 'Dan Da Dan',
        japaneseTitle: 'ダンダダン',
        rating: 8.6,
        releaseYear: 2024,
        genres: ['Action'],
        description: 'Aliens vs ghosts.',
        posterUrl: '',
        backdropUrl: '',
        episodeInfo: 'SUB · 12 EPS',
        aniListId: 166240,
        hasVideoAvailable: true, // Even if mock/API item claims true, resolver is authoritative (false)
      );

      await repo.toggleSaveAnime(externalItem);
      final saved = repo.entriesByStatus(MyListStatus.saved).single;
      expect(saved.hasVideoAvailable, isFalse);
      expect(saved.completedPercent, equals(0));
      expect(saved.progressSummaryText, equals('Platform resmi · Progres 0%'));

      // recordWatchProgress refuses to increment unavailable-video anime
      final externalDetail = makeDetail(
        id: '166240',
        aniListId: 166240,
        title: 'Dan Da Dan',
        totalEpisodes: 0,
        hasVideoAvailable: false,
      );
      await repo.recordWatchProgress(detail: externalDetail, episodeNumber: 1);
      final after = repo.entriesByStatus(MyListStatus.saved).single;
      expect(after.watchedEpisode, equals(0));
      expect(after.status, equals(MyListStatus.saved));

      // Manual progress update works even when totalEpisodes was 0
      await repo.updateEpisodeProgress(after.canonicalKey, 4);
      final manual = repo.entriesByStatus(MyListStatus.watching).single;
      expect(manual.watchedEpisode, equals(4));
    });

    test('supports manual updateStatus, removeEntry, and restoreEntry', () async {
      final repo = MyListRepository(
        disablePersistence: true,
        clock: () => currentClock,
      );

      await repo.toggleSaveAnime(makePlayableItem(id: 'demon-slayer', aniListId: 101922));
      final entry = repo.allEntries.single;

      await repo.updateStatus(entry.canonicalKey, MyListStatus.completed);
      expect(repo.entriesByStatus(MyListStatus.completed).single.watchedEpisode, equals(26));
      expect(repo.entriesByStatus(MyListStatus.completed).single.completedPercent, equals(100));

      final removed = await repo.removeEntry(entry.canonicalKey);
      expect(removed, isNotNull);
      expect(repo.allEntries, isEmpty);

      await repo.restoreEntry(removed!);
      expect(repo.allEntries.length, equals(1));
      expect(repo.entriesByStatus(MyListStatus.completed).single.watchedEpisode, equals(26));
    });

    test('persists entries to JSON file and reloads in a fresh MyListRepository instance', () async {
      final tempDir = await Directory.systemTemp.createTemp('nimeva_mylist_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final storageFile = File('${tempDir.path}/my_list.json');

      final repo1 = MyListRepository(storageFile: storageFile, clock: () => currentClock);
      await repo1.init();
      await repo1.toggleSaveAnime(makePlayableItem(id: 'demon-slayer', aniListId: 101922));
      await repo1.updateEpisodeProgress('demon-slayer', 7);

      final repo2 = MyListRepository(storageFile: storageFile, clock: () => currentClock);
      await repo2.init();
      expect(repo2.allEntries.length, equals(1));
      final reloaded = repo2.allEntries.single;
      expect(reloaded.canonicalKey, equals('demon-slayer'));
      expect(reloaded.watchedEpisode, equals(7));
      expect(reloaded.status, equals(MyListStatus.watching));
    });
  });
}
