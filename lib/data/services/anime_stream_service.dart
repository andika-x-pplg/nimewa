import 'anime_api_client.dart';
import 'anime_stream_resolver.dart';
import '../models/anime_detail.dart';
import '../models/anime_item.dart';
import '../models/episode_item.dart';

/// Service providing anime details, episode lists, and streaming endpoints.
/// Supports both online Sub Indo endpoints and built-in fallback catalogs.
class AnimeStreamService {
  final Duration networkDelay;
  final AnimeApiClient apiClient;

  const AnimeStreamService({
    this.networkDelay = const Duration(milliseconds: 50),
    this.apiClient = const AnimeApiClient(),
  });

  /// Fetches spotlight anime (10 items) for home hero carousel.
  Future<List<AnimeItem>> getSpotlightAnime() async {
    if (networkDelay > Duration.zero) {
      await Future.delayed(networkDelay);
    }
    return apiClient.fetchTrendingAnime(limit: 10);
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

    final cleanQuery = query?.trim();
    if (cleanQuery != null && cleanQuery.isNotEmpty) {
      return apiClient.searchAnime(cleanQuery, limit: limit, offset: offset);
    }

    if (genre != null && genre != 'Semua' && genre.isNotEmpty) {
      return apiClient.fetchAnimeByCategory(genre, limit: limit, offset: offset);
    }

    switch (filter) {
      case 'latest':
        return apiClient.fetchLatestAnime(limit: limit, offset: offset);
      case 'top_rated':
        return apiClient.fetchTopRatedAnime(limit: limit, offset: offset);
      case 'popular':
      default:
        return apiClient.fetchTrendingAnime(limit: limit, offset: offset);
    }
  }

  /// Fetches detailed metadata and all available episodes for an anime.
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    if (networkDelay > Duration.zero) {
      await Future.delayed(networkDelay);
    }

    final cleanId = animeId.toLowerCase().trim();

    if (_curatedDetails.containsKey(cleanId)) {
      return _curatedDetails[cleanId]!;
    }

