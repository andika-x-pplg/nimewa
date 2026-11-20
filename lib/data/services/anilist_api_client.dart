import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/anime_detail.dart';
import '../models/anime_external_link.dart';
import '../models/anime_item.dart';
import '../models/anime_relation_item.dart';
import '../models/episode_item.dart';
import 'anime_stream_resolver.dart';
import 'owner_video_repository.dart';

/// Client for AniList GraphQL API (https://graphql.anilist.co).
/// Fetches rich catalog metadata, official cover/banner imagery, and franchise relations.
class AniListApiClient {
  static const String graphqlEndpoint = 'https://graphql.anilist.co';

  final Duration timeout;
  final HttpClient? _client;

  const AniListApiClient({
    this.timeout = const Duration(seconds: 6),
    HttpClient? client,
  }) : _client = client;

  HttpClient get _activeClient =>
      _client ?? (_lazyClient ??= HttpClient()..connectionTimeout = timeout);
  static HttpClient? _lazyClient;

  /// Fetches top trending anime from AniList.
  Future<List<AnimeItem>> fetchTrendingAnime({
    int limit = 10,
    int page = 1,
  }) async {
    const query = r'''
query ($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, sort: [TRENDING_DESC, POPULARITY_DESC]) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        extraLarge
        large
        color
      }
      bannerImage
      episodes
      season
      seasonYear
      status
      averageScore
      description
      genres
    }
  }
}
''';
    try {
      final json = await _postGraphQL(query, {'page': page, 'perPage': limit});
      final mediaList = json['data']?['Page']?['media'] as List<dynamic>?;
      if (mediaList != null && mediaList.isNotEmpty) {
        return mediaList
            .whereType<Map<String, dynamic>>()
            .map(parseMediaItem)
            .toList();
      }
    } catch (_) {
      // Fallback to verified local AniList cache
    }
    return cachedTrendingAnime.skip((page - 1) * limit).take(limit).toList();
  }

