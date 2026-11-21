import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/owner_subtitle_repository.dart';
import 'package:nimeva/data/services/owner_video_repository.dart';

void main() {
  group('OwnerSubtitleRepository Tests', () {
    late OwnerSubtitleRepository repo;

    setUp(() {
      repo = OwnerSubtitleRepository.instance;
      repo.resetToDefaults();
    });

    test('parseSrt parses SubRip timestamps and Indonesian text accurately', () {
      const srt = '''
1
00:00:18,000 --> 00:00:24,000
Manusia telah mencemari Bumi...

2
00:00:26,500 --> 00:00:32,000
Siapa aku? Hanya seseorang yang menjadi pahlawan untuk hobi semata.
''';

      final cues = OwnerSubtitleRepository.parseSrt(srt);
      expect(cues.length, equals(2));
      expect(cues[0].index, equals(1));
      expect(cues[0].start, equals(const Duration(seconds: 18)));
      expect(cues[0].end, equals(const Duration(seconds: 24)));
      expect(cues[0].text, equals('Manusia telah mencemari Bumi...'));

      expect(cues[1].index, equals(2));
      expect(cues[1].start, equals(const Duration(milliseconds: 26500)));
      expect(cues[1].end, equals(const Duration(seconds: 32)));
      expect(cues[1].text, contains('Siapa aku?'));
    });

    test('returns Indonesian subtitle for registered owner video during active dialogue', () {
      // One Punch Man S1 Ep 1 (AniList ID 21087)
      final sub = repo.getSubtitleForVideo(
        aniListId: 21087,
        seasonNumber: 1,
        episodeNumber: 1,
        position: const Duration(seconds: 20),
      );
      expect(sub, contains('Manusia telah mencemari Bumi'));
    });

    test('returns empty string during pause / silence interval (text vanishes)', () {
      // Between 24.0s and 26.5s in OPM S1 Ep 1 is silence
      final sub = repo.getSubtitleForVideo(
        aniListId: 21087,
        seasonNumber: 1,
        episodeNumber: 1,
        position: const Duration(seconds: 25),
      );
      expect(sub, isEmpty);
    });

    test('strictly returns empty string for non-owner anime (never scrapes internet automatically)', () {
      // Random anime ID 99999 not registered to app owner
      final sub = repo.getSubtitleForVideo(
        aniListId: 99999,
        seasonNumber: 1,
        episodeNumber: 1,
        position: const Duration(seconds: 20),
      );
      expect(sub, isEmpty);
      expect(repo.hasSubtitleForVideo(aniListId: 99999, seasonNumber: 1, episodeNumber: 1), isFalse);
    });

    test('registers custom .srt matching video ID and filename perfectly', () {
      const customSrt = '''
1
00:00:05,000 --> 00:00:10,000
Halo dunia anime! Ini subtitle kustom pemilik.
''';
      // Register for an owner video
      repo.registerSrtFile(
        aniListId: 41370,
        seasonNumber: 1,
        episodeNumber: 99,
        srtContent: customSrt,
      );

      final videoId = OwnerSubtitleRepository.buildVideoId(41370, 1, 99);
      expect(videoId, equals('owner_41370_s1_ep99'));
      expect(OwnerSubtitleRepository.buildFileName(41370, 1, 99), equals('owner_41370_s1_ep99.srt'));

      // If registered to OwnerVideoRepository
      OwnerVideoRepository.instance.ensureVideosForAnime(
        aniListId: 41370,
        seasonNumber: 1,
        count: 100,
        seriesTitle: 'Demon Slayer',
      );

      final result = repo.getSubtitleForVideo(
        aniListId: 41370,
        seasonNumber: 1,
        episodeNumber: 99,
        position: const Duration(seconds: 7),
      );
      expect(result, contains('Halo dunia anime'));
    });
  });
}

