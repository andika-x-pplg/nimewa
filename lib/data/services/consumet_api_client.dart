import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Represents a single search result from Consumet API.
class ConsumetAnimeResult {
  final String id;
  final String title;
  final String? url;
  final String? image;
  final String? releaseDate;
  final String? subOrDub;

  const ConsumetAnimeResult({
    required this.id,
    required this.title,
    this.url,
    this.image,
    this.releaseDate,
    this.subOrDub,
  });

  factory ConsumetAnimeResult.fromJson(Map<String, dynamic> json) {
    return ConsumetAnimeResult(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString(),
      image: json['image']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
      subOrDub: json['subOrDub']?.toString(),
    );
  }
}

/// Represents an episode in Consumet's anime detail.
class ConsumetEpisode {
  final String id;
  final int number;
  final String? title;
  final String? url;

  const ConsumetEpisode({
    required this.id,
    required this.number,
    this.title,
    this.url,
  });

  factory ConsumetEpisode.fromJson(Map<String, dynamic> json) {
    final rawNumber = json['number'];
    final number = rawNumber is num
        ? rawNumber.toInt()
        : int.tryParse(rawNumber?.toString() ?? '1') ?? 1;

    return ConsumetEpisode(
      id: json['id']?.toString() ?? '',
      number: number,
      title: json['title']?.toString(),
      url: json['url']?.toString(),
    );
  }
}

/// Represents video stream source returned by Consumet.
class ConsumetStreamSource {
  final String url;
  final bool isM3U8;
  final String quality;

  const ConsumetStreamSource({
    required this.url,
    this.isM3U8 = false,
    this.quality = 'default',
  });

  factory ConsumetStreamSource.fromJson(Map<String, dynamic> json) {
    return ConsumetStreamSource(
      url: json['url']?.toString() ?? '',
      isM3U8: json['isM3U8'] == true ||
          (json['url']?.toString().contains('.m3u8') ?? false),
      quality: json['quality']?.toString() ?? 'default',
    );
  }
}

/// Client for interacting with Consumet open-source Anime API instances.
/// Implements dual-mirror fallback and short timeouts for smooth UX.
class ConsumetApiClient {
  /// Community and self-hosted mirror instances.
  static const List<String> defaultBaseUrls = [
    'https://api.consumet.org',
    'https://api-consumet.vercel.app',
    'https://consumet.up.railway.app',
  ];

  final List<String> baseUrls;
  final Duration timeout;
  final HttpClient _client;

  ConsumetApiClient({
    List<String>? baseUrls,
    this.timeout = const Duration(seconds: 4),
    HttpClient? client,
  })  : baseUrls = baseUrls ?? defaultBaseUrls,
        _client = client ?? HttpClient() {
    _client.connectionTimeout = timeout;
  }

  /// Searches for anime across the specified provider (default: 'gogoanime').
  Future<List<ConsumetAnimeResult>> searchAnime(
    String query, {
    String provider = 'gogoanime',
  }) async {
    final encodedQuery = Uri.encodeComponent(query.trim());
    for (final base in baseUrls) {
      final endpoint = '$base/anime/$provider/$encodedQuery';
      try {
        final data = await _getJson(endpoint);
        final results = data['results'];
        if (results is List) {
          return results
              .whereType<Map<String, dynamic>>()
              .map(ConsumetAnimeResult.fromJson)
              .toList();
        }
      } catch (_) {
        // Try next mirror
      }
    }
    return [];
  }

  /// Retrieves anime information and episode list.
  Future<List<ConsumetEpisode>> getEpisodes(
    String animeId, {
    String provider = 'gogoanime',
  }) async {
    final encodedId = Uri.encodeComponent(animeId.trim());
    for (final base in baseUrls) {
      final endpoint = '$base/anime/$provider/info/$encodedId';
      try {
        final data = await _getJson(endpoint);
        final eps = data['episodes'];
        if (eps is List) {
          return eps
              .whereType<Map<String, dynamic>>()
              .map(ConsumetEpisode.fromJson)
              .toList();
        }
      } catch (_) {
        // Try next mirror
      }
    }
    return [];
  }

  /// Retrieves video stream sources for a given episode ID.
  Future<List<ConsumetStreamSource>> getEpisodeStreams(
    String episodeId, {
    String provider = 'gogoanime',
  }) async {
    final encodedEp = Uri.encodeComponent(episodeId.trim());
    for (final base in baseUrls) {
      final endpoint = '$base/anime/$provider/watch/$encodedEp';
      try {
        final data = await _getJson(endpoint);
        final sources = data['sources'];
        if (sources is List) {
          return sources
              .whereType<Map<String, dynamic>>()
              .map(ConsumetStreamSource.fromJson)
              .toList();
        }
      } catch (_) {
        // Try next mirror
      }
    }
    return [];
  }

  /// High-level resolver: finds best stream URL for an anime title and episode number.
  /// Returns null if not found or if servers are unresponsive within timeout.
  Future<String?> resolveLatestStream({
    required String title,
    required int episodeNumber,
    int? seasonNumber,
    String provider = 'gogoanime',
  }) async {
    try {
      // Build search query (e.g. "Tokyo Revengers Season 4" or "Tokyo Revengers")
      String query = title;
      if (seasonNumber != null && seasonNumber > 1 && !title.toLowerCase().contains('season')) {
        query = '$title Season $seasonNumber';
      }

      final searchResults = await searchAnime(query, provider: provider);
      if (searchResults.isEmpty) return null;

      // Select top result
      final topAnime = searchResults.first;
      final episodes = await getEpisodes(topAnime.id, provider: provider);
      if (episodes.isEmpty) return null;

      // Find episode with matching number
      ConsumetEpisode? targetEpisode;
      for (final ep in episodes) {
        if (ep.number == episodeNumber) {
          targetEpisode = ep;
          break;
        }
      }
      targetEpisode ??= episodes.first;

      final streams = await getEpisodeStreams(targetEpisode.id, provider: provider);
      if (streams.isEmpty) return null;

      // Prefer 720p or 1080p or default
      final bestStream = streams.firstWhere(
        (s) => s.quality == '720p' || s.quality == '1080p' || s.quality == 'default',
        orElse: () => streams.first,
      );

      return bestStream.url.isNotEmpty ? bestStream.url : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final uri = Uri.parse(url);
    final req = await _client.getUrl(uri).timeout(timeout);
    req.headers.set('User-Agent', 'NimevaAnime/1.0 (Mobile Client)');
    req.headers.set('Accept', 'application/json');

    final resp = await req.close().timeout(timeout);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = await resp.transform(utf8.decoder).join().timeout(timeout);
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    throw HttpException('Failed HTTP request: ${resp.statusCode}');
  }
}