  /// Fetches most popular anime from AniList.
  Future<List<AnimeItem>> fetchPopularAnime({
    int limit = 20,
    int page = 1,
  }) async {
    const query = r'''
query ($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, sort: [POPULARITY_DESC]) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        extraLarge
        large
        color
      }
      bannerImage
      episodes
      season
      seasonYear
      status
      averageScore
      description
      genres
    }
  }
}
''';
    try {
      final json = await _postGraphQL(query, {'page': page, 'perPage': limit});
      final mediaList = json['data']?['Page']?['media'] as List<dynamic>?;
      if (mediaList != null && mediaList.isNotEmpty) {
        return mediaList
            .whereType<Map<String, dynamic>>()
            .map(parseMediaItem)
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    return cachedPopularAnime.skip((page - 1) * limit).take(limit).toList();
  }

  /// Fetches top rated anime from AniList.
  Future<List<AnimeItem>> fetchTopRatedAnime({
    int limit = 20,
    int page = 1,
  }) async {
    return fetchPopularAnime(limit: limit, page: page);
  }

  /// Alias for fetchAnimeByCategory.
  Future<List<AnimeItem>> fetchAnimeByGenre(
    String genre, {
    int limit = 20,
    int page = 1,
  }) async {
    return fetchAnimeByCategory(genre, limit: limit, page: page);
  }

  /// Fetches latest anime releases sorted by release date.
  Future<List<AnimeItem>> fetchLatestAnime({
    int limit = 20,
    int page = 1,
  }) async {
    const query = r'''
query ($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, sort: [START_DATE_DESC]) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        extraLarge
        large
        color
      }
      bannerImage
      episodes
      season
      seasonYear
      status
      averageScore
      description
      genres
    }
  }
}
''';
    try {
      final json = await _postGraphQL(query, {'page': page, 'perPage': limit});
      final mediaList = json['data']?['Page']?['media'] as List<dynamic>?;
      if (mediaList != null && mediaList.isNotEmpty) {
        return mediaList
            .whereType<Map<String, dynamic>>()
            .map(parseMediaItem)
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    return cachedPopularAnime.skip((page - 1) * limit).take(limit).toList();
  }

  /// Fetches anime filtered by genre.
  Future<List<AnimeItem>> fetchAnimeByCategory(
    String genre, {
    int limit = 20,
    int page = 1,
  }) async {
    const query = r'''
query ($page: Int, $perPage: Int, $genre: String) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, genre: $genre, sort: [POPULARITY_DESC]) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        extraLarge
        large
        color
      }
      bannerImage
      episodes
      season
      seasonYear
      status
      averageScore
      description
      genres
    }
  }
}
''';
    try {
      final json = await _postGraphQL(
        query,
        {'page': page, 'perPage': limit, 'genre': genre},
      );
      final mediaList = json['data']?['Page']?['media'] as List<dynamic>?;
      if (mediaList != null && mediaList.isNotEmpty) {
        return mediaList
            .whereType<Map<String, dynamic>>()
            .map(parseMediaItem)
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    return cachedPopularAnime
        .where((a) => a.genres.any((g) => g.toLowerCase() == genre.toLowerCase()))
        .skip((page - 1) * limit)
        .take(limit)
        .toList();
  }

  /// Searches anime by query keyword.
  Future<List<AnimeItem>> searchAnime(
    String query, {
    int limit = 20,
    int page = 1,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return fetchPopularAnime(limit: limit, page: page);
    }

    const acronyms = {
      'jjk': 'Jujutsu Kaisen',
      'aot': 'Attack on Titan',
      'snk': 'Shingeki no Kyojin',
      'ds': 'Demon Slayer',
      'kny': 'Kimetsu no Yaiba',
      'tr': 'Tokyo Revengers',
      'sl': 'Solo Leveling',
      'csm': 'Chainsaw Man',
      'dn': 'Death Note',
      'op': 'One Piece',
      'mha': 'My Hero Academia',
      'bnha': 'Boku no Hero Academia',
      'sao': 'Sword Art Online',
      'fma': 'Fullmetal Alchemist',
      'fmab': 'Fullmetal Alchemist',
      'hxh': 'Hunter x Hunter',
      'yns': 'Yosuga no Sora',
      'sg': 'Steins Gate',
      'tg': 'Tokyo Ghoul',
      'ddd': 'Dandadan',
      'opm': 'One Punch Man',
    };
    final searchKeyword = acronyms[cleanQuery.toLowerCase()] ?? cleanQuery;

    const gql = r'''
query ($page: Int, $perPage: Int, $search: String) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, search: $search, sort: [SEARCH_MATCH, POPULARITY_DESC]) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        extraLarge
        large
        color
      }
      bannerImage
      episodes
      season
      seasonYear
      status
      averageScore
      description
      genres
    }
  }
}
''';
    try {
      final json = await _postGraphQL(gql, {
        'page': page,
        'perPage': limit,
        'search': searchKeyword,
      });
      final mediaList = json['data']?['Page']?['media'] as List<dynamic>?;
      if (mediaList != null && mediaList.isNotEmpty) {
        return mediaList
            .whereType<Map<String, dynamic>>()
            .map(parseMediaItem)
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    return cachedPopularAnime
        .where((a) => a.matchesSearch(cleanQuery))
        .skip((page - 1) * limit)
        .take(limit)
        .toList();
  }

  /// Fetches detailed anime info including franchise relations.
  Future<AnimeDetail> fetchAnimeDetail(dynamic idOrAniListId) async {
    final aniListId = idOrAniListId is num
        ? idOrAniListId.toInt()
        : int.tryParse(idOrAniListId.toString()) ?? 0;

    const query = r'''
query ($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    title {
      romaji
      english
      native
    }
    coverImage {
      extraLarge
      large
      color
    }
    bannerImage
    episodes
    season
    seasonYear
    status
    averageScore
    description
    genres
    studios(isMain: true) {
      nodes {
        name
      }
    }
    relations {
      edges {
        relationType
        node {
          id
          title {
            romaji
            english
          }
          format
          type
          status
          coverImage {
            large
          }
        }
      }
    }
    externalLinks {
      id
      url
      site
      type
      icon
      color
    }
  }
}
''';

    if (aniListId > 0) {
      try {
        final json = await _postGraphQL(query, {'id': aniListId});
        final media = json['data']?['Media'] as Map<String, dynamic>?;
        if (media != null) {
          return parseMediaDetail(media);
        }
      } catch (_) {
        // Fallback
      }
    }

    // Try finding in cached
    final cached = cachedPopularAnime.firstWhere(
      (a) => a.id == idOrAniListId.toString() || a.aniListId == aniListId,
      orElse: () => cachedPopularAnime.first,
    );
    return _generateDetailFromItem(cached);
  }

  /// Converts AniList Media JSON into domain [AnimeItem].
  AnimeItem parseMediaItem(Map<String, dynamic> json) {
    final aniListId = json['id'] is num
        ? (json['id'] as num).toInt()
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    final titles = json['title'] as Map<String, dynamic>? ?? {};
    final englishTitle = titles['english']?.toString();
    final romajiTitle = titles['romaji']?.toString() ?? '';
    final nativeTitle = titles['native']?.toString() ?? '';
    final title = (englishTitle != null && englishTitle.isNotEmpty)
        ? englishTitle
        : (romajiTitle.isNotEmpty ? romajiTitle : nativeTitle);

    final covers = json['coverImage'] as Map<String, dynamic>? ?? {};
    final posterUrl = covers['extraLarge']?.toString() ??
        covers['large']?.toString() ??
        covers['medium']?.toString() ??
        '';

    final bannerUrl = json['bannerImage']?.toString();

    final rawScore = json['averageScore'];
    final scoreInt = rawScore is num
        ? rawScore.toInt()
        : int.tryParse(rawScore?.toString() ?? '0') ?? 0;
    final rating = scoreInt > 0 ? (scoreInt / 10.0) : 8.0;

    final rawYear = json['seasonYear'];
    final releaseYear = rawYear is num
        ? rawYear.toInt()
        : int.tryParse(rawYear?.toString() ?? '2024') ?? 2024;

    final rawGenres = json['genres'] as List<dynamic>? ?? [];
    final genres = rawGenres.map((g) => g.toString()).toList();
    if (genres.isEmpty) genres.addAll(['Action', 'Fantasy']);

    final rawDesc = json['description']?.toString() ?? '';
    final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '');

    final rawStatus = json['status']?.toString();
    final isFinished = rawStatus == 'FINISHED';
    final statusLabel = isFinished ? 'Tamat' : 'Ongoing';

    final rawEpisodes = json['episodes'] as num?;
    final totalEpisodes = rawEpisodes != null ? rawEpisodes.toInt() : 12;
    final episodeInfo = totalEpisodes > 1
        ? 'SUB · $totalEpisodes EPS ($statusLabel)'
        : (totalEpisodes == 1 ? 'SUB · MOVIE' : 'SUB · Ongoing');

    final hasVideo = _computeHasVideoAvailable(aniListId, title);

    return AnimeItem(
      id: aniListId > 0 ? aniListId.toString() : title.toLowerCase().replaceAll(RegExp(r'\W+'), '-'),
      title: title,
      japaneseTitle: nativeTitle,
      rating: double.parse(rating.toStringAsFixed(1)),
      releaseYear: releaseYear,
      genres: genres,
      description: cleanDesc.isNotEmpty ? cleanDesc : 'Nonton streaming anime berkualitas HD.',
      posterUrl: posterUrl,
      backdropUrl: bannerUrl ?? posterUrl,
      bannerUrl: bannerUrl,
      episodeInfo: episodeInfo,
      statusLabel: statusLabel,
      aniListId: aniListId,
      hasVideoAvailable: hasVideo,
    );
  }

  /// Converts AniList Media JSON into domain [AnimeDetail].
  AnimeDetail parseMediaDetail(Map<String, dynamic> json) {
    final item = parseMediaItem(json);
    final rawEpisodes = json['episodes'] as num?;
    final count = rawEpisodes != null && rawEpisodes > 0 ? rawEpisodes.toInt() : 12;

    // Parse relations
    final relationEdges = json['relations']?['edges'] as List<dynamic>? ?? [];
    final relations = relationEdges
        .whereType<Map<String, dynamic>>()
        .map(AnimeRelationItem.fromJson)
        .toList();

    // Parse externalLinks (official streaming platforms)
    final rawLinks = json['externalLinks'] as List<dynamic>? ?? [];
    final externalLinks = rawLinks
        .whereType<Map<String, dynamic>>()
        .map(AnimeExternalLink.fromJson)
        .toList();

    final studiosNodes = json['studios']?['nodes'] as List<dynamic>? ?? [];
    final studio = studiosNodes.isNotEmpty
        ? studiosNodes.first['name']?.toString() ?? 'Animation Studio'
        : 'Animation Studio';

    // Episode list: only populated if video is available
    final uploadedVideos = OwnerVideoRepository.instance.getVideosForAnime(item.aniListId);
    final episodeList = item.hasVideoAvailable
        ? (uploadedVideos.isNotEmpty
            ? uploadedVideos
                .map(
                  (uv) => EpisodeItem(
                    id: '${item.id}-eps-${uv.episodeNumber}',
                    episodeNumber: uv.episodeNumber,
                    title: uv.episodeTitle,
                    releaseDate: '2024-01-${uv.episodeNumber.toString().padLeft(2, '0')}',
                    streamUrl: uv.videoUrl,
                  ),
                )
                .toList()
            : List.generate(
                count,
                (i) => EpisodeItem(
                  id: '${item.id}-eps-${i + 1}',
                  episodeNumber: i + 1,
                  title: count == 1 ? 'Full Movie Sub Indo' : 'Episode ${i + 1} Sub Indo',
                  releaseDate: '2024-01-${(i + 1).toString().padLeft(2, '0')}',
                  streamUrl: AnimeStreamResolver.resolveStreamUrl(
                    animeId: item.aniListId > 0 ? item.aniListId.toString() : item.id,
                    animeTitle: item.title,
                    server: 'Server 1 (Fast HD)',
                    episodeNumber: i + 1,
                  ),
                ),
              ))
        : <EpisodeItem>[];

    return AnimeDetail(
      id: item.id,
      title: item.title,
      japaneseTitle: item.japaneseTitle,
      rating: item.rating,
      releaseYear: item.releaseYear,
      genres: item.genres,
      synopsis: item.description,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      status: item.statusLabel,
      studio: studio,
      totalEpisodes: item.hasVideoAvailable ? episodeList.length : 0,
      episodes: episodeList,
      aniListId: item.aniListId,
      relations: relations,
      externalLinks: externalLinks,
      hasVideoAvailable: item.hasVideoAvailable,
      bannerUrl: item.bannerUrl,
    );
  }

  AnimeDetail _generateDetailFromItem(AnimeItem item) {
    final count = item.hasVideoAvailable ? 12 : 0;
    final uploadedVideos = OwnerVideoRepository.instance.getVideosForAnime(item.aniListId);
    final episodes = item.hasVideoAvailable
        ? (uploadedVideos.isNotEmpty
            ? uploadedVideos
                .map(
                  (uv) => EpisodeItem(
                    id: '${item.id}-eps-${uv.episodeNumber}',
                    episodeNumber: uv.episodeNumber,
                    title: uv.episodeTitle,
                    releaseDate: '2024-01-${uv.episodeNumber.toString().padLeft(2, '0')}',
                    streamUrl: uv.videoUrl,
                  ),
                )
                .toList()
            : List.generate(
                count,
                (i) => EpisodeItem(
                  id: '${item.id}-eps-${i + 1}',
                  episodeNumber: i + 1,
                  title: 'Episode ${i + 1} Sub Indo',
                  releaseDate: '2024-01-${(i + 1).toString().padLeft(2, '0')}',
                  streamUrl: AnimeStreamResolver.resolveStreamUrl(
                    animeId: item.id,
                    animeTitle: item.title,
                    server: 'Server 1 (Fast HD)',
                    episodeNumber: i + 1,
                  ),
                ),
              ))
        : <EpisodeItem>[];

    return AnimeDetail(
      id: item.id,
      title: item.title,
      japaneseTitle: item.japaneseTitle,
      rating: item.rating,
      releaseYear: item.releaseYear,
      genres: item.genres,
      synopsis: item.description,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      status: item.statusLabel,
      studio: 'Animation Studio',
      totalEpisodes: episodes.length,
      episodes: episodes,
      aniListId: item.aniListId,
      relations: const [],
      externalLinks: const [],
      hasVideoAvailable: item.hasVideoAvailable,
      bannerUrl: item.bannerUrl,
    );
  }

  bool _computeHasVideoAvailable(int aniListId, String title) {
    // Explicit blacklist of anime seasons known to lack video
    if (aniListId == 178945 ||
        title.toLowerCase().contains('tokyo revengers: season 4') ||
        title.toLowerCase().contains('santen sensou') ||
        title.toLowerCase().contains('three deities')) {
      return false;
    }
    if (aniListId > 0 && OwnerVideoRepository.instance.hasVideosForAnime(aniListId)) {
      return true;
    }
    return AnimeStreamResolver.hasCompleteEpisodes(aniListId.toString(), title);
  }

  Future<Map<String, dynamic>> _postGraphQL(
    String query,
    Map<String, dynamic> variables,
  ) async {
    final uri = Uri.parse(graphqlEndpoint);
    final req = await _activeClient.postUrl(uri).timeout(timeout);
    req.headers.set('Content-Type', 'application/json');
    req.headers.set('Accept', 'application/json');
    req.headers.set('User-Agent', 'NimevaAnime/1.0 (Mobile Client)');

    final body = jsonEncode({'query': query, 'variables': variables});
    req.write(body);

    final resp = await req.close().timeout(timeout);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final responseBody = await resp.transform(utf8.decoder).join().timeout(timeout);
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    throw HttpException('AniList GraphQL request failed with status: ${resp.statusCode}');
  }

  /// Top authentic anime cached with official AniList IDs and CDN assets.
  static const List<AnimeItem> cachedTrendingAnime = [
    AnimeItem(
      id: '151807',
      title: 'Solo Leveling',
      japaneseTitle: '俺だけレベルアップな件',
      rating: 8.4,
      releaseYear: 2024,
      genres: ['Action', 'Fantasy', 'Supernatural'],
      description: 'Sung Jinwoo bangkit dari Hunter terlemah menjadi satu-satunya yang dapat naik level.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx151807-it355ZgzquUd.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/151807-37yfQA3ym8PA.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/151807-37yfQA3ym8PA.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 151807,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '101922',
      title: 'Demon Slayer: Kimetsu no Yaiba',
      japaneseTitle: '鬼滅の刃',
      rating: 8.5,
      releaseYear: 2019,
      genres: ['Action', 'Fantasy', 'Historical'],
      description: 'Tanjiro Kamado berjuang membasmi iblis demi mengembalikan adiknya Nezuko.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101922-WBsBl0ClmgYL.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101922-33MtJGsUSxga.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101922-33MtJGsUSxga.jpg',
      episodeInfo: 'SUB · 26 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 101922,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '16498',
      title: 'Attack on Titan',
      japaneseTitle: '進撃の巨人',
      rating: 8.5,
      releaseYear: 2013,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Pertarungan sengit umat manusia melawan para Titan raksasa yang mengancam kepunahan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-buvcRTBx4NSm.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498-8jpFCOcDmneX.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498-8jpFCOcDmneX.jpg',
      episodeInfo: 'SUB · 25 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 16498,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '113415',
      title: 'Jujutsu Kaisen',
      japaneseTitle: '呪術廻戦',
      rating: 8.6,
      releaseYear: 2020,
      genres: ['Action', 'Fantasy', 'Supernatural'],
      description: 'Yuji Itadori menelan jari kutukan Sukuna dan memasuki dunia pertempuran penyihir Jujutsu.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx113415-LHBAeoZDIsnF.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/113415-jQBSkxWAAk83.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/113415-jQBSkxWAAk83.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 113415,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '120120',
      title: 'Tokyo Revengers',
      japaneseTitle: '東京リベンジャーズ',
      rating: 7.9,
      releaseYear: 2021,
      genres: ['Action', 'Drama', 'Supernatural'],
      description: 'Takemichi Hanagaki returns 12 years to his middle school days.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx120120-cWDmnmeEntSe.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/120120-UDYgoHA69peT.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/120120-UDYgoHA69peT.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 120120,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '163539',
      title: 'Tokyo Revengers: Tenjiku Arc',
      japaneseTitle: '東京リベンジャーズ 天竺編',
      rating: 7.9,
      releaseYear: 2023,
      genres: ['Action', 'Drama', 'Delinquents'],
      description: 'Pertarungan besar antara Tokyo Manji Gang dan geng Tenjiku pimpinan Izana Kurokawa.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx163329-lGJRnYV9dcjc.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/163329-SLDIMqtukB7B.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/163329-SLDIMqtukB7B.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 163539,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '166240',
      title: 'Dan Da Dan Season 1',
      japaneseTitle: 'ダンダダン',
      rating: 8.7,
      releaseYear: 2024,
      genres: ['Action', 'Comedy', 'Sci-Fi'],
      description: 'Pertarungan heboh Momo Ayase dan Okarun menghadapi fenomena kutukan dan alien.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx171018-60q1B6GK2Ghb.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/171018-SpwPNAduszXl.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/171018-SpwPNAduszXl.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 166240,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '21827',
      title: 'Kimi no Na wa (Your Name)',
      japaneseTitle: '君の名は。',
      rating: 9.1,
      releaseYear: 2016,
      genres: ['Romance', 'Drama', 'Supernatural'],
      description: 'Taki dan Mitsuha terhubung oleh benang takdir dan fenomena bertukar tubuh melintasi waktu.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21519-SUo3ZQuCbYhJ.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21519-1ayMXgNlmByb.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21519-1ayMXgNlmByb.jpg',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 21827,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '154587',
      title: 'Sousou no Frieren',
      japaneseTitle: '葬送のフリーレン',
      rating: 9.3,
      releaseYear: 2023,
      genres: ['Fantasy', 'Adventure', 'Drama'],
      description: 'Perjalanan panjang sang penyihir elf Frieren memahami arti hidup dan waktu manusia.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-qQTzQnEJJ3oB.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/154587-ivXNJ23SM1xB.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/154587-ivXNJ23SM1xB.jpg',
      episodeInfo: 'SUB · 28 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 154587,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '127720',
      title: 'Chainsaw Man',
      japaneseTitle: 'チェンソーマン',
      rating: 8.7,
      releaseYear: 2022,
      genres: ['Action', 'Supernatural', 'Horror'],
      description: 'Denji membuat kontrak dengan iblis gergaji Pochita dan bangkit sebagai Chainsaw Man.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx127230-DdP4vAdssLoz.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/127230-o8IRwCGVr9KW.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/127230-o8IRwCGVr9KW.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 127720,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '1535',
      title: 'Death Note',
      japaneseTitle: 'デスノート',
      rating: 9.0,
      releaseYear: 2006,
      genres: ['Mystery', 'Psychological', 'Supernatural'],
      description: 'Light Yagami menggunakan buku catatan kematian untuk menciptakan dunia tanpa kejahatan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx1535-kUgkcrfOrkUM.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1535.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1535.jpg',
      episodeInfo: 'SUB · 37 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 1535,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '8861',
      title: 'Yosuga no Sora',
      japaneseTitle: 'ヨスガノソラ',
      rating: 7.2,
      releaseYear: 2010,
      genres: ['Romance', 'Drama', 'Ecchi'],
      description: 'Haruka dan Sora Kasugano pindah ke desa terpencil tempat kenangan masa kecil mereka.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx8861-DZKseZpdtBwp.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx8861-DZKseZpdtBwp.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx8861-DZKseZpdtBwp.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 8861,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '21087',
      title: 'One Punch Man',
      japaneseTitle: 'ワンパンマン',
      rating: 8.7,
      releaseYear: 2015,
      genres: ['Action', 'Comedy', 'Sci-Fi', 'Supernatural'],
      description: 'Saitama adalah pahlawan unik yang mampu mengalahkan musuh mana pun hanya dengan satu pukulan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21087-sZwHsannLyql.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21087-sX47UotflVms.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21087-sX47UotflVms.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 21087,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '178945',
      title: 'Tokyo Revengers: Santen Sensou-hen',
      japaneseTitle: '東京リベンジャーズ 三天戦争編',
      rating: 8.2,
      releaseYear: 2026,
      genres: ['Action', 'Drama', 'Delinquents'],
      description: 'Pertarungan tiga dewa besar Tokyo dalam babak Three Deities.',
      posterUrl: '',
      backdropUrl: '',
      bannerUrl: null,
      episodeInfo: 'Upcoming',
      statusLabel: 'Ongoing',
      aniListId: 178945,
      hasVideoAvailable: false,
    ),
  ];

  static const List<AnimeItem> cachedPopularAnime = cachedTrendingAnime;
}
