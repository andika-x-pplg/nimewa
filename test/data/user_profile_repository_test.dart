import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_detail.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/data/services/user_profile_repository.dart';

void main() {
  AnimeDetail makeDetail({String id = '154587', String title = 'Frieren'}) {
    return AnimeDetail(
      id: id,
      aniListId: 154587,
      title: title,
      japaneseTitle: '葬送のフリーレン',
      synopsis: 'Journey.',
      rating: 9.1,
      releaseYear: 2023,
      status: 'Completed',
      genres: const ['Adventure'],
      studio: 'Madhouse',
      posterUrl: '',
      backdropUrl: '',
      totalEpisodes: 28,
      hasVideoAvailable: true,
      episodes: const [
        EpisodeItem(
          id: 'ep-1',
          episodeNumber: 1,
          title: 'Episode 1',
          releaseDate: '2023',
          streamUrl: '',
        ),
      ],
    );
  }

  group('UserProfileRepository', () {
    test('updates username and derives uppercase initial', () async {
      final repo = UserProfileRepository(disablePersistence: true);
      await repo.init();
      expect(repo.username, equals('dikzzz'));
      expect(repo.initial, equals('D'));

      await repo.updateUsername('budi santoso');
      expect(repo.username, equals('budi santoso'));
      expect(repo.initial, equals('B'));
    });

    test('records watch history with exact position and formats MM:SS / HH:MM:SS', () async {
      final repo = UserProfileRepository(disablePersistence: true);
      await repo.init();
      final detail = makeDetail();

      await repo.recordWatchHistory(
        detail: detail,
        episodeNumber: 3,
        episodeTitle: 'Episode 3',
        positionSeconds: 3725, // 1:02:05
        durationSeconds: 5400,
      );

      expect(repo.watchHistory.length, equals(1));
      final entry = repo.watchHistory.first;
      expect(entry.formattedPosition, equals('1:02:05'));
      expect(
        repo.getSavedPosition(detail.id, 3, aniListId: 154587, title: detail.title),
        equals(const Duration(seconds: 3725)),
      );
      expect(
        repo.getSavedPosition(detail.id, 2, aniListId: 154587, title: detail.title),
        isNull,
      );
    });

    test('persists profile and watch history to JSON and reloads', () async {
      final tempDir = await Directory.systemTemp.createTemp('nimeva_profile_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final file = File('${tempDir.path}/profile.json');

      final repo1 = UserProfileRepository(storageFile: file);
      await repo1.init();
      await repo1.updateUsername('NimevaUser');
      await repo1.recordWatchHistory(
        detail: makeDetail(),
        episodeNumber: 2,
        episodeTitle: 'Episode 2',
        positionSeconds: 185,
        durationSeconds: 1440,
      );

      final repo2 = UserProfileRepository(storageFile: file);
      await repo2.init();
      expect(repo2.username, equals('NimevaUser'));
      expect(repo2.initial, equals('N'));
      expect(repo2.watchHistory.length, equals(1));
      expect(repo2.watchHistory.first.positionSeconds, equals(185));
    });
  });
}