    // Map known API ID aliases to curated details
    if (cleanId == 'tokyo-revengers-s4' || cleanId == '48960' || cleanId == '42249') {
      return _curatedDetails['tokyo-revengers-s4']!;
    }
    if (cleanId == '41370' || cleanId == 'kny') {
      return _curatedDetails['demon-slayer']!;
    }
    if (cleanId == '7442' || cleanId == 'aot') {
      return _curatedDetails['attack-on-titan']!;
    }
    if (cleanId == '1376') {
      return _curatedDetails['death-note']!;
    }
    if (cleanId == '6448' || cleanId == 'hxh') {
      return _curatedDetails['hunter-x-hunter']!;
    }
    if (cleanId == '3936' || cleanId == 'fma') {
      return _curatedDetails['fullmetal-alchemist']!;
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
    'solo-leveling-s2': AnimeDetail(
      id: 'solo-leveling-s2',
      title: 'Solo Leveling: Arise from the Shadow',
      japaneseTitle: '俺だけレベルアップな件',
      rating: 8.8,
      releaseYear: 2025,
      genres: const ['Action', 'Fantasy', 'Supernatural'],
      synopsis: 'Setelah pertempuran sengit di Pulau Jeju, Sung Jinwoo semakin mendekati kebenaran tentang Monarch dan Rulers. Sebagai Shadow Monarch, kekuatannya kini melampaui batas manusia biasa dalam membela bumi dari kehancuran.',
      posterUrl: 'https://avac.moe/img/anime/large/58567.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/58567.jpg',
      status: 'Ongoing',
      studio: 'A-1 Pictures',
      totalEpisodes: 12,
      episodes: List.generate(
        8,
        (index) => EpisodeItem(
          id: 'solo-leveling-s2-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Kebangkitan Bayangan',
          releaseDate: '2025-02-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'solo-leveling-s2',
            animeTitle: 'Solo Leveling',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'tokyo-revengers-s4': AnimeDetail(
      id: 'tokyo-revengers-s4',
      title: 'Tokyo Revengers: Season 4',
      japaneseTitle: '東京リベンジャーズ',
      rating: 7.8,
      releaseYear: 2025,
      genres: const ['Action', 'Drama', 'Delinquents', 'Supernatural'],
      synopsis: 'Pasca pertempuran berdarah Kanto Incident dan Arc Tenjiku, Takemichi Hanagaki kembali menghadapi labirin takdir baru. Tekadnya untuk menyelamatkan Mikey dan teman-temannya kembali diuji dalam skala yang lebih berbahaya.',
      posterUrl: 'https://avac.moe/img/anime/large/42249.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/42249.jpg',
      status: 'Ongoing',
      studio: 'LIDENFILMS',
      totalEpisodes: 12,
      episodes: List.generate(
        6,
        (index) => EpisodeItem(
          id: 'tokyo-revengers-s4-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Takdir Tak Terelakkan',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'tokyo-revengers-s4',
            animeTitle: 'Tokyo Revengers Season 4',
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
    'hunter-x-hunter': AnimeDetail(
      id: 'hunter-x-hunter',
      title: 'Hunter x Hunter (2011)',
      japaneseTitle: 'HUNTER×HUNTER',
      rating: 9.0,
      releaseYear: 2011,
      genres: const ['Action', 'Adventure', 'Fantasy'],
      synopsis: 'Gon Freecss memulai petualangan berbahaya untuk menjadi Hunter berlisensi dan menemukan keberadaan ayahnya, Ging.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/6448/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/6448/large.jpg',
      status: 'Tamat',
      studio: 'Madhouse',
      totalEpisodes: 148,
      episodes: List.generate(
        148,
        (index) => EpisodeItem(
          id: 'hunter-x-hunter-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} Sub Indo',
          releaseDate: '2011-10-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'hunter-x-hunter',
            animeTitle: 'Hunter x Hunter',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'fullmetal-alchemist': AnimeDetail(
      id: 'fullmetal-alchemist',
      title: 'Fullmetal Alchemist: Brotherhood',
      japaneseTitle: '鋼の錬金術師 FULLMETAL ALCHEMIST',
      rating: 9.1,
      releaseYear: 2009,
      genres: const ['Action', 'Adventure', 'Drama', 'Fantasy'],
      synopsis: 'Edward dan Alphonse Elric mencari Batu Bertuah untuk memulihkan tubuh mereka yang hilang akibat transmutasi manusia terlarang.',
      posterUrl: 'https://media.kitsu.app/anime/poster_images/3936/large.jpg',
      backdropUrl: 'https://media.kitsu.app/anime/poster_images/3936/large.jpg',
      status: 'Tamat',
      studio: 'Bones',
      totalEpisodes: 64,
      episodes: List.generate(
        64,
        (index) => EpisodeItem(
          id: 'fullmetal-alchemist-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} Sub Indo',
          releaseDate: '2009-04-${(index + 1).toString().padLeft(2, '0')}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'fullmetal-alchemist',
            animeTitle: 'Fullmetal Alchemist',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'frieren-s2': AnimeDetail(
      id: 'frieren-s2',
      title: 'Sousou no Frieren Season 2',
      japaneseTitle: '葬送のフリーレン',
      rating: 9.3,
      releaseYear: 2025,
      genres: const ['Fantasy', 'Adventure', 'Drama'],
      synopsis: 'Setelah lulus ujian penyihir kelas satu, Frieren bersama Fern dan Stark melanjutkan perjalanan mereka menuju wilayah utara demi mencapai Ende, tempat peristirahatan para jiwa.',
      posterUrl: 'https://avac.moe/img/anime/large/52991.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/52991.jpg',
      status: 'Ongoing',
      studio: 'Madhouse',
      totalEpisodes: 24,
      episodes: List.generate(
        6,
        (index) => EpisodeItem(
          id: 'frieren-s2-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Perjalanan ke Utara',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'frieren-s2',
            animeTitle: 'Sousou no Frieren',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'hotaru-no-yomeiri': AnimeDetail(
      id: 'hotaru-no-yomeiri',
      title: 'Hotaru no Yomeiri (Firefly Wedding)',
      japaneseTitle: 'ホタルの嫁入り',
      rating: 8.2,
      releaseYear: 2025,
      genres: const ['Romance', 'Historical', 'Suspense', 'Drama'],
      synopsis: 'Satoko, seorang putri bangsawan yang hidupnya terancam, mengajukan lamaran pernikahan tak terduga kepada Shinpei, seorang pembunuh bayaran kejam. Dimulailah ikatan cinta berbahaya penuh intrik di era Meiji.',
      posterUrl: 'https://avac.moe/img/anime/large/63293.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/63293.jpg',
      status: 'Ongoing',
      studio: 'CloverWorks',
      totalEpisodes: 12,
      episodes: List.generate(
        6,
        (index) => EpisodeItem(
          id: 'hotaru-no-yomeiri-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Janji di Balik Bilah',
          releaseDate: '2025-02-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'hotaru-no-yomeiri',
            animeTitle: 'Hotaru no Yomeiri',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'black-clover-s2': AnimeDetail(
      id: 'black-clover-s2',
      title: 'Black Clover Season 2',
      japaneseTitle: 'ブラッククローバー',
      rating: 8.0,
      releaseYear: 2025,
      genres: const ['Action', 'Fantasy', 'Magic', 'Shounen'],
      synopsis: 'Asta and the Black Bulls push past their limits as deeper conspiracies and formidable adversaries threaten the peace of the Clover Kingdom.',
      posterUrl: 'https://avac.moe/img/anime/large/34572.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/34572.jpg',
      status: 'Ongoing',
      studio: 'Studio Pierrot',
      totalEpisodes: 12,
      episodes: List.generate(
        6,
        (index) => EpisodeItem(
          id: 'black-clover-s2-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Melampaui Batas',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'black-clover-s2',
            animeTitle: 'Black Clover',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'chii-fuyo': AnimeDetail(
      id: 'chii-fuyo',
      title: 'Chii Fuyo (Tsuihou Sareta Cheat Fuyo Majutsushi)',
      japaneseTitle: '追放されたチート付与魔術師は気ままなセカンドライフを謳歌する',
      rating: 7.6,
      releaseYear: 2025,
      genres: const ['Fantasy', 'Action', 'Adventure', 'Comedy'],
      synopsis: 'Unfairly expelled from his adventurer party after secretly bestowing massive buffs on them, enchanter Rain starts an unfettered second life with true allies.',
      posterUrl: 'https://avac.moe/img/anime/large/63431.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/63431.jpg',
      status: 'Ongoing',
      studio: 'Drive',
      totalEpisodes: 12,
      episodes: List.generate(
        6,
        (index) => EpisodeItem(
          id: 'chii-fuyo-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Kehidupan Baru Sang Penyihir Buff',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'chii-fuyo',
            animeTitle: 'Chii Fuyo',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
    'tensei-juukishi': AnimeDetail(
      id: 'tensei-juukishi',
      title: 'Tsuihou sareta Tensei juukishi wa game chishiki de musou suru',
      japaneseTitle: '追放された転生重騎士はゲーム知識で無双する',
      rating: 7.7,
      releaseYear: 2025,
      genres: const ['Fantasy', 'Action', 'Isekai', 'Strategy'],
      synopsis: 'Reborn as Elma and banished by his aristocratic family for acquiring the "incompetent" Heavy Knight class, he leverages meta game knowledge to prove the class is invincible.',
      posterUrl: 'https://avac.moe/img/anime/large/59741.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/59741.jpg',
      status: 'Ongoing',
      studio: 'Felix Film',
      totalEpisodes: 12,
      episodes: List.generate(
        6,
        (index) => EpisodeItem(
          id: 'tensei-juukishi-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Rahasia Heavy Knight',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: AnimeStreamResolver.resolveStreamUrl(
            animeId: 'tensei-juukishi',
            animeTitle: 'Tensei juukishi',
            server: 'Server 1 (Fast HD)',
            episodeNumber: index + 1,
          ),
        ),
      ),
    ),
  };
}
