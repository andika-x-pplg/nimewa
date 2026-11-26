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

  static const Map<String, String> _categoryTagMap = {
    'isekai': 'Isekai',
    'demons': 'Demons',
    'harem': 'Male Harem',
    'game': 'Video Games',
    'historical': 'Historical',
    'josei': 'Josei',
    'magic': 'Magic',
    'martial arts': 'Martial Arts',
    'military': 'Military',
    'parody': 'Parody',
    'police': 'Police',
    'samurai': 'Samurai',
    'school': 'School',
    'shoujo': 'Shoujo',
    'shoujo ai': 'Yuri',
    'super power': 'Super Power',
    'vampire': 'Vampire',
  };

  /// Fetches anime filtered by genre, format (Movie), or AniList tag.
  Future<List<AnimeItem>> fetchAnimeByCategory(
    String genre, {
    int limit = 20,
    int page = 1,
  }) async {
    final normalized = genre.trim().toLowerCase();
    final isMovie = normalized == 'movie';
    final mappedTag = _categoryTagMap[normalized];

    final String query;
    final Map<String, dynamic> variables;

    if (isMovie) {
      query = r'''
query ($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, format: MOVIE, sort: [POPULARITY_DESC]) {
      id
      title { romaji english native }
      coverImage { extraLarge large color }
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
      variables = {'page': page, 'perPage': limit};
    } else if (mappedTag != null) {
      query = r'''
query ($page: Int, $perPage: Int, $tag: String) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, tag: $tag, sort: [POPULARITY_DESC]) {
      id
      title { romaji english native }
      coverImage { extraLarge large color }
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
      variables = {'page': page, 'perPage': limit, 'tag': mappedTag};
    } else {
      query = r'''
query ($page: Int, $perPage: Int, $genre: String) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, genre: $genre, sort: [POPULARITY_DESC]) {
      id
      title { romaji english native }
      coverImage { extraLarge large color }
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
      variables = {'page': page, 'perPage': limit, 'genre': genre};
    }

    try {
      final json = await _postGraphQL(query, variables);
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
    if (hasVideo && aniListId > 0) {
      OwnerVideoRepository.instance.ensureVideosForAnime(
        aniListId: aniListId,
        seasonNumber: 1,
        count: totalEpisodes > 0 ? totalEpisodes : 12,
        seriesTitle: title,
      );
    }

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
    var uploadedVideos = OwnerVideoRepository.instance.getVideosForAnime(item.aniListId);
    if (uploadedVideos.isEmpty && item.hasVideoAvailable && item.aniListId > 0) {
      OwnerVideoRepository.instance.ensureVideosForAnime(
        aniListId: item.aniListId,
        seasonNumber: 1,
        count: count,
        seriesTitle: item.title,
      );
      uploadedVideos = OwnerVideoRepository.instance.getVideosForAnime(item.aniListId);
    }
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
                    title: AnimeStreamResolver.getEpisodeTitle(
                      item.aniListId > 0 ? item.aniListId.toString() : item.id,
                      item.title,
                      i + 1,
                      isMovie: count == 1,
                    ),
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
                  title: AnimeStreamResolver.getEpisodeTitle(
                    item.id,
                    item.title,
                    i + 1,
                  ),
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
    if (aniListId <= 0 && title.isEmpty) return false;
    if (aniListId == 999998 || title.toLowerCase().contains('unreleased')) {
      return false;
    }
    final idStr = aniListId > 0 ? aniListId.toString() : title;
    return AnimeStreamResolver.hasCompleteEpisodes(idStr, title);
  }

  /// Executes a raw GraphQL query against the AniList endpoint.
  Future<Map<String, dynamic>> executeGraphQL(
    String query,
    Map<String, dynamic> variables,
  ) =>
      _postGraphQL(query, variables);

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
      id: '153152',
      title: 'Boku no Kokoro no Yabai Yatsu',
      japaneseTitle: '僕の心のヤバイやつ',
      rating: 8.5,
      releaseYear: 2023,
      genres: ['Comedy', 'Romance', 'School'],
      description: 'Kyotaro Ichikawa yang pendiam dan muram perlahan berubah setelah mengenal Anna Yamada yang ceria.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx153152-Xnwmx7wuoIWV.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/153152-rBoe4ue4EjzI.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/153152-rBoe4ue4EjzI.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 153152,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '166216',
      title: 'Boku no Kokoro no Yabai Yatsu 2nd Season',
      japaneseTitle: '僕の心のヤバイやつ 第2期',
      rating: 8.8,
      releaseYear: 2024,
      genres: ['Comedy', 'Romance', 'School'],
      description: 'Kelanjutan kisah kedekatan Ichikawa dan Yamada yang semakin manis di tahun ajaran baru.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx166216-vCMkF4e3x5FB.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/166216-mmAL8hAH8Ttc.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/166216-mmAL8hAH8Ttc.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 166216,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '127911',
      title: 'Kawaii dake ja Nai Shikimori-san',
      japaneseTitle: '可愛いだけじゃない式守さん',
      rating: 7.4,
      releaseYear: 2022,
      genres: ['Comedy', 'Romance', 'School'],
      description: 'Shikimori yang manis bisa berubah menjadi sangat keren saat melindungi pacarnya, Izumi yang selalu sial.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx127911-qfJDzUt0qCna.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/127911-YRSP7vuUy801.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/127911-YRSP7vuUy801.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 127911,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '132405',
      title: 'Sono Bisque Doll wa Koi wo Suru',
      japaneseTitle: 'その着せ替え人形は恋をする',
      rating: 8.3,
      releaseYear: 2022,
      genres: ['Romance', 'School'],
      description: 'Wakana Gojo si pembuat boneka hina membantu Marin Kitagawa mewujudkan impian cosplay-nya.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx132405-qP7FQYGmNI3d.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/132405-LnPQaqaksEpN.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/132405-LnPQaqaksEpN.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 132405,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '154768',
      title: 'Sono Bisque Doll wa Koi wo Suru Season 2',
      japaneseTitle: 'その着せ替え人形は恋をする 第2期',
      rating: 8.4,
      releaseYear: 2025,
      genres: ['Romance', 'School'],
      description: 'Kelanjutan kisah Gojo dan Marin dengan proyek cosplay baru dan perasaan yang semakin berkembang.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154768-DHHvNd4MjV1p.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/154768-EuZd63IcqsVq.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/154768-EuZd63IcqsVq.jpg',
      episodeInfo: 'SUB · 12 EPS',
      statusLabel: 'Tamat',
      aniListId: 154768,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '143338',
      title: 'Otonari no Tenshi-sama ni Itsunomanika Dame Ningen ni Sareteita Ken',
      japaneseTitle: 'お隣の天使様にいつの間にか駄目人間にされていた件',
      rating: 7.9,
      releaseYear: 2023,
      genres: ['Romance', 'School'],
      description: 'Amane dan tetangganya yang cantik, Mahiru Shiina, perlahan menjadi dekat lewat makan malam bersama.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx143338-zhyDVYgEzsm5.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/143338-d0AqJzRUQCgk.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/143338-d0AqJzRUQCgk.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 143338,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '163623',
      title: 'Giji Harem',
      japaneseTitle: '疑似ハーレム',
      rating: 7.8,
      releaseYear: 2024,
      genres: ['Comedy', 'Romance', 'School'],
      description: 'Rin Nanakura memerankan berbagai karakter demi menghibur seniornya di klub drama, Eiji Kitahama.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx163623-pzR6vIHoJh0b.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/163623-A5g41LWbH3WT.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/163623-A5g41LWbH3WT.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 163623,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '170942',
      title: 'Ao no Hako (Blue Box)',
      japaneseTitle: 'アオのハコ',
      rating: 8.3,
      releaseYear: 2024,
      genres: ['Romance', 'Sports', 'School'],
      description: 'Taiki Inomata, pemain bulu tangkis, mengagumi seniornya Chinatsu Kano dari tim basket.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx170942-KKcLfQzV57nG.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/170942-v2GO5YNO0Q5I.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/170942-v2GO5YNO0Q5I.jpg',
      episodeInfo: 'SUB · 25 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 170942,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '20958',
      title: 'Attack on Titan Season 2',
      japaneseTitle: '進撃の巨人 Season 2',
      rating: 8.5,
      releaseYear: 2017,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Pasukan Pengintai mengungkap rahasia di balik dinding dan identitas Titan yang menyamar di antara mereka.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20958-HuFJyr54Mmir.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20958-Y7eQdz9VENBD.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20958-Y7eQdz9VENBD.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20958,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '99147',
      title: 'Attack on Titan Season 3',
      japaneseTitle: '進撃の巨人 Season 3',
      rating: 8.6,
      releaseYear: 2018,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Konflik politik di dalam tembok memanas saat Historia Reiss dan masa lalu keluarga kerajaan mulai terkuak.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx99147-AiPDD8cwlCfi.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/99147-HACsFVrynFf5.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/99147-HACsFVrynFf5.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 99147,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '104578',
      title: 'Attack on Titan Season 3 Part 2',
      japaneseTitle: '進撃の巨人 Season 3 Part 2',
      rating: 9.0,
      releaseYear: 2019,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Pertempuran hidup dan mati di Distrik Shiganshina untuk merebut kembali Wall Maria dan mencapai ruang bawah tanah.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx104578-k61nx3LPjvgd.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/104578-z7SadpYEuAsy.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/104578-z7SadpYEuAsy.jpg',
      episodeInfo: 'SUB · 10 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 104578,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '110277',
      title: 'Attack on Titan Final Season',
      japaneseTitle: '進撃の巨人 The Final Season',
      rating: 8.7,
      releaseYear: 2021,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Empat tahun setelah mencapai lautan, perang antara Pulau Paradis dan bangsa Marley memasuki babak baru.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx110277-sKUNXAsWMNFw.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/110277-iuGn6F5bK1U1.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/110277-iuGn6F5bK1U1.jpg',
      episodeInfo: 'SUB · 16 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 110277,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '131681',
      title: 'Attack on Titan Final Season Part 2',
      japaneseTitle: '進撃の巨人 The Final Season Part 2',
      rating: 8.8,
      releaseYear: 2022,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Pertarungan di Shiganshina memuncak saat Eren dan Zeke berusaha mengaktifkan Rumbling.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx131681-5ooUqvqNtee1.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/131681-3tNurPRsqsfz.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/131681-3tNurPRsqsfz.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 131681,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '146984',
      title: 'Attack on Titan Final Season THE FINAL CHAPTERS Special 1',
      japaneseTitle: '進撃の巨人 The Final Season 完結編（前編）',
      rating: 8.9,
      releaseYear: 2023,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Aliansi Paradis dan Marley berpacu dengan waktu untuk menghentikan Rumbling yang menghancurkan dunia.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx146984-GXrLeT6vQqyP.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/146984-yAkTtW2AExVj.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/146984-yAkTtW2AExVj.jpg',
      episodeInfo: 'SUB · SPECIAL',
      statusLabel: 'Tamat',
      aniListId: 146984,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '162314',
      title: 'Attack on Titan Final Season THE FINAL CHAPTERS Special 2',
      japaneseTitle: '進撃の巨人 The Final Season 完結編（後編）',
      rating: 9.0,
      releaseYear: 2023,
      genres: ['Action', 'Drama', 'Fantasy', 'Mystery'],
      description: 'Babak penutup epik dari perjalanan Eren Yeager, Mikasa, dan Armin dalam pertempuran terakhir umat manusia.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx162314-qIWdAAFtvY8J.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/162314-N5M4XMz6O1j4.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/162314-N5M4XMz6O1j4.jpg',
      episodeInfo: 'SUB · SPECIAL',
      statusLabel: 'Tamat',
      aniListId: 162314,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '10620',
      title: 'Mirai Nikki (Future Diary)',
      japaneseTitle: '未来日記',
      rating: 6.9,
      releaseYear: 2011,
      genres: ['Action', 'Horror', 'Mystery', 'Psychological', 'Thriller'],
      description: 'Yukiteru Amano terjebak dalam permainan bertahan hidup mematikan antar pemilik buku harian masa depan bersama Yuno Gasai.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx10620-dUZeNej0W4QN.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/10620-CsZ2FFSbGpqV.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/10620-CsZ2FFSbGpqV.jpg',
      episodeInfo: 'SUB · 26 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 10620,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '101351',
      title: 'Happy Sugar Life',
      japaneseTitle: 'ハッピーシュガーライフ',
      rating: 6.5,
      releaseYear: 2018,
      genres: ['Drama', 'Horror', 'Mystery', 'Psychological', 'Romance'],
      description: 'Satou Matsuzaka rela melakukan apa pun demi melindungi kehidupan manisnya bersama gadis kecil bernama Shio.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101351-TWLbnRdE1tBI.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101351-gAmnBuRCb1U0.png',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101351-gAmnBuRCb1U0.png',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 101351,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '2476',
      title: 'School Days',
      japaneseTitle: 'スクールデイズ',
      rating: 5.0,
      releaseYear: 2007,
      genres: ['Drama', 'Psychological', 'Romance', 'School'],
      description: 'Makoto Ito meminta bantuan Sekai Saionji untuk mendekati Kotonoha Katsura, yang memicu cinta segitiga kelam.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx2476-GSeJUpMGnj40.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2476-LhCtGB8AbAdB.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2476-LhCtGB8AbAdB.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 2476,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '934',
      title: 'Higurashi no Naku Koro ni (When They Cry)',
      japaneseTitle: 'ひぐらしのなく頃に',
      rating: 7.6,
      releaseYear: 2006,
      genres: ['Horror', 'Mystery', 'Psychological', 'Supernatural', 'Thriller'],
      description: 'Keiichi Maebara pindah ke desa Hinamizawa yang tampak damai, namun menyimpan misteri kutukan berulang setiap festival.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx934-wjMlVEl4CWwg.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/n934-p227WvkFZ7XX.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/n934-p227WvkFZ7XX.jpg',
      episodeInfo: 'SUB · 26 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 934,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '20613',
      title: 'Akame ga Kill!',
      japaneseTitle: 'アカメが斬る！',
      rating: 7.3,
      releaseYear: 2014,
      genres: ['Action', 'Adventure', 'Drama', 'Fantasy'],
      description: 'Tatsumi bergabung dengan kelompok pembunuh bayaran Night Raid untuk menumbangkan kekaisaran yang korup.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20613-HXHpec4bemk5.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20613-CoEQF4qKiWDX.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20613-CoEQF4qKiWDX.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20613,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '15583',
      title: 'Date A Live',
      japaneseTitle: 'デート・ア・ライブ',
      rating: 6.8,
      releaseYear: 2013,
      genres: ['Action', 'Comedy', 'Harem', 'Romance', 'Sci-Fi'],
      description: 'Shido Itsuka harus membuat para Spirit jatuh cinta padanya demi menyelamatkan dunia dari kehancuran.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx15583-Sxd2J4RJdRhj.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/15583.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/15583.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 15583,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '20832',
      title: 'Overlord',
      japaneseTitle: 'オーバーロード',
      rating: 7.6,
      releaseYear: 2015,
      genres: ['Action', 'Adventure', 'Fantasy'],
      description: 'Momonga terjebak di dunia game YGGDRASIL sebagai penguasa Nazarick dan mulai menaklukkan dunia baru.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20832-vUNm5zrYWifc.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20832-NswCiSYMoI2k.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20832-NswCiSYMoI2k.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20832,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '21517',
      title: 'Renai Boukun (Love Tyrant)',
      japaneseTitle: '恋愛暴君',
      rating: 6.2,
      releaseYear: 2017,
      genres: ['Comedy', 'Harem', 'Romance', 'Supernatural'],
      description: 'Seiji Aino mendadak didatangi malaikat Guri yang membawa Kiss Note dan memaksanya mencium gadis lain.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21517-huYdImj17Sr3.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21517-rRAzWHjDBXxM.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21517-rRAzWHjDBXxM.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 21517,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '101921',
      title: 'Kaguya-sama: Love is War',
      japaneseTitle: 'かぐや様は告らせたい',
      rating: 8.3,
      releaseYear: 2019,
      genres: ['Comedy', 'Psychological', 'Romance', 'School'],
      description: 'Miyuki Shirogane dan Kaguya Shinomiya saling menyukai, namun gengsi membuat mereka beradu strategi agar lawan mengaku duluan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101921-ufrjLzhSz7L1.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101921-GgvvFhlNhzlF.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101921-GgvvFhlNhzlF.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 101921,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '20910',
      title: 'Shimoneta',
      japaneseTitle: '下ネタという概念が存在しない退屈な世界',
      rating: 6.9,
      releaseYear: 2015,
      genres: ['Comedy', 'Ecchi', 'School'],
      description: 'Di Jepang masa depan yang menyensor segala hal tidak senonoh, Tanukichi terseret ke organisasi bawah tanah SOX.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20910-U7txwG3o9gma.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20910-QoDcFgTDAeRE.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20910-QoDcFgTDAeRE.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20910,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '177552',
      title: 'Kuroiwa Medaka ni Watashi no Kawaii ga Tsuujinai',
      japaneseTitle: '黒岩メダカに私の可愛いが通じない',
      rating: 7.2,
      releaseYear: 2025,
      genres: ['Comedy', 'Romance', 'School'],
      description: 'Mona Kawai berusaha membuat Medaka Kuroiwa jatuh hati padanya, namun Medaka selalu bersikap dingin.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177552-7XiOf3dGXmNs.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/177552-iLWNEFS7t8HM.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/177552-iLWNEFS7t8HM.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 177552,
      hasVideoAvailable: false,
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
      hasVideoAvailable: true,
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
      episodeInfo: 'SUB · 1 EPS (Preview)',
      statusLabel: 'Ongoing',
      aniListId: 178945,
      hasVideoAvailable: true,
    ),
  ];

  static const List<AnimeItem> cachedPopularAnime = cachedTrendingAnime;
}
