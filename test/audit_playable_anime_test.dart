import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anime_stream_resolver.dart';
import 'package:nimeva/data/services/anime_stream_service.dart';
import 'package:nimeva/data/services/owner_video_repository.dart';

void main() {
  test('audit all authentic playable anime for playback, duplicates, and posters', () async {
    const service = AnimeStreamService(networkDelay: Duration.zero);
    final keys = [
      'demon-slayer',
      'demon-slayer-s2',
      'demon-slayer-s3',
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
    expect(issues, isEmpty);
  });
}

