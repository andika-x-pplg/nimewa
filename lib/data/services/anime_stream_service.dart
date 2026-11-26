import 'dart:convert';
import 'dart:io';

import 'anilist_api_client.dart';
import 'anime_api_client.dart';
import 'anime_stream_resolver.dart';
import '../models/anime_detail.dart';
import '../models/anime_item.dart';
import '../models/anime_relation_item.dart';
import '../models/episode_item.dart';

/// Service providing anime details, episode lists, and streaming endpoints.
/// Supports both online Sub Indo endpoints and built-in fallback catalogs.
class AnimeStreamService {
  final Duration networkDelay;
  final AnimeApiClient apiClient;
  final AniListApiClient anilistApiClient;

  const AnimeStreamService({
    this.networkDelay = const Duration(milliseconds: 50),
    this.apiClient = const AnimeApiClient(),
    this.anilistApiClient = const AniListApiClient(),
  });

  static final Map<String, String> _synopsisIdCache = {};

  static Future<String> translateSynopsisToIndonesian(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return clean;
    final cached = _synopsisIdCache[clean];
    if (cached != null) return cached;

    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': 'en',
        'tl': 'id',
        'dt': 't',
        'q': clean,
      });
      final client = HttpClient();
      try {
        final req = await client.getUrl(uri).timeout(const Duration(seconds: 2));
        final res = await req.close().timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final decoded = jsonDecode(body);
          if (decoded is List && decoded.isNotEmpty && decoded.first is List) {
            final buffer = StringBuffer();
            for (final segment in decoded.first as List) {
              if (segment is List && segment.isNotEmpty && segment.first != null) {
                buffer.write(segment.first.toString());
              }
            }
            final result = buffer.toString().trim();
            if (result.isNotEmpty) {
              _synopsisIdCache[clean] = result;
              return result;
            }
          }
        }
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      // Fallback to original synopsis when offline or rate-limited.
    }
    return clean;
  }

  /// Fetches spotlight anime (10 items) for home hero carousel.
  Future<List<AnimeItem>> getSpotlightAnime() async {
    if (networkDelay > Duration.zero) {
      await Future.delayed(networkDelay);
    }
    return anilistApiClient.fetchTrendingAnime(limit: 10);
  }

  /// Fetches explore anime catalog with reactive filtering, search query, and pagination.
  Future<List<AnimeItem>> getExploreAnimeList({
    required String filter,
    String? genre,
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    if (networkDelay > Duration.zero) {
      await Future.delayed(networkDelay);
    }

    final page = (offset ~/ limit) + 1;
    final cleanQuery = query?.trim();
    if (cleanQuery != null && cleanQuery.isNotEmpty) {
      return anilistApiClient.searchAnime(cleanQuery, limit: limit, page: page);
    } else if (genre != null && genre != 'Semua' && genre.isNotEmpty) {
      return anilistApiClient.fetchAnimeByCategory(genre, limit: limit, page: page);
    } else {
      switch (filter) {
        case 'latest':
          return anilistApiClient.fetchLatestAnime(limit: limit, page: page);
        case 'top_rated':
          return anilistApiClient.fetchTopRatedAnime(limit: limit, page: page);
        case 'popular':
        default:
          return anilistApiClient.fetchPopularAnime(limit: limit, page: page);
      }
    }
  }

  /// Fetches detailed metadata and all available episodes for an anime.
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    if (networkDelay > Duration.zero) {
      await Future.delayed(networkDelay);
    }

    final cleanId = animeId.toLowerCase().trim();
    final parsedAniListId = int.tryParse(cleanId);

    // If numeric AniList ID, fetch directly from AniList GraphQL client
    if (parsedAniListId != null) {
      try {
        final detail = await anilistApiClient.fetchAnimeDetail(parsedAniListId);
        final translatedSynopsis =
            await translateSynopsisToIndonesian(detail.synopsis);
        final hasVideo = AnimeStreamResolver.hasCompleteEpisodes(cleanId, detail.title);
        final key = AnimeStreamResolver.detectAnimeKey(cleanId, detail.title);
        final curated = _curatedDetails[key];
        if (hasVideo && curated != null && curated.episodes.isNotEmpty) {
          return detail.copyWith(
            synopsis: translatedSynopsis,
            hasVideoAvailable: true,
            episodes: curated.episodes,
            relations: detail.relations.isNotEmpty ? detail.relations : curated.relations,
          );
        }
        return detail.copyWith(
          synopsis: translatedSynopsis,
          hasVideoAvailable: hasVideo,
          episodes: hasVideo ? detail.episodes : const [],
        );
      } catch (_) {
        // Fall through to curated details
      }
    }

    if (_curatedDetails.containsKey(cleanId)) {
      return _curatedDetails[cleanId]!;
    }

    // Map known API ID aliases to curated details
    if (cleanId == 'solo-leveling' || cleanId == 'solo-leveling-s2' || cleanId == '46231' || cleanId == '151807') {
      return _curatedDetails['solo-leveling']!;
    }
    if (cleanId == 'tokyo-revengers-s4' || cleanId == '178945' || cleanId == '48960') {
      return _curatedDetails['tokyo-revengers-s4']!;
    }
    if (cleanId == 'yosuga-no-sora' || cleanId == '8861') {
      return _curatedDetails['yosuga-no-sora']!;
    }
    if (cleanId == 'tokyo-revengers-s3' || cleanId == 'tokyo-revengers-tenjiku' || cleanId == '47537' || cleanId == '163539') {
      return _curatedDetails['tokyo-revengers-s3']!;
    }
    if (cleanId == 'tokyo-revengers-s2' || cleanId == 'tokyo-revengers-seiya' || cleanId == '45697' || cleanId == '142853') {
      return _curatedDetails['tokyo-revengers-s2']!;
    }
    if (cleanId == 'tokyo-revengers' || cleanId == '43321' || cleanId == '120120') {
      return _curatedDetails['tokyo-revengers']!;
    }
    if (cleanId == '41370' || cleanId == '101922' || cleanId == 'kny' || cleanId == 'demon-slayer') {
      return _curatedDetails['demon-slayer']!;
    }
    if (cleanId == '7442' || cleanId == '16498' || cleanId == 'aot' || cleanId == 'attack-on-titan') {
      return _curatedDetails['attack-on-titan']!;
    }
    if (cleanId == '1376' || cleanId == '1535' || cleanId == 'death-note') {
      return _curatedDetails['death-note']!;
    }
    if (cleanId == '6448' || cleanId == '11061' || cleanId == 'hxh' || cleanId == 'hunter-x-hunter') {
      return _curatedDetails['hunter-x-hunter']!;
    }
    if (cleanId == '3936' || cleanId == '5114' || cleanId == 'fma' || cleanId == 'fullmetal-alchemist') {
      return _curatedDetails['fullmetal-alchemist']!;
    }
    if (cleanId == 'frieren' || cleanId == '154587' || cleanId == '46112') {
      return _curatedDetails['frieren']!;
    }
    if (cleanId == 'jujutsu-kaisen' || cleanId == '113415' || cleanId == '43806') {
      return _curatedDetails['jujutsu-kaisen']!;
    }
    if (cleanId == 'chainsaw-man' || cleanId == '127720' || cleanId == '44081') {
      return _curatedDetails['chainsaw-man']!;
    }
    if (cleanId == 'dandadan' || cleanId == '166240' || cleanId == '48363') {
      return _curatedDetails['dandadan']!;
    }
    if (cleanId == 'one-punch-man' || cleanId == '21087' || cleanId == 'opm') {
      return _curatedDetails['one-punch-man']!;
    }
    if (cleanId == 'one-punch-man-s2' || cleanId == '102194' || cleanId == '97668') {
      return _curatedDetails['one-punch-man-s2']!;
    }

    // Fetch from live API
    return apiClient.fetchAnimeDetail(cleanId);
  }

  /// Fetches video streaming URL for a specific episode.
  Future<String> getEpisodeStreamUrl(
    String episodeId, {
    String animeId = '',
    String title = '',
    String server = 'Server 1 (Fast HD)',
  }) async {
    if (networkDelay > Duration.zero) {
      await Future.delayed(networkDelay);
    }
    return AnimeStreamResolver.resolveStreamUrl(
      animeId: animeId.isNotEmpty ? animeId : episodeId,
      animeTitle: title,
      server: server,
    );
  }

  static final Map<String, AnimeDetail> _curatedDetails = {
    'solo-leveling': AnimeDetail(
      id: 'solo-leveling',
      title: 'Solo Leveling',
      japaneseTitle: '俺だけレベルアップな件',
      rating: 8.8,
      releaseYear: 2024,
      genres: const ['Action', 'Fantasy', 'Supernatural'],
      synopsis: 'Sung Jinwoo bangkit dari Hunter terlemah menjadi satu-satunya yang dapat naik level tanpa batas dalam membela dunia dari kehancuran.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/46231/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/46231/large.jpg',
      status: 'Tamat',
      studio: 'A-1 Pictures',
      totalEpisodes: 12,
      aniListId: 151807,
      hasVideoAvailable: true,
      relations: const [
        AnimeRelationItem(
          id: 176274,
          title: 'Solo Leveling Season 2: -Arise from the Shadow-',
          relationType: 'SEQUEL',
          format: 'TV',
          status: 'RELEASING',
        ),
      ],
      episodes: List.generate(
        12,
        (index) => EpisodeItem(
          id: 'solo-leveling-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Kebangkitan Bayangan',
          releaseDate: '2024-01-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'solo-leveling',
            animeTitle: 'Solo Leveling',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'tokyo-revengers-s3': AnimeDetail(
      id: 'tokyo-revengers-s3',
      title: 'Tokyo Revengers: Tenjiku Arc',
      japaneseTitle: '東京リベンジャーズ 天竺編',
      rating: 8.3,
      releaseYear: 2023,
      genres: const ['Action', 'Drama', 'Delinquents', 'Supernatural'],
      synopsis: 'Pertarungan sengit antara Tokyo Manji Gang dan geng Tenjiku pimpinan Izana Kurokawa dalam insiden Kanto Incident.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/47537/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/47537/large.jpg',
      status: 'Tamat',
      studio: 'LIDENFILMS',
      totalEpisodes: 13,
      aniListId: 163539,
      hasVideoAvailable: true,
      relations: const [
        AnimeRelationItem(
          id: 142853,
          title: 'Tokyo Revengers: Christmas Showdown',
          relationType: 'PREQUEL',
          format: 'TV',
          status: 'FINISHED',
        ),
        AnimeRelationItem(
          id: 178945,
          title: 'Tokyo Revengers: Santen Sensou-hen',
          relationType: 'SEQUEL',
          format: 'TV',
          status: 'NOT_YET_RELEASED',
        ),
      ],
      episodes: List.generate(
        13,
        (index) => EpisodeItem(
          id: 'tokyo-revengers-s3-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Insiden Kanto',
          releaseDate: '2023-10-${((index + 1) % 28) + 1}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'tokyo-revengers-s3',
            animeTitle: 'Tokyo Revengers Season 3',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'demon-slayer': AnimeDetail(
      id: 'demon-slayer',
      title: 'Demon Slayer: Kimetsu no Yaiba',
      japaneseTitle: '鬼滅の刃',
      rating: 8.9,
      releaseYear: 2019,
      genres: const ['Action', 'Fantasy', 'Historical'],
      synopsis: 'Tanjiro Kamado bertekad menjadi Pembasmi Iblis demi menyelamatkan adik tercintanya, Nezuko, yang telah berubah menjadi iblis.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/41370/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/41370/large.jpg',
      status: 'Tamat',
      studio: 'ufotable',
      totalEpisodes: 26,
      episodes: List.generate(
        26,
        (index) => EpisodeItem(
          id: 'demon-slayer-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} Sub Indo',
          releaseDate: '2019-04-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'demon-slayer',
            animeTitle: 'Demon Slayer',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'attack-on-titan': AnimeDetail(
      id: 'attack-on-titan',
      title: 'Attack on Titan (Shingeki no Kyojin)',
      japaneseTitle: '進撃の巨人',
      rating: 8.8,
      releaseYear: 2013,
      genres: const ['Action', 'Fantasy', 'Mystery'],
      synopsis: 'Eren Yeager dan Korps Survei bertarung membebaskan manusia dari teror raksasa pemakan manusia di balik dinding pertahanan.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/7442/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/7442/large.jpg',
      status: 'Tamat',
      studio: 'Wit Studio / MAPPA',
      totalEpisodes: 25,
      episodes: List.generate(
        25,
        (index) => EpisodeItem(
          id: 'attack-on-titan-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} Sub Indo',
          releaseDate: '2013-04-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'attack-on-titan',
            animeTitle: 'Attack on Titan',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'death-note': AnimeDetail(
      id: 'death-note',
      title: 'Death Note',
      japaneseTitle: 'デスノート',
      rating: 9.0,
      releaseYear: 2006,
      genres: const ['Mystery', 'Psychological', 'Supernatural'],
      synopsis: 'Light Yagami menggunakan buku catatan kematian untuk menciptakan dunia baru tanpa kejahatan, namun dihadang oleh detektif jenius L.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/1376/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/1376/large.jpg',
      status: 'Tamat',
      studio: 'Madhouse',
      totalEpisodes: 37,
      episodes: List.generate(
        37,
        (index) => EpisodeItem(
          id: 'death-note-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} Sub Indo',
          releaseDate: '2006-10-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'death-note',
            animeTitle: 'Death Note',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'hunter-x-hunter': const AnimeDetail(
      id: 'hunter-x-hunter',
      title: 'Hunter x Hunter (2011)',
      japaneseTitle: 'HUNTER×HUNTER',
      rating: 9.0,
      releaseYear: 2011,
      genres: ['Action', 'Adventure', 'Fantasy'],
      synopsis: 'Gon Freecss memulai petualangan berbahaya untuk menjadi Hunter berlisensi dan menemukan keberadaan ayahnya, Ging.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/6448/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/6448/large.jpg',
      status: 'Tamat',
      studio: 'Madhouse',
      totalEpisodes: 148,
      aniListId: 11061,
      hasVideoAvailable: false,
      episodes: [],
    ),
    'fullmetal-alchemist': const AnimeDetail(
      id: 'fullmetal-alchemist',
      title: 'Fullmetal Alchemist: Brotherhood',
      japaneseTitle: '鋼の錬金術師 FULLMETAL ALCHEMIST',
      rating: 9.1,
      releaseYear: 2009,
      genres: ['Action', 'Adventure', 'Drama', 'Fantasy'],
      synopsis: 'Edward dan Alphonse Elric mencari Batu Bertuah untuk memulihkan tubuh mereka yang hilang akibat transmutasi manusia terlarang.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/3936/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/3936/large.jpg',
      status: 'Tamat',
      studio: 'Bones',
      totalEpisodes: 64,
      aniListId: 5114,
      hasVideoAvailable: false,
      episodes: [],
    ),
    'frieren': AnimeDetail(
      id: 'frieren',
      title: 'Sousou no Frieren',
      japaneseTitle: '葬送のフリーレン',
      rating: 9.3,
      releaseYear: 2023,
      genres: const ['Fantasy', 'Adventure', 'Drama'],
      synopsis: 'Perjalanan panjang sang penyihir elf Frieren memahami arti hidup dan waktu manusia setelah mengalahkan raja iblis.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/46112/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/46112/large.jpg',
      status: 'Tayang',
      studio: 'Madhouse',
      totalEpisodes: 5,
      episodes: List.generate(
        5,
        (index) => EpisodeItem(
          id: 'frieren-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Perjalanan Elf',
          releaseDate: '2023-09-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'frieren',
            animeTitle: 'Sousou no Frieren',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'jujutsu-kaisen': const AnimeDetail(
      id: 'jujutsu-kaisen',
      title: 'Jujutsu Kaisen',
      japaneseTitle: '呪術廻戦',
      rating: 8.9,
      releaseYear: 2020,
      genres: ['Action', 'Supernatural', 'Fantasy'],
      synopsis: 'Yuji Itadori menelan jari kutukan Ryomen Sukuna dan memasuki dunia pertempuran penyihir Jujutsu.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/43806/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/43806/large.jpg',
      status: 'Tamat',
      studio: 'MAPPA',
      totalEpisodes: 24,
      aniListId: 113415,
      hasVideoAvailable: false,
      episodes: [],
    ),
    'chainsaw-man': AnimeDetail(
      id: 'chainsaw-man',
      title: 'Chainsaw Man',
      japaneseTitle: 'チェンソーマン',
      rating: 8.7,
      releaseYear: 2022,
      genres: const ['Action', 'Supernatural', 'Horror'],
      synopsis: 'Denji membuat kontrak dengan iblis gergaji Pochita dan bangkit sebagai Chainsaw Man.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/44081/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/44081/large.jpg',
      status: 'Tamat',
      studio: 'MAPPA',
      totalEpisodes: 12,
      episodes: List.generate(
        12,
        (index) => EpisodeItem(
          id: 'chainsaw-man-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} Sub Indo',
          releaseDate: '2022-10-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'chainsaw-man',
            animeTitle: 'Chainsaw Man',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'dandadan': const AnimeDetail(
      id: 'dandadan',
      title: 'Dan Da Dan',
      japaneseTitle: 'ダンダダン',
      rating: 8.7,
      releaseYear: 2024,
      genres: ['Action', 'Comedy', 'Sci-Fi'],
      synopsis: 'Pertarungan heboh alien dan roh kutukan bersama Momo Ayase dan Okarun.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/48363/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/48363/large.jpg',
      status: 'Tamat',
      studio: 'Science SARU',
      totalEpisodes: 12,
      aniListId: 166240,
      hasVideoAvailable: false,
      episodes: [],
    ),
    'tokyo-revengers': AnimeDetail(
      id: 'tokyo-revengers',
      title: 'Tokyo Revengers',
      japaneseTitle: '東京リベンジャーズ',
      rating: 8.1,
      releaseYear: 2021,
      genres: const ['Action', 'Drama', 'Delinquents', 'Supernatural'],
      synopsis: 'Takemichi Hanagaki melompati waktu 12 tahun ke masa lalu untuk menyelamatkan Hinata Tachibana.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/43321/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/43321/large.jpg',
      status: 'Tamat',
      studio: 'LIDENFILMS',
      totalEpisodes: 12,
      aniListId: 120120,
      hasVideoAvailable: true,
      relations: const [
        AnimeRelationItem(
          id: 142853,
          title: 'Tokyo Revengers: Christmas Showdown',
          relationType: 'SEQUEL',
          format: 'TV',
          status: 'FINISHED',
        ),
      ],
      episodes: List.generate(
        12,
        (index) => EpisodeItem(
          id: 'tokyo-revengers-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} Sub Indo',
          releaseDate: '2021-04-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'tokyo-revengers',
            animeTitle: 'Tokyo Revengers',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'tokyo-revengers-s2': AnimeDetail(
      id: 'tokyo-revengers-s2',
      title: 'Tokyo Revengers: Christmas Showdown',
      japaneseTitle: '東京リベンジャーズ 聖夜決戦編',
      rating: 8.0,
      releaseYear: 2023,
      genres: const ['Action', 'Drama', 'Delinquents', 'Supernatural'],
      synopsis: 'Konflik takdir antara Takemichi, geng Black Dragon, dan Shiba bersaudara di malam Natal.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/45697/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/45697/large.jpg',
      status: 'Tamat',
      studio: 'LIDENFILMS',
      totalEpisodes: 13,
      aniListId: 142853,
      hasVideoAvailable: true,
      relations: const [
        AnimeRelationItem(
          id: 120120,
          title: 'Tokyo Revengers',
          relationType: 'PREQUEL',
          format: 'TV',
          status: 'FINISHED',
        ),
        AnimeRelationItem(
          id: 163539,
          title: 'Tokyo Revengers: Tenjiku Arc',
          relationType: 'SEQUEL',
          format: 'TV',
          status: 'FINISHED',
        ),
      ],
      episodes: List.generate(
        13,
        (index) => EpisodeItem(
          id: 'tokyo-revengers-s2-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Perang Suci Natal',
          releaseDate: '2023-01-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'tokyo-revengers-s2',
            animeTitle: 'Tokyo Revengers Season 2',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'tokyo-revengers-s4': const AnimeDetail(
      id: '178945',
      title: 'Tokyo Revengers: Santen Sensou-hen',
      japaneseTitle: '東京リベンジャーズ 三天戦争編',
      rating: 8.2,
      releaseYear: 2026,
      genres: ['Action', 'Drama', 'Delinquents'],
      synopsis: 'Pertarungan tiga dewa besar Tokyo dalam babak Three Deities.',
      posterUrl: '',
      backdropUrl: '',
      status: 'Ongoing',
      studio: 'LIDENFILMS',
      totalEpisodes: 1,
      episodes: [],
      aniListId: 178945,
      hasVideoAvailable: false,
      relations: [
        AnimeRelationItem(
          id: 163539,
          title: 'Tokyo Revengers: Tenjiku Arc',
          relationType: 'PREQUEL',
          format: 'TV',
          status: 'FINISHED',
        ),
      ],
    ),
    'yosuga-no-sora': const AnimeDetail(
      id: '8861',
      title: 'Yosuga no Sora',
      japaneseTitle: 'ヨスガノソラ',
      rating: 7.2,
      releaseYear: 2010,
      genres: ['Romance', 'Drama', 'Ecchi'],
      synopsis: 'Haruka dan Sora Kasugano pindah ke desa terpencil tempat kenangan masa kecil mereka.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx8861-DZKseZpdtBwp.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx8861-DZKseZpdtBwp.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx8861-DZKseZpdtBwp.jpg',
      status: 'Tamat',
      studio: 'feel.',
      totalEpisodes: 12,
      episodes: [],
      aniListId: 8861,
      hasVideoAvailable: false,
    ),
    'unreleased-anime': const AnimeDetail(
      id: '999998',
      title: 'Unreleased Anime Project',
      japaneseTitle: '未公開プロジェクト',
      rating: 7.5,
      releaseYear: 2027,
      genres: ['Action', 'Mystery'],
      synopsis: 'Anime ini belum dirilis dan belum memiliki episode.',
      posterUrl: '',
      backdropUrl: '',
      status: 'Akan Tayang',
      studio: 'Animation Studio',
      totalEpisodes: 0,
      episodes: [],
      aniListId: 999998,
      hasVideoAvailable: false,
    ),
    'one-punch-man': AnimeDetail(
      id: 'one-punch-man',
      title: 'One Punch Man',
      japaneseTitle: 'ワンパンマン',
      rating: 8.7,
      releaseYear: 2015,
      genres: const ['Action', 'Comedy', 'Sci-Fi', 'Supernatural'],
      synopsis: 'Saitama adalah seorang pahlawan yang bisa mengalahkan musuh apa pun hanya dengan satu pukulan, namun merasa bosan karena tak pernah menemukan lawan yang seimbang.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21087-sZwHsannLyql.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21087-sX47UotflVms.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21087-sX47UotflVms.jpg',
      status: 'Tamat',
      studio: 'Madhouse',
      totalEpisodes: 12,
      aniListId: 21087,
      hasVideoAvailable: true,
      relations: const [
        AnimeRelationItem(
          id: 102194,
          title: 'One Punch Man Season 2',
          relationType: 'SEQUEL',
          format: 'TV',
          status: 'FINISHED',
        ),
      ],
      episodes: [
        'Pria Terkuat',
        'Siklon Soliter',
        'Ilmuwan Obsesif',
        'Ninja Modern',
        'Mentor Utama',
        'Kota Menakutkan',
        'Murid Terbaik',
        'Raja Laut Dalam',
        'Keadilan yang Pantang Menyerah',
        'Bahaya yang Tak Tertandingi',
        'Dominator Alam Semesta',
        'Pahlawan Terkuat',
      ].asMap().entries.map((entry) {
        final ep = entry.key + 1;
        return EpisodeItem(
          id: 'one-punch-man-eps-$ep',
          episodeNumber: ep,
          title: 'Episode $ep - ${entry.value}',
          releaseDate: '2015-10-${ep.toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: '21087',
            animeTitle: 'One Punch Man',
            server: 'Server 1 (Fast HD)',
            episodeNumber: ep,
          ),
        );
      }).toList(),
    ),
    'one-punch-man-s2': AnimeDetail(
      id: 'one-punch-man-s2',
      title: 'One Punch Man Season 2',
      japaneseTitle: 'ワンパンマン 2',
      rating: 7.5,
      releaseYear: 2019,
      genres: const ['Action', 'Comedy', 'Sci-Fi', 'Supernatural'],
      synopsis: 'Asosiasi Monster mulai bergerak sementara Garou melancarkan perburuan terhadap para pahlawan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx102194-NlPmtwZ7lGbe.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/102194-e0k1NfJ5Q1K7.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/102194-e0k1NfJ5Q1K7.jpg',
      status: 'Tamat',
      studio: 'J.C.Staff',
      totalEpisodes: 12,
      aniListId: 102194,
      hasVideoAvailable: false,
      relations: const [
        AnimeRelationItem(
          id: 21087,
          title: 'One Punch Man',
          relationType: 'PREQUEL',
          format: 'TV',
          status: 'FINISHED',
        ),
      ],
      episodes: [
        'Kembalinya Sang Pahlawan',
        'Monster Manusia',
        'Perburuan Dimulai',
        'Kelelawar Logam',
        'Turnamen Seni Bela Diri',
        'Pemberontakan Monster',
        'Pahlawan Kelas S',
        'Perlawanan Orang Kuat',
        'Kekhawatiran Orang Kuat',
        'Pengepungan Keadilan',
        'Kebanggaan Masing-Masing',
        'Pembersihan Murid',
      ].asMap().entries.map((entry) {
        final ep = entry.key + 1;
        return EpisodeItem(
          id: 'one-punch-man-s2-eps-$ep',
          episodeNumber: ep,
          title: 'Episode $ep - ${entry.value}',
          releaseDate: '2019-04-${ep.toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: '102194',
            animeTitle: 'One Punch Man Season 2',
            server: 'Server 1 (Fast HD)',
            episodeNumber: ep,
          ),
        );
      }).toList(),
    ),
  };
}
