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
      id: '199',
      title: 'Spirited Away (Sen to Chihiro no Kamikakushi)',
      japaneseTitle: '千と千尋の神隠し',
      rating: 8.6,
      releaseYear: 2001,
      genres: ['Adventure', 'Drama', 'Fantasy', 'Movie'],
      description: 'Chihiro terjebak di dunia para roh dan harus bekerja di pemandian milik penyihir Yubaba untuk menyelamatkan orang tuanya.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx199-sWefXJvXkDOb.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/199-Sm2RU5PSqw7T.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/199-Sm2RU5PSqw7T.jpg',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 199,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '918',
      title: 'Gintama',
      japaneseTitle: '銀魂',
      rating: 8.5,
      releaseYear: 2006,
      genres: ['Action', 'Comedy', 'Drama', 'Sci-Fi'],
      description: 'Di Edo yang dikuasai alien Amanto, samurai eksentrik Gintoki Sakata menjalankan usaha serabutan Yorozuya.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx918-iOaeBVUn4uK7.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/918-bljqHE1PFArH.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/918-bljqHE1PFArH.jpg',
      episodeInfo: 'SUB · 201 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 918,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '9969',
      title: 'Gintama\' (Season 2)',
      japaneseTitle: '銀魂’',
      rating: 8.9,
      releaseYear: 2011,
      genres: ['Action', 'Comedy', 'Drama', 'Sci-Fi'],
      description: 'Kelanjutan aksi kocak dan arc serius Gintoki bersama Shinsuke, Shinsengumi, dan warga Kabukicho.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx9969-0GaRABYVdUcH.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/9969-pxE6nSzGGyUB.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/9969-pxE6nSzGGyUB.jpg',
      episodeInfo: 'SUB · 51 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 9969,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '15417',
      title: 'Gintama\': Enchousen',
      japaneseTitle: '銀魂’延長戦',
      rating: 8.9,
      releaseYear: 2012,
      genres: ['Action', 'Comedy', 'Drama', 'Sci-Fi'],
      description: 'Arc Courtesan of a Nation dan Beam Saber yang mengguncang sejarah Edo serta rahasia masa lalu Shoyo.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx15417-Uc2uNdWEixwi.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/15417-0T9JCwFZM99Q.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/15417-0T9JCwFZM99Q.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 15417,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '20996',
      title: 'Gintama° (Season 3)',
      japaneseTitle: '銀魂°',
      rating: 9.0,
      releaseYear: 2015,
      genres: ['Action', 'Comedy', 'Drama', 'Sci-Fi'],
      description: 'Dari komedi parodi hingga tragedi Shogun Assassination dan Farewell Shinsengumi yang mengubah segalanya.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20996-kBEGEGdeK1r7.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20996-gaNJKtjmy3Pf.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20996-gaNJKtjmy3Pf.jpg',
      episodeInfo: 'SUB · 51 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20996,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '97889',
      title: 'Gintama. (Season 4)',
      japaneseTitle: '銀魂.',
      rating: 8.9,
      releaseYear: 2017,
      genres: ['Action', 'Comedy', 'Drama', 'Sci-Fi'],
      description: 'Yorozuya bertempur di Rakuyo untuk menyelamatkan Kagura dan menghadapi aliansi Harusame.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx97889-ytqHdmus9wQi.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/97889-z0Gm66dFW93U.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/97889-z0Gm66dFW93U.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 97889,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '99714',
      title: 'Gintama.: Porori-hen (Slip Arc)',
      japaneseTitle: '銀魂. ポロリ篇',
      rating: 8.2,
      releaseYear: 2017,
      genres: ['Action', 'Comedy', 'Sci-Fi'],
      description: 'Kumpulan cerita komedi klasik yang belum sempat diadaptasi sebelum pertempuran terakhir.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx99714-0pCKHe4XYIz7.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/99714-mPAF6Pk56mKc.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/99714-mPAF6Pk56mKc.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 99714,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '100784',
      title: 'Gintama.: Shirogane no Tamashii-hen',
      japaneseTitle: '銀魂. 銀ノ魂篇',
      rating: 8.6,
      releaseYear: 2018,
      genres: ['Action', 'Comedy', 'Drama', 'Sci-Fi'],
      description: 'Babak awal Arc Jiwa Perak saat Edo bersatu menghadapi invasi Utsuro dan pasukan Altana.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx100784-7fWdiduBFr95.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/100784-jDLVx9EAO0HF.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/100784-jDLVx9EAO0HF.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 100784,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '101925',
      title: 'Gintama.: Shirogane no Tamashii-hen - Kouhan-sen',
      japaneseTitle: '銀魂. 銀ノ魂篇 後半戦',
      rating: 8.7,
      releaseYear: 2018,
      genres: ['Action', 'Comedy', 'Drama', 'Sci-Fi'],
      description: 'Pertarungan klimaks Arc Jiwa Perak dua tahun setelah invasi demi masa depan Edo.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101925-gcA84dgcSj2w.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101925-eyVjqcyh4Gsu.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101925-eyVjqcyh4Gsu.jpg',
      episodeInfo: 'SUB · 14 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 101925,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '162890',
      title: '3-nen Z-gumi Ginpachi-sensei',
      japaneseTitle: '3年Z組銀八先生',
      rating: 7.5,
      releaseYear: 2025,
      genres: ['Comedy', 'Parody', 'School'],
      description: 'Spin-off sekolah Gintama dengan Ginpachi-sensei sebagai wali kelas paling absurd di kelas 3-Z.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx162890-vDRlo1KuRM6W.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/162890-aY5XAN4j9Ph2.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/162890-aY5XAN4j9Ph2.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 162890,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '190327',
      title: 'JoJo\'s Bizarre Adventure: Steel Ball Run - 1st STAGE',
      japaneseTitle: 'スティール・ボール・ラン ジョジョの奇妙な冒険 1st STAGE',
      rating: 8.7,
      releaseYear: 2026,
      genres: ['Action', 'Adventure', 'Mystery', 'Supernatural'],
      description: 'Johnny Joestar dan Gyro Zeppeli memulai perlombaan pacuan kuda lintas Amerika demi mencari rahasia Spin.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx190327-riJNCFL7w9y4.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/190327-bXr8tFZUdxOw.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/190327-bXr8tFZUdxOw.jpg',
      episodeInfo: 'SUB · 1 EP (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 190327,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '210482',
      title: 'JoJo\'s Bizarre Adventure: Steel Ball Run - 2nd & 3rd STAGE',
      japaneseTitle: 'スティール・ボール・ラン ジョジョの奇妙な冒険 2nd & 3rd STAGE',
      rating: 8.6,
      releaseYear: 2026,
      genres: ['Action', 'Adventure', 'Mystery', 'Supernatural'],
      description: 'Kelanjutan perlombaan Steel Ball Run dengan konspirasi Saint\'s Corpse dan musuh-musuh Stand mematikan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx210482-P1VNKbqdJ6Zj.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/210482-pYAD0IbzNbgS.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/210482-pYAD0IbzNbgS.jpg',
      episodeInfo: 'SUB · 11 EPS',
      statusLabel: 'Tamat',
      aniListId: 210482,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '161645',
      title: 'The Apothecary Diaries (Kusuriya no Hitorigoto)',
      japaneseTitle: '薬屋のひとりごと',
      rating: 8.8,
      releaseYear: 2023,
      genres: ['Drama', 'Historical', 'Mystery'],
      description: 'Maomao si peracik obat yang cerdas memecahkan berbagai misteri dan intrik racun di istana kekaisaran.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx161645-QLbzHXiYRgV2.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/161645-oqzTZYIvviWI.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/161645-oqzTZYIvviWI.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 161645,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '176301',
      title: 'The Apothecary Diaries Season 2',
      japaneseTitle: '薬屋のひとりごと 第2期',
      rating: 8.8,
      releaseYear: 2025,
      genres: ['Drama', 'Historical', 'Mystery'],
      description: 'Maomao dan Jinshi menghadapi kasus baru yang lebih berbahaya serta konspirasi besar di balik istana.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx176301-TIGmldLffQGX.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/176301-GkuTF1YTT6b2.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/176301-GkuTF1YTT6b2.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 176301,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '195516',
      title: 'The Apothecary Diaries Season 3',
      japaneseTitle: '薬屋のひとりごと 第3期',
      rating: 8.5,
      releaseYear: 2026,
      genres: ['Drama', 'Historical', 'Mystery'],
      description: 'Babak baru petualangan Maomao mengungkap misteri di luar dinding istana kekaisaran.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx195516-MJpUZlOberqH.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/195516-B5M0cPaQbQXI.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/195516-B5M0cPaQbQXI.jpg',
      episodeInfo: 'SUB · 12 EPS',
      statusLabel: 'Ongoing',
      aniListId: 195516,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '1689',
      title: '5 Centimeters per Second (Byousoku 5 Centimeter)',
      japaneseTitle: '秒速５センチメートル',
      rating: 7.1,
      releaseYear: 2007,
      genres: ['Drama', 'Movie', 'Romance', 'Slice of Life'],
      description: 'Kisah jarak, waktu, dan kenangan antara Takaki Tono dan Akari Shinohara yang perlahan menjauh seiring dewasa.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx1689-rJKhjLEjQHSy.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1689.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1689.jpg',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 1689,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '99750',
      title: 'I Want to Eat Your Pancreas (Kimi no Suizou wo Tabetai)',
      japaneseTitle: '君の膵臓をたべたい',
      rating: 8.4,
      releaseYear: 2018,
      genres: ['Drama', 'Movie', 'Romance', 'Slice of Life'],
      description: 'Seorang siswa penyendiri menemukan buku harian Sakura Yamauchi dan mengetahui rahasia penyakit pankreas yang dideritanya.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx99750-pNyly9d3MEgV.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/99750-KPFW2Jv03b2B.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/99750-KPFW2Jv03b2B.jpg',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 99750,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '20872',
      title: 'Plastic Memories',
      japaneseTitle: 'プラスティックメモリーズ',
      rating: 7.7,
      releaseYear: 2015,
      genres: ['Drama', 'Romance', 'Sci-Fi', 'Slice of Life'],
      description: 'Tsukasa Mizugaki bekerja bersama android bernama Isla untuk mengambil kembali Giftia sebelum masa aktifnya habis.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20872-j5PBzzVtrYDM.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20872-RlrRw6pnwLWK.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20872-RlrRw6pnwLWK.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20872,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '21234',
      title: 'Boku dake ga Inai Machi (ERASED)',
      japaneseTitle: '僕だけがいない街',
      rating: 8.1,
      releaseYear: 2016,
      genres: ['Drama', 'Mystery', 'Psychological', 'Supernatural', 'Thriller'],
      description: 'Satoru Fujinuma terlempar 18 tahun ke masa lalu untuk mencegah penculikan berantai dan menyelamatkan Kayo Hinazuki.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21234-XmqW39aQ9o7O.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21234-7lfSSPoMmwr2.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21234-7lfSSPoMmwr2.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 21234,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '21860',
      title: 'Shuumatsu Nani Shitemasu ka? (WorldEnd)',
      japaneseTitle: '終末なにしてますか? 忙しいですか? 救ってもらっていいですか?',
      rating: 7.5,
      releaseYear: 2017,
      genres: ['Drama', 'Fantasy', 'Mystery', 'Romance', 'Supernatural'],
      description: 'Willem Kmetsch merawat para gadis Leprechaun termasuk Chtholly yang menjadi senjata terakhir melawan monster Beast.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21860-lSIbYJtEbAXu.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21860-oQ0YAYNOtGTU.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21860-oQ0YAYNOtGTU.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 21860,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '105333',
      title: 'Dr. STONE',
      japaneseTitle: 'Dr.STONE',
      rating: 8.1,
      releaseYear: 2019,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Senku Ishigami terbangun ribuan tahun setelah umat manusia membatu dan bertekad membangun kembali peradaban dengan sains.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx105333-GybuoSoOZfpH.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/105333-KWKGvBM8Hyga.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/105333-KWKGvBM8Hyga.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 105333,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '113936',
      title: 'Dr. STONE: STONE WARS',
      japaneseTitle: 'Dr.STONE STONE WARS',
      rating: 8.1,
      releaseYear: 2021,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Kerajaan Sains pimpinan Senku berhadapan langsung dengan Kekaisaran Kekuatan pimpinan Tsukasa.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx113936-D4eYd4XwslVI.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/113936-PpMtCY9kCwwV.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/113936-PpMtCY9kCwwV.jpg',
      episodeInfo: 'SUB · 11 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 113936,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '142876',
      title: 'Dr. STONE: Ryuusui',
      japaneseTitle: 'Dr.STONE 龍水',
      rating: 8.0,
      releaseYear: 2022,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Senku membangkitkan kapten laut jenius Ryusui Nanami untuk membangun kapal dan berlayar melintasi samudra.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx142876-izO35hPP2DZ9.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/142876-4vxyOR19TI7i.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/142876-4vxyOR19TI7i.jpg',
      episodeInfo: 'SUB · SPECIAL',
      statusLabel: 'Tamat',
      aniListId: 142876,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '131518',
      title: 'Dr. STONE: NEW WORLD',
      japaneseTitle: 'Dr.STONE NEW WORLD',
      rating: 8.1,
      releaseYear: 2023,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Ekspedisi kapal Perseus berlayar menuju Treasure Island untuk mencari sumber cahaya pembatuan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx131518-RU7RoUmGb2sP.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/131518-uENBDjWnMHmN.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/131518-uENBDjWnMHmN.jpg',
      episodeInfo: 'SUB · 11 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 131518,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '162670',
      title: 'Dr. STONE: NEW WORLD Part 2',
      japaneseTitle: 'Dr.STONE NEW WORLD 第2クール',
      rating: 8.2,
      releaseYear: 2023,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Pertempuran sengit memperebutkan alat pembatuan melawan Ibara dan prajurit Kerajaan Pembatuan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx162670-07XrFq2hreTx.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/162670-usucQbwBz6ES.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/162670-usucQbwBz6ES.jpg',
      episodeInfo: 'SUB · 11 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 162670,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '172019',
      title: 'Dr. STONE: SCIENCE FUTURE',
      japaneseTitle: 'Dr.STONE SCIENCE FUTURE',
      rating: 8.2,
      releaseYear: 2025,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Kerajaan Sains berlayar ke Amerika untuk mengumpulkan bahan pembuatan roket menuju Bulan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx172019-3cfZbrYBmV23.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/172019-qchFwdk8OM4m.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/172019-qchFwdk8OM4m.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 172019,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '189117',
      title: 'Dr. STONE: SCIENCE FUTURE Part 2',
      japaneseTitle: 'Dr.STONE SCIENCE FUTURE 第2クール',
      rating: 8.5,
      releaseYear: 2025,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Pengejaran melintasi Amerika Selatan melawan pasukan Dr. Xeno dan Stanley demi menguak misteri Medusa.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx189117-TLtCXYT7JPoL.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/189117-SEvEg0G0Rcv7.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/189117-SEvEg0G0Rcv7.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 189117,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '199221',
      title: 'Dr. STONE: SCIENCE FUTURE Part 3',
      japaneseTitle: 'Dr.STONE SCIENCE FUTURE 第3クール',
      rating: 8.3,
      releaseYear: 2026,
      genres: ['Action', 'Adventure', 'Comedy', 'Sci-Fi'],
      description: 'Babak penutup misi luar angkasa Kerajaan Sains untuk menghadapi Why-man di Bulan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx199221-TReDQMNhslHu.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/199221-b3W0FfJd4zMy.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/199221-b3W0FfJd4zMy.jpg',
      episodeInfo: 'SUB · 13 EPS',
      statusLabel: 'Ongoing',
      aniListId: 199221,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '21507',
      title: 'Mob Psycho 100',
      japaneseTitle: 'モブサイコ100',
      rating: 8.4,
      releaseYear: 2016,
      genres: ['Action', 'Comedy', 'Drama', 'Psychological', 'Supernatural'],
      description: 'Shigeo "Mob" Kageyama adalah siswa SMP berkekuatan esper luar biasa yang bekerja paruh waktu untuk Reigen Arataka.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21507-6YUSbh2m0N1p.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21507-Qx8bGsLXUgLo.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21507-Qx8bGsLXUgLo.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 21507,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '101338',
      title: 'Mob Psycho 100 II',
      japaneseTitle: 'モブサイコ100 II',
      rating: 8.7,
      releaseYear: 2019,
      genres: ['Action', 'Comedy', 'Drama', 'Psychological', 'Supernatural'],
      description: 'Mob mulai tumbuh lebih dewasa secara emosional saat menghadapi organisasi esper Claw dan krisis hubungannya dengan Reigen.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101338-rokVscjRYzdP.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101338-Rl54Qhx71dUq.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101338-Rl54Qhx71dUq.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 101338,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '140439',
      title: 'Mob Psycho 100 III',
      japaneseTitle: 'モブサイコ100 Ⅲ',
      rating: 8.7,
      releaseYear: 2022,
      genres: ['Action', 'Comedy', 'Drama', 'Psychological', 'Supernatural'],
      description: 'Babak akhir perjalanan Mob menghadapi Pohon Suci, Dimple, dan menerima sisi sejati dirinya.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx140439-bPKmhe1wNxc9.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/140439-r9SRh0q0UgX1.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/140439-r9SRh0q0UgX1.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 140439,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '153518',
      title: 'Delicious in Dungeon (Dungeon Meshi)',
      japaneseTitle: 'ダンジョン飯',
      rating: 8.5,
      releaseYear: 2024,
      genres: ['Adventure', 'Comedy', 'Fantasy'],
      description: 'Laios dan timnya menjelajahi dungeon sambil memasak monster untuk bertahan hidup demi menyelamatkan adiknya, Falin.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx153518-IVXPDY5ph3kO.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/153518-7uRvV7SLqmHV.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/153518-7uRvV7SLqmHV.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 153518,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '101348',
      title: 'Vinland Saga',
      japaneseTitle: 'ヴィンランド・サガ',
      rating: 8.7,
      releaseYear: 2019,
      genres: ['Action', 'Adventure', 'Drama', 'Historical'],
      description: 'Thorfinn tumbuh di tengah pasukan Viking Askeladd sambil memendam dendam atas kematian ayahnya, Thors.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101348-2fhDFPCuMNiz.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101348-pivKKffCAwAY.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101348-pivKKffCAwAY.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 101348,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '136430',
      title: 'Vinland Saga Season 2',
      japaneseTitle: 'ヴィンランド・サガ SEASON2',
      rating: 8.8,
      releaseYear: 2023,
      genres: ['Action', 'Adventure', 'Drama', 'Historical'],
      description: 'Kehilangan tujuan hidup, Thorfinn bekerja sebagai budak di ladang Ketil dan mulai menemukan arti sejati dari pejuang.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx136430-gsBsJjA7hGh9.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/136430-ktoFZnyubhHg.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/136430-ktoFZnyubhHg.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 136430,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '1',
      title: 'Cowboy Bebop',
      japaneseTitle: 'カウボーイビバップ',
      rating: 8.6,
      releaseYear: 1998,
      genres: ['Action', 'Adventure', 'Drama', 'Sci-Fi'],
      description: 'Spike Spiegel dan kru kapal Bebop berburu buronan melintasi tata surya sambil dihantui masa lalu masing-masing.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx1-GCsPm7waJ4kS.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-OquNCNB6srGe.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-OquNCNB6srGe.jpg',
      episodeInfo: 'SUB · 26 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 1,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '19',
      title: 'Monster',
      japaneseTitle: 'MONSTER',
      rating: 8.8,
      releaseYear: 2004,
      genres: ['Drama', 'Horror', 'Mystery', 'Psychological', 'Thriller'],
      description: 'Dr. Kenzo Tenma mempertaruhkan segalanya untuk memburu Johan Liebert, anak yang pernah ia selamatkan namun tumbuh menjadi pembunuh berantai.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx19-gtMC64182sm4.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/19-kJhwsB0Z97tL.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/19-kJhwsB0Z97tL.jpg',
      episodeInfo: 'SUB · 74 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 19,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '1575',
      title: 'Code Geass: Lelouch of the Rebellion',
      japaneseTitle: 'コードギアス 反逆のルルーシュ',
      rating: 8.5,
      releaseYear: 2006,
      genres: ['Action', 'Drama', 'Mecha', 'Sci-Fi', 'Thriller'],
      description: 'Pangeran terbuang Lelouch vi Britannia memperoleh kekuatan Geass dan memimpin pemberontakan melawan Kekaisaran Britannia.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx1575-hsmWM2ydNm1m.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1575.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1575.jpg',
      episodeInfo: 'SUB · 25 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 1575,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '2904',
      title: 'Code Geass: Lelouch of the Rebellion R2',
      japaneseTitle: 'コードギアス 反逆のルルーシュ R2',
      rating: 8.7,
      releaseYear: 2008,
      genres: ['Action', 'Drama', 'Mecha', 'Sci-Fi', 'Thriller'],
      description: 'Lelouch kembali sebagai Zero untuk menuntaskan rencana besarnya dan mengubah masa depan dunia.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx2904-Fet9Q33suC7G.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2904-X71fcvE83n3s.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2904-X71fcvE83n3s.jpg',
      episodeInfo: 'SUB · 25 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 2904,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '20987',
      title: 'Himouto! Umaru-chan',
      japaneseTitle: '干物妹！うまるちゃん',
      rating: 6.7,
      releaseYear: 2015,
      genres: ['Comedy', 'School', 'Slice of Life'],
      description: 'Umaru Doma adalah siswi teladan di sekolah, namun di rumah ia berubah menjadi adik pemalas pecinta game dan cola.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20987-9Tq7kZTeJPMo.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20987-jnbJ4VXW687z.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20987-jnbJ4VXW687z.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20987,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '98572',
      title: 'Himouto! Umaru-chan R',
      japaneseTitle: '干物妹! うまるちゃん R',
      rating: 7.1,
      releaseYear: 2017,
      genres: ['Comedy', 'School', 'Slice of Life'],
      description: 'Keseharian kocak Umaru bersama Taihei dan teman-temannya berlanjut dengan lebih banyak kehangatan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx98572-zJQd23nzJips.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/98572-cSJYhHQmQXLY.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/98572-cSJYhHQmQXLY.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 98572,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '143270',
      title: 'Lycoris Recoil',
      japaneseTitle: 'リコリス・リコイル',
      rating: 8.1,
      releaseYear: 2022,
      genres: ['Action', 'Slice of Life'],
      description: 'Chisato Nishikigi dan Takina Inoue bekerja di kafe LycoReco sembari menjalankan misi rahasia menjaga kedamaian Jepang.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx143270-rfkyiYXhek5w.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/143270-Ivjs2nVpARtS.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/143270-Ivjs2nVpARtS.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 143270,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '137822',
      title: 'BLUE LOCK',
      japaneseTitle: 'ブルーロック',
      rating: 7.9,
      releaseYear: 2022,
      genres: ['Action', 'Drama', 'Sports'],
      description: 'Yoichi Isagi mengikuti program latihan ekstrem Blue Lock demi mencetak penyerang terbaik dan paling egois untuk Jepang.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx137822-U8naszP96vzC.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/137822-oevspckMGLuY.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/137822-oevspckMGLuY.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 137822,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '163146',
      title: 'BLUE LOCK Season 2 (VS. U-20 JAPAN)',
      japaneseTitle: 'ブルーロック VS. U-20 JAPAN',
      rating: 7.5,
      releaseYear: 2024,
      genres: ['Action', 'Drama', 'Sports'],
      description: 'Tim Blue Lock Eleven bertanding melawan Timnas U-20 Jepang demi mempertahankan kelangsungan proyek Blue Lock.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx163146-BVZPgyzkqi82.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/163146-HIz04v1Or7He.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/163146-HIz04v1Or7He.jpg',
      episodeInfo: 'SUB · 14 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 163146,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '2167',
      title: 'Clannad',
      japaneseTitle: 'ＣＬＡＮＮＡＤ -クラナド-',
      rating: 7.7,
      releaseYear: 2007,
      genres: ['Comedy', 'Drama', 'Romance', 'School', 'Slice of Life'],
      description: 'Tomoya Okazaki bertemu Nagisa Furukawa dan berbagai gadis di sekolahnya, mengubah hidupnya yang hampa.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx2167-pSDBcyc0vjej.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2167.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2167.jpg',
      episodeInfo: 'SUB · 23 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 2167,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '4181',
      title: 'Clannad: After Story',
      japaneseTitle: 'ＣＬＡＮＮＡＤ ~After Story~',
      rating: 8.8,
      releaseYear: 2008,
      genres: ['Drama', 'Romance', 'Slice of Life', 'Supernatural'],
      description: 'Kelanjutan kisah Tomoya dan Nagisa setelah lulus SMA menghadapi pahit manis kehidupan dewasa dan keluarga.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx4181-zUKE7BZC62OF.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/4181.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/4181.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 4181,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '10408',
      title: 'Hotarubi no Mori e (Into the Forest of Fireflies\' Light)',
      japaneseTitle: '蛍火の杜へ',
      rating: 7.9,
      releaseYear: 2011,
      genres: ['Drama', 'Fantasy', 'Movie', 'Romance', 'Supernatural'],
      description: 'Hotaru Takegawa menjalin persahabatan dan cinta musim panas dengan roh hutan bernama Gin yang tak boleh disentuh manusia.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx10408-PlKJ6DAyvMk2.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/10408-kZhXe0uVrAd2.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/10408-kZhXe0uVrAd2.jpg',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 10408,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '9989',
      title: 'Anohana: The Flower We Saw That Day',
      japaneseTitle: 'あの日見た花の名前を僕達はまだ知らない。',
      rating: 8.0,
      releaseYear: 2011,
      genres: ['Drama', 'Romance', 'Slice of Life', 'Supernatural'],
      description: 'Arwah Menma kembali menemui Jinta untuk mengabulkan satu keinginan terakhir agar teman-teman masa kecilnya bersatu kembali.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx9989-hImMg6kCMm6I.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/9989-pyr6rXlV1oAm.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/9989-pyr6rXlV1oAm.jpg',
      episodeInfo: 'SUB · 11 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 9989,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '18245',
      title: 'White Album 2',
      japaneseTitle: 'WHITE ALBUM 2',
      rating: 7.4,
      releaseYear: 2013,
      genres: ['Drama', 'Music', 'Romance', 'Slice of Life'],
      description: 'Haruki Kitahara membentuk band festival bersama Setsuna Ogiso dan Kazusa Touma yang memicu cinta segitiga penuh luka.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx18245-7eMtaBsi00dl.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/18245-kcqQvFqQmMg2.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/18245-kcqQvFqQmMg2.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 18245,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '16662',
      title: 'The Wind Rises (Kaze Tachinu)',
      japaneseTitle: '風立ちぬ',
      rating: 8.0,
      releaseYear: 2013,
      genres: ['Drama', 'Movie', 'Romance'],
      description: 'Kisah Jiro Horikoshi yang bermimpi merancang pesawat terbang di tengah gejolak sejarah dan cintanya pada Nahoko.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16662-HUI8irtoTdOJ.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16662-XLmadbKVsRW2.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16662-XLmadbKVsRW2.jpg',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 16662,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '2001',
      title: 'Tengen Toppa Gurren Lagann',
      japaneseTitle: '天元突破グレンラガン',
      rating: 8.5,
      releaseYear: 2007,
      genres: ['Action', 'Comedy', 'Drama', 'Mecha', 'Sci-Fi'],
      description: 'Simon dan Kamina menembus permukaan bumi dengan mecha Lagann untuk membebaskan umat manusia dari penindasan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx2001-XwRnjzGeFWRQ.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2001-3eWhvkau8NV3.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/2001-3eWhvkau8NV3.jpg',
      episodeInfo: 'SUB · 27 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 2001,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '4107',
      title: 'Gurren Lagann The Movie: Childhood\'s End',
      japaneseTitle: '天元突破グレンラガン 紅蓮篇',
      rating: 7.9,
      releaseYear: 2008,
      genres: ['Action', 'Drama', 'Mecha', 'Movie', 'Sci-Fi'],
      description: 'Film kompilasi babak pertama Tengen Toppa Gurren Lagann dengan adegan pertarungan baru.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx4107-WaS60WNsKZuu.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/4107-AEaJQo7InYJ1.png',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/4107-AEaJQo7InYJ1.png',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 4107,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '4565',
      title: 'Gurren Lagann The Movie: The Lights in the Sky are Stars',
      japaneseTitle: '天元突破グレンラガン 螺巌篇',
      rating: 8.5,
      releaseYear: 2009,
      genres: ['Action', 'Drama', 'Mecha', 'Movie', 'Sci-Fi'],
      description: 'Film kompilasi babak kedua dengan pertarungan klimaks skala galaksi melawan Anti-Spiral.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx4565-FbFYEBTJSPyr.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/4565-Ngb9pZ0nuf8s.png',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/4565-Ngb9pZ0nuf8s.png',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 4565,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '126546',
      title: 'Seirei Gensouki: Spirit Chronicles',
      japaneseTitle: '精霊幻想記',
      rating: 6.9,
      releaseYear: 2021,
      genres: ['Action', 'Drama', 'Fantasy', 'Romance'],
      description: 'Rio terbangun dengan ingatan kehidupan sebelumnya sebagai Haruto Amakawa dan memulai perjalanan di dunia fantasi penuh sihir.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx126546-Jujx9OvKxLzA.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/126546-eSjc83C90h24.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/126546-eSjc83C90h24.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 126546,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '141182',
      title: 'Seirei Gensouki: Spirit Chronicles Season 2',
      japaneseTitle: '精霊幻想記2',
      rating: 6.9,
      releaseYear: 2024,
      genres: ['Action', 'Drama', 'Fantasy', 'Romance'],
      description: 'Rio kembali ke wilayah Strahl setelah pengembaraannya di Yagumo dan menghadapi konflik baru para pahlawan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx141182-xNtdR0PenhRR.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/141182-ZHCTx8JhKujK.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/141182-ZHCTx8JhKujK.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 141182,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '185407',
      title: 'Takopii no Genzai (Takopi\'s Original Sin)',
      japaneseTitle: 'タコピーの原罪',
      rating: 8.6,
      releaseYear: 2025,
      genres: ['Drama', 'Psychological', 'Sci-Fi'],
      description: 'Alien ceria bernama Takopi datang ke Bumi untuk menyebarkan kebahagiaan, namun pertemuannya dengan Shizuka membawanya ke kenyataan kelam yang tak bisa diselesaikan hanya dengan alat ajaib.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx185407-7uzY4fA3hokP.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/185407-WOKgyadY4Pr1.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/185407-WOKgyadY4Pr1.jpg',
      episodeInfo: 'SUB · 6 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 185407,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '20754',
      title: 'Gakkou Gurashi! (School-Live!)',
      japaneseTitle: 'がっこうぐらし！',
      rating: 7.4,
      releaseYear: 2015,
      genres: ['Horror', 'Mystery', 'Psychological', 'Slice of Life', 'Supernatural'],
      description: 'Yuki Takeya dan anggota Klub Kehidupan Sekolah tinggal di sekolah mereka setiap hari, namun di balik keceriaan mereka tersembunyi kenyataan mengerikan tentang dunia luar.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20754-e5JXeLpHoN7w.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20754-Hwnbsm4uaVFD.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20754-Hwnbsm4uaVFD.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20754,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '100010',
      title: 'Mahou Shoujo Site (Magical Girl Site)',
      japaneseTitle: '魔法少女サイト',
      rating: 6.1,
      releaseYear: 2018,
      genres: ['Action', 'Drama', 'Horror', 'Mahou Shoujo', 'Psychological', 'Supernatural'],
      description: 'Aya Asagiri yang terus dirundung menemukan situs misterius bernama Magical Girl Site yang memberinya tongkat sihir dan menyeretnya ke dalam pertarungan bertahan hidup yang kejam.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx100010-FCSVBvRZ6Ifl.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/100010-WZMK7JXMAi2i.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/100010-WZMK7JXMAi2i.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 100010,
      hasVideoAvailable: true,
    ),
    AnimeItem(
      id: '143200',
      title: 'Summer Pockets',
      japaneseTitle: 'Summer Pockets',
      rating: 7.1,
      releaseYear: 2025,
      genres: ['Drama', 'Romance', 'Slice of Life', 'Supernatural'],
      description: 'Hairi Takahara pergi ke Pulau Torishirojima di musim panas untuk membereskan barang peninggalan neneknya dan bertemu para gadis misterius yang menyimpan kenangan masa lalu.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx143200-42OaDCS6VEy3.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/143200-R0qpwS1C6b8i.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/143200-R0qpwS1C6b8i.jpg',
      episodeInfo: 'SUB · 26 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 143200,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '20800',
      title: 'Yuuki Yuuna wa Yuusha de Aru (Yuki Yuna is a Hero)',
      japaneseTitle: '結城友奈は勇者である',
      rating: 7.2,
      releaseYear: 2014,
      genres: ['Action', 'Drama', 'Fantasy', 'Mahou Shoujo', 'Psychological', 'Slice of Life'],
      description: 'Yuuna Yuuki adalah siswi SMP anggota Klub Pahlawan yang bertugas melindungi dunia dari ancaman makhluk misterius bernama Vertex.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20800-7IAW762FbSFU.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20800-KpoJB6tGnj2V.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20800-KpoJB6tGnj2V.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 20800,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '114446',
      title: 'Higurashi no Naku Koro ni Gou',
      japaneseTitle: 'ひぐらしのなく頃に業',
      rating: 6.9,
      releaseYear: 2020,
      genres: ['Drama', 'Horror', 'Mystery', 'Psychological', 'Supernatural', 'Thriller'],
      description: 'Keiichi Maebara pindah ke desa tenang Hinamizawa, namun segera terseret dalam misteri kutukan dan tragedi berulang setiap festival Watanagashi.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx114446-H6uxjVi8wBoo.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/114446-DTd4xfGx7DJB.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/114446-DTd4xfGx7DJB.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 114446,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '9756',
      title: 'Mahou Shoujo Madoka Magica (Puella Magi Madoka Magica)',
      japaneseTitle: '魔法少女まどか☆マギカ',
      rating: 8.3,
      releaseYear: 2011,
      genres: ['Action', 'Drama', 'Fantasy', 'Mahou Shoujo', 'Psychological', 'Thriller'],
      description: 'Madoka Kaname ditawari kontrak menjadi gadis penyihir oleh makhluk misterius bernama Kyubey, namun segera mengetahui kenyataan kelam di balik takdir para penyihir.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx9756-QnUGwlwwnsuN.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/9756-d5M8NffgJJHB.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/9756-d5M8NffgJJHB.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 9756,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '97986',
      title: 'Made in Abyss',
      japaneseTitle: 'メイドインアビス',
      rating: 8.4,
      releaseYear: 2017,
      genres: ['Adventure', 'Drama', 'Fantasy', 'Horror', 'Mystery', 'Sci-Fi'],
      description: 'Riko dan robot misterius Reg turun menjelajahi jurang raksasa Abyss yang penuh relik kuno dan makhluk berbahaya demi menemukan ibu Riko.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx97986-TQ7dCgbS3y5s.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/97986-C55UnbJKB7ZF.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/97986-C55UnbJKB7ZF.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 97986,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '177159',
      title: 'Momentary Lily',
      japaneseTitle: 'もめんたりー・リリィ',
      rating: 5.4,
      releaseYear: 2025,
      genres: ['Action', 'Adventure', 'Mystery', 'Sci-Fi', 'Slice of Life'],
      description: 'Di dunia yang terancam oleh mesin misterius, sekelompok gadis bertarung menggunakan senjata khusus sambil mempertahankan kehangatan hidup sehari-hari.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177159-Yt7VNCVjlnxR.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/177159-gvNAEPFmGAfT.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/177159-gvNAEPFmGAfT.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 177159,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '108147',
      title: 'Granbelm',
      japaneseTitle: 'グランベルム',
      rating: 6.3,
      releaseYear: 2019,
      genres: ['Action', 'Adventure', 'Drama', 'Fantasy', 'Mahou Shoujo', 'Mecha'],
      description: 'Mangetsu Kohinata terlempar ke dunia sihir malam purnama dan ikut bertarung menggunakan mecha sihir ARMANOX dalam turnamen Granbelm.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/b108147-pymvfgDxie1b.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/108147-BGaAzTwozw12.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/108147-BGaAzTwozw12.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 108147,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '105334',
      title: 'Fruits Basket: 1st Season',
      japaneseTitle: 'フルーツバスケット 1st season',
      rating: 8.2,
      releaseYear: 2019,
      genres: ['Comedy', 'Drama', 'Romance', 'Slice of Life', 'Supernatural'],
      description: 'Setelah kehilangan tempat tinggal, Tohru Honda mulai tinggal bersama keluarga Soma dan mengetahui rahasia kutukan dua belas shio.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx105334-AZwEdMu4KFtV.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/105334-dPfrCyZ8GkOI.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/105334-dPfrCyZ8GkOI.jpg',
      episodeInfo: 'SUB · 25 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 105334,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '111762',
      title: 'Fruits Basket: 2nd Season',
      japaneseTitle: 'フルーツバスケット 2nd season',
      rating: 8.5,
      releaseYear: 2020,
      genres: ['Comedy', 'Drama', 'Psychological', 'Romance', 'Slice of Life', 'Supernatural'],
      description: 'Memasuki tahun kedua SMA, Tohru Honda semakin dekat dengan keluarga Soma dan bertekad mencari cara mematahkan kutukan shio.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx111762-C8TNf5uRlVNQ.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/111762-VvlNooo9xZa4.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/111762-VvlNooo9xZa4.jpg',
      episodeInfo: 'SUB · 25 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 111762,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '124194',
      title: 'Fruits Basket: The Final (Season 3)',
      japaneseTitle: 'フルーツバスケット The Final',
      rating: 8.9,
      releaseYear: 2021,
      genres: ['Comedy', 'Drama', 'Psychological', 'Romance', 'Slice of Life', 'Supernatural'],
      description: 'Musim penutup kisah Tohru Honda bersama Yuki, Kyo, dan seluruh keluarga Soma saat ikatan kutukan shio akhirnya menghadapi akhir.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx124194-TJlqMMR7BGn9.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/124194-IB2X2IdALUYB.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/124194-IB2X2IdALUYB.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 124194,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '17895',
      title: 'Golden Time',
      japaneseTitle: 'ゴールデンタイム',
      rating: 7.5,
      releaseYear: 2013,
      genres: ['Drama', 'Romance'],
      description: 'Banri Tada yang kehilangan ingatannya memulai hidup baru sebagai mahasiswa hukum di Tokyo dan bertemu Kouko Kaga yang penuh semangat.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx17895-M8yjOyMxHf5X.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/17895.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/17895.jpg',
      episodeInfo: 'SUB · 24 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 17895,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '109020',
      title: 'Yesterday wo Utatte (Sing "Yesterday" for Me)',
      japaneseTitle: 'イエスタデイをうたって',
      rating: 6.7,
      releaseYear: 2020,
      genres: ['Drama', 'Romance', 'Slice of Life'],
      description: 'Rikuo Uozumi yang bekerja paruh waktu setelah lulus kuliah bertemu gadis misterius Haru Nonaka dan teman lamanya Shinako Morinome.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx109020-sRBusiVXbsLH.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/109020-TclHkkKtYgcQ.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/109020-TclHkkKtYgcQ.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 109020,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '21857',
      title: 'Masamune-kun no Revenge',
      japaneseTitle: '政宗くんのリベンジ',
      rating: 6.6,
      releaseYear: 2017,
      genres: ['Comedy', 'Romance', 'Slice of Life'],
      description: 'Masamune Makabe mengubah penampilannya menjadi tampan demi membalas dendam kepada Aki Adagaki yang pernah menolaknya saat kecil.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/nx21857-haPDVD7DKDpg.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21857-k7r362xG7420.png',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21857-k7r362xG7420.png',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 21857,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '157397',
      title: 'Yumemiru Danshi wa Genjitsushugisha',
      japaneseTitle: '夢見る男子は現実主義者',
      rating: 6.5,
      releaseYear: 2023,
      genres: ['Comedy', 'Romance', 'Slice of Life'],
      description: 'Wataru Sajou yang terus mengejar Aika Natsukawa tiba-tiba sadar diri dan mulai menjaga jarak, membuat Aika justru kebingungan.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx157397-L1ZUMTuxf8OK.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/157397-lMf3pt84a0EQ.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/157397-lMf3pt84a0EQ.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 157397,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '105932',
      title: 'Araburu Kisetsu no Otome-domo yo.',
      japaneseTitle: '荒ぶる季節の乙女どもよ。',
      rating: 7.1,
      releaseYear: 2019,
      genres: ['Comedy', 'Drama', 'Romance', 'Slice of Life'],
      description: 'Lima siswi anggota klub sastra SMA menghadapi gejolak masa remaja, cinta, dan persahabatan yang canggung.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx105932-OCI48MaTvGXT.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/105932-7SlYF8up5W7e.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/105932-7SlYF8up5W7e.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 105932,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '118419',
      title: 'Kamisama ni Natta Hi (The Day I Became a God)',
      japaneseTitle: '神様になった日',
      rating: 6.5,
      releaseYear: 2020,
      genres: ['Comedy', 'Drama', 'Romance', 'Sci-Fi', 'Slice of Life'],
      description: 'Di akhir musim panas SMA, Youta Narukami bertemu gadis misterius bernama Hina yang mengaku sebagai dewa maha tahu dan meramalkan dunia akan berakhir dalam 30 hari.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx118419-li8RpQcLgiKK.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/118419-aNKG9YhLhT9h.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/118419-aNKG9YhLhT9h.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 118419,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '18119',
      title: 'Servant x Service',
      japaneseTitle: 'サーバント×サービス',
      rating: 7.3,
      releaseYear: 2013,
      genres: ['Comedy', 'Romance', 'Slice of Life'],
      description: 'Lucy Yamagami mulai bekerja sebagai pegawai negeri di kantor pelayanan warga Hokkaido bersama rekan-rekan kerja yang unik dan penuh tingkah kocak.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx18119-L4l1JsqrzATj.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/18119-E1t5vS9XHovZ.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/18119-E1t5vS9XHovZ.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 18119,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '114232',
      title: 'Higehiro (Hige wo Soru. Soshite Joshikousei wo Hirou.)',
      japaneseTitle: 'ひげを剃る。そして女子高生を拾う。',
      rating: 7.0,
      releaseYear: 2021,
      genres: ['Drama', 'Romance', 'Slice of Life'],
      description: 'Setelah ditolak cintanya, pekerja kantoran Yoshida bertemu siswi SMA bernama Sayu yang kabur dari rumah dan memberinya tempat tinggal sementara.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx114232-2rm50ZD1cQgP.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/114232-lWTVDRDLqAH1.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/114232-lWTVDRDLqAH1.jpg',
      episodeInfo: 'SUB · 13 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 114232,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '98820',
      title: 'Just Because!',
      japaneseTitle: 'Just Because!',
      rating: 7.0,
      releaseYear: 2017,
      genres: ['Drama', 'Romance', 'Slice of Life'],
      description: 'Menjelang kelulusan SMA di musim dingin, kepindahan murid pindahan Eita Izumi mengguncang kembali perasaan teman-teman lamanya.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx98820-EVHeNEUOWkh3.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/98820-K4k7c5Qfnuih.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/98820-K4k7c5Qfnuih.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 98820,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '437',
      title: 'Perfect Blue',
      japaneseTitle: 'PERFECT BLUE',
      rating: 8.5,
      releaseYear: 1998,
      genres: ['Drama', 'Horror', 'Psychological', 'Thriller'],
      description: 'Mima Kirigoe meninggalkan grup idolnya untuk mengejar karier akting, namun hidupnya mulai hancur oleh penguntit misterius dan delusi yang mengaburkan realitas.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx437-69NMlXKFeuse.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/437-3yMVTyN7gl2A.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/437-3yMVTyN7gl2A.jpg',
      episodeInfo: 'SUB · MOVIE',
      statusLabel: 'Tamat',
      aniListId: 437,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '7724',
      title: 'Shiki',
      japaneseTitle: '屍鬼',
      rating: 7.5,
      releaseYear: 2010,
      genres: ['Horror', 'Mystery', 'Supernatural', 'Thriller'],
      description: 'Kematian misterius mulai melanda desa terpencil Sotoba setelah kedatangan keluarga Kirishiki di puri bergaya Eropa.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx7724-NwNnRsI34eDa.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/7724.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/7724.jpg',
      episodeInfo: 'SUB · 22 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 7724,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '101759',
      title: 'Yakusoku no Neverland (The Promised Neverland)',
      japaneseTitle: '約束のネバーランド',
      rating: 8.3,
      releaseYear: 2019,
      genres: ['Drama', 'Fantasy', 'Horror', 'Mystery', 'Psychological', 'Thriller'],
      description: 'Emma, Norman, dan Ray hidup bahagia di Panti Asuhan Grace Field hingga mereka mengetahui rahasia mengerikan di balik dinding panti.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101759-8UR7r9MNVpz2.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101759-MhlCoeqnODso.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101759-MhlCoeqnODso.jpg',
      episodeInfo: 'SUB · 12 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 101759,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '108725',
      title: 'Yakusoku no Neverland Season 2 (The Promised Neverland)',
      japaneseTitle: '約束のネバーランド 2期',
      rating: 5.1,
      releaseYear: 2021,
      genres: ['Action', 'Adventure', 'Drama', 'Fantasy', 'Horror', 'Psychological', 'Thriller'],
      description: 'Setelah berhasil kabur dari Grace Field House, Emma dan anak-anak lainnya harus bertahan hidup di dunia luar yang penuh iblis.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx108725-ZKivuyr4Jtc9.jpg',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/108725-lg940Urvxzfu.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/108725-lg940Urvxzfu.jpg',
      episodeInfo: 'SUB · 11 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 108725,
      hasVideoAvailable: false,
    ),
    AnimeItem(
      id: '98460',
      title: 'DEVILMAN crybaby',
      japaneseTitle: 'DEVILMAN crybaby',
      rating: 7.6,
      releaseYear: 2018,
      genres: ['Action', 'Drama', 'Horror', 'Psychological', 'Supernatural'],
      description: 'Akira Fudo yang berhati lembut bergabung dengan iblis Amon atas ajakan sahabatnya Ryo Asuka untuk melawan kebangkitan para iblis.',
      posterUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx98460-bLtH2c3jd6sV.png',
      backdropUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/98460-PwSHquwVu89n.jpg',
      bannerUrl: 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/98460-PwSHquwVu89n.jpg',
      episodeInfo: 'SUB · 10 EPS (Tamat)',
      statusLabel: 'Tamat',
      aniListId: 98460,
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
      hasVideoAvailable: false,
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
