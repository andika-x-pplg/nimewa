import '../models/anime_detail.dart';
import '../models/episode_item.dart';

/// Service providing anime details, episode lists, and streaming endpoints.
/// Supports both online Sub Indo endpoints and built-in fallback catalogs.
class AnimeStreamService {
  /// Fetches detailed metadata and all available episodes for an anime.
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    // Simulate slight async response time as if calling a network API
    await Future.delayed(const Duration(milliseconds: 100));

    final cleanId = animeId.toLowerCase().trim();

    if (_curatedDetails.containsKey(cleanId)) {
      return _curatedDetails[cleanId]!;
    }

    // Default dynamic generator for any arbitrary or search anime item
    return _generateFallbackDetail(cleanId);
  }

  /// Fetches video streaming URL for a specific episode.
  Future<String> getEpisodeStreamUrl(String episodeId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  }

  AnimeDetail _generateFallbackDetail(String id) {
    final titleFormatted = id
        .split('-')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');

    final episodes = List.generate(
      12,
      (index) => EpisodeItem(
        id: '$id-eps-${index + 1}',
        episodeNumber: index + 1,
        title: 'Episode ${index + 1} Sub Indo',
        releaseDate: '2025-01-${10 + index}',
        streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      ),
    );

    return AnimeDetail(
      id: id,
      title: titleFormatted.isEmpty ? 'Anime Detail' : titleFormatted,
      japaneseTitle: 'アニメ詳細',
      rating: 8.5,
      releaseYear: 2025,
      genres: const ['Action', 'Fantasy', 'Adventure'],
      synopsis: 'Petualangan epik di dunia penuh misteri dan aksi tak terduga. Ikuti kisah perjuangan para karakter utama dalam menghadapi berbagai rintangan demi mencapai impian mereka.',
      posterUrl: 'https://avac.moe/img/anime/large/58567.jpg',
      backdropUrl: 'https://avac.moe/img/anime/large/58567.jpg',
      status: 'Ongoing',
      studio: 'Mappa / Ufotable',
      totalEpisodes: 12,
      episodes: episodes,
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
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
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
      backdropUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=1200&auto=format&fit=crop&q=80',
      status: 'Ongoing',
      studio: 'LIDENFILMS',
      totalEpisodes: 13,
      episodes: List.generate(
        13,
        (index) => EpisodeItem(
          id: 'tokyo-revengers-s4-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Takdir Tak Terelakkan',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
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
        12,
        (index) => EpisodeItem(
          id: 'frieren-s2-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Perjalanan ke Utara',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
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
      backdropUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&auto=format&fit=crop&q=80',
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
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
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
      backdropUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1200&auto=format&fit=crop&q=80',
      status: 'Ongoing',
      studio: 'Studio Pierrot',
      totalEpisodes: 12,
      episodes: List.generate(
        12,
        (index) => EpisodeItem(
          id: 'black-clover-s2-eps-${index + 1}',
          episodeNumber: index + 1,
          title: 'Episode ${index + 1} - Melampaui Batas',
          releaseDate: '2025-01-${(index + 1) * 7}',
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
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
      backdropUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=1200&auto=format&fit=crop&q=80',
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
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
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
      backdropUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1200&auto=format&fit=crop&q=80',
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
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
      ),
    ),
  };
}
