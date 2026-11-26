import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anilist_api_client.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';
import 'package:nimeva/data/services/owner_video_repository.dart';

void main() {
  test('audit all authentic playable anime for playback, duplicates, and posters', () async {
    const service = AnimeStreamService(networkDelay: Duration.zero);
    final keys = [
      'demon-slayer',
      'demon-slayer-s2',
      'demon-slayer-s4',
      'demon-slayer-mugen-tv',
      'attack-on-titan',
      'death-note',
      'jujutsu-kaisen-0',
      'tokyo-revengers',
      'tokyo-revengers-s2',
      'tokyo-revengers-s3',
      'chainsaw-man',
      'chainsaw-man-movie',
      'naruto',
      'solo-leveling',
      'my-hero-academia',
      'rezero',
      'shigatsu-wa-kimi',
      'your-name',
      'haikyuu-movie',
      'gintama-movie',
      'silent-voice',
      'frieren',
      'one-punch-man',
    ];

    final issues = <String>[];
    for (final key in keys) {
      final detail = await service.getAnimeDetail(key);
      final playable = AnimeStreamResolver.hasCompleteEpisodes(detail.id, detail.title);
      if (!playable) {
        issues.add('NOT_PLAYABLE: $key (id=${detail.id}, title=${detail.title})');
      }
      if (detail.episodes.isEmpty) {
        issues.add('NO_EPISODES: $key');
      }
      if (detail.posterUrl.trim().isEmpty) {
        issues.add('EMPTY_POSTER: $key');
      }
      if (detail.backdropUrl.trim().isEmpty) {
        issues.add('EMPTY_BACKDROP: $key');
      }

      final seenNums = <int>{};
      final seenUrls = <String>{};
      for (final ep in detail.episodes) {
        if (!seenNums.add(ep.episodeNumber)) {
          issues.add('DUP_EP_NUM: $key ep ${ep.episodeNumber}');
        }
        final resolved = AnimeStreamResolver.resolveStreamUrl(
          animeId: detail.id,
          animeTitle: detail.title,
          server: 'Server 1 (Fast HD)',
          episodeNumber: ep.episodeNumber,
          existingStreamUrl: ep.streamUrl,
        );
        if (resolved.trim().isEmpty) {
          issues.add('EMPTY_STREAM_URL: $key ep ${ep.episodeNumber}');
        } else if (!seenUrls.add(resolved) && detail.episodes.length > 1) {
          issues.add('DUP_STREAM_URL: $key ep ${ep.episodeNumber} -> $resolved');
        }
      }

      // Also check OwnerVideoRepository if aniListId > 0
      if (detail.aniListId > 0) {
        final ownerEps = OwnerVideoRepository.instance.getVideosForAnime(detail.aniListId);
        if (ownerEps.isNotEmpty) {
          final ownerNums = <int>{};
          for (final o in ownerEps) {
            if (!ownerNums.add(o.episodeNumber)) {
              issues.add('OWNER_DUP_EP: $key (aniList=${detail.aniListId}) ep ${o.episodeNumber}');
            }
          }
        }
      }
    }

    // Print all issues clearly
    // ignore: avoid_print
    print('AUDIT_TOTAL_ISSUES=${issues.length}');
    for (final i in issues) {
      // ignore: avoid_print
      print('ISSUE: $i');
    }
    expect(
      AnimeStreamResolver.hasCompleteEpisodes('145139', 'Demon Slayer Swordsmith Village Arc'),
      isFalse,
    );
    expect(issues, isEmpty);
  });

  test('Boku no Kokoro S1 & S2 disabled until Japanese-audio subbed source exists, 9 added anime posters/IDs valid, and episode titles have no Sub Indo tag', () async {
    expect(AnimeStreamResolver.hasCompleteEpisodes('153152', 'Boku no Kokoro no Yabai Yatsu'), isFalse);
    expect(AnimeStreamResolver.hasCompleteEpisodes('166216', 'Boku no Kokoro no Yabai Yatsu 2nd Season'), isFalse);
    expect(AnimeStreamResolver.hasCompleteEpisodes('182317', 'Boku no Kokoro no Yabai Yatsu Movie'), isFalse);
    expect(AnimeStreamResolver.hasCompleteEpisodes('170221', 'Boku no Kokoro no Yabai Yatsu: Twi-Yaba'), isFalse);
    expect(AnimeStreamResolver.hasCompleteEpisodes('209247', 'Boku no Kokoro no Yabai Yatsu 3rd Season'), isFalse);

    const service = AnimeStreamService(networkDelay: Duration.zero);
    for (final key in ['demon-slayer', 'attack-on-titan', 'death-note', 'solo-leveling', 'chainsaw-man', 'tokyo-revengers']) {
      final detail = await service.getAnimeDetail(key);
      expect(detail.episodes, isNotEmpty, reason: '$key should have episodes');
      for (final ep in detail.episodes) {
        expect(ep.title.toLowerCase().contains('sub indo'), isFalse, reason: '$key ep ${ep.episodeNumber} title should not contain Sub Indo');
      }
    }
    expect(AnimeStreamResolver.getEpisodeTitle('101922', 'Demon Slayer', 1), 'Episode 1: Cruelty');
    expect(AnimeStreamResolver.getEpisodeTitle('151807', 'Solo Leveling', 1), 'Episode 1: I\'m Used to It');
    expect(AnimeStreamResolver.getEpisodeTitle('21087', 'One Punch Man', 1), 'Episode 1: The Strongest Man');

    const addedIds = {
      '153152',
      '166216',
      '127911',
      '132405',
      '154768',
      '143338',
      '163623',
      '170942',
      '177552',
    };
    final addedItems = AniListApiClient.cachedPopularAnime
        .where((a) => addedIds.contains(a.id))
        .toList();
    expect(addedItems.length, 9);
    expect(addedItems.map((a) => a.posterUrl).toSet().length, 9);
    expect(addedItems.map((a) => a.backdropUrl).toSet().length, 9);
    for (final item in addedItems) {
      expect(item.aniListId, int.parse(item.id));
    }

    const aotSequelIds = {
      '20958',
      '99147',
      '104578',
      '110277',
      '131681',
      '146984',
      '162314',
    };
    final aotItems = AniListApiClient.cachedPopularAnime
        .where((a) => aotSequelIds.contains(a.id))
        .toList();
    expect(aotItems.length, 7);
    expect(aotItems.map((a) => a.posterUrl).toSet().length, 7);
    expect(aotItems.map((a) => a.backdropUrl).toSet().length, 7);
    for (final item in aotItems) {
      expect(item.aniListId, int.parse(item.id));
      expect(
        AnimeStreamResolver.hasCompleteEpisodes(item.id, item.title),
        isFalse,
        reason: '${item.title} should not falsely fall back to AoT S1',
      );
    }

    const aotSpinoffs = [
      'Attack on Titan: Lost Girls',
      'Attack on Titan: Junior High',
      'Attack on Titan Part I: Crimson Bow and Arrow',
      'Attack on Titan Part II: Wings of Freedom',
      'Attack on Titan: The Roar of Awakening',
      'Attack on Titan: No Regrets',
      'Attack on Titan ~Chronicle~',
      'Attack on Titan OVA',
      'Attack on Titan Picture Drama',
      'Shingeki no Kyojin: Chimi Kyara Gekijou',
    ];
    for (final title in aotSpinoffs) {
      expect(
        AnimeStreamResolver.hasCompleteEpisodes('999000', title),
        isFalse,
        reason: '$title should be unavailable, not AoT S1',
      );
    }
  });
}

