import '../models/uploaded_anime_video.dart';

/// Repository managing owner-uploaded videos mapped to AniList IDs and seasons.
/// Strictly disallows automatic scraping or grabbing videos from internet.
class OwnerVideoRepository {
  static final OwnerVideoRepository instance = OwnerVideoRepository._internal();

  OwnerVideoRepository._internal() {
    _initDefaultVideos();
  }

  /// Store keyed by "$aniListId-$seasonNumber-$episodeNumber"
  final Map<String, UploadedAnimeVideo> _videos = {};

  String _buildKey(int aniListId, int seasonNumber, int episodeNumber) =>
      '$aniListId-$seasonNumber-$episodeNumber';

  /// Register an owner uploaded video
  void registerVideo(UploadedAnimeVideo video) {
    _videos[_buildKey(video.aniListId, video.seasonNumber, video.episodeNumber)] = video;
  }

  /// Register multiple owner videos
  void registerAll(List<UploadedAnimeVideo> videos) {
    for (final v in videos) {
      registerVideo(v);
    }
  }

  /// Clear all registered videos (useful for test isolation)
  void clear() {
    _videos.clear();
  }

  /// Reset to standard default curated videos
  void resetToDefaults() {
    _videos.clear();
    _initDefaultVideos();
  }

  /// Check if videos are uploaded for an AniList ID (optionally specific season)
  bool hasVideosForAnime(int aniListId, {int? seasonNumber}) {
    if (aniListId <= 0) return false;
    for (final v in _videos.values) {
      if (v.aniListId == aniListId) {
        if (seasonNumber == null || v.seasonNumber == seasonNumber) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get all uploaded videos for an anime, sorted by episode number
  List<UploadedAnimeVideo> getVideosForAnime(int aniListId, {int? seasonNumber}) {
    final list = _videos.values.where((v) {
      if (v.aniListId != aniListId) return false;
      if (seasonNumber != null && v.seasonNumber != seasonNumber) return false;
      return true;
    }).toList();
    list.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    return list;
  }

  /// Get a specific episode video for an AniList ID and season
  UploadedAnimeVideo? getVideo(int aniListId, int seasonNumber, int episodeNumber) {
    return _videos[_buildKey(aniListId, seasonNumber, episodeNumber)];
  }

  void _initDefaultVideos() {
    final now = DateTime(2024, 1, 1);

    // Helper to register standard episodes
    void registerEpisodes({
      required int aniListId,
      required int seasonNumber,
      required int count,
      required String baseUrlPattern,
      required String seriesTitle,
    }) {
      for (int ep = 1; ep <= count; ep++) {
        final epStr = ep.toString().padLeft(2, '0');
        final url = baseUrlPattern.replaceAll('{EP}', epStr);
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: count == 1
              ? '$seriesTitle Full Movie Sub Indo'
              : '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
    }

    // 1. Solo Leveling (AniList ID 151807, Season 1)
    registerEpisodes(
      aniListId: 151807,
      seasonNumber: 1,
      count: 12,
      baseUrlPattern: 'https://archive.org/download/solo-leveling-ep-01/Solo.Leveling.S01E{EP}.mp4',
      seriesTitle: 'Solo Leveling',
    );

    // 2. Tokyo Revengers Season 1 (AniList ID 120120)
    registerEpisodes(
      aniListId: 120120,
      seasonNumber: 1,
      count: 24,
      baseUrlPattern: 'https://archive.org/download/tokyo-revengers-ep-01/Tokyo.Revengers.S01E{EP}.mp4',
      seriesTitle: 'Tokyo Revengers S1',
    );

    // 3. Tokyo Revengers Season 2 - Christmas Showdown (AniList ID 142853)
    registerEpisodes(
      aniListId: 142853,
      seasonNumber: 2,
      count: 13,
      baseUrlPattern: 'https://archive.org/download/tokyo-revengers-s2-ep-01/tokyo-revengers-s2-ep-{EP}.mp4',
      seriesTitle: 'Tokyo Revengers S2',
    );

    // 4. Tokyo Revengers Season 3 - Tenjiku-hen (AniList ID 163539)
    registerEpisodes(
      aniListId: 163539,
      seasonNumber: 3,
      count: 13,
      baseUrlPattern: 'https://archive.org/download/tokyo-revengers-s3-ep-01/tokyo-revengers-s3-ep-{EP}.mp4',
      seriesTitle: 'Tokyo Revengers S3',
    );

    // NOTE: Tokyo Revengers Season 4 (AniList ID 178945) has NO uploaded videos.
    // It will strictly show "Belum tersedia" and never fallback to S1, S2, or S3.

    // 5. Demon Slayer Season 1 (AniList ID 101922)
    registerEpisodes(
      aniListId: 101922,
      seasonNumber: 1,
      count: 26,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      seriesTitle: 'Demon Slayer S1',
    );

    // 6. Demon Slayer Season 2 (AniList ID 142329)
    registerEpisodes(
      aniListId: 142329,
      seasonNumber: 2,
      count: 11,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
      seriesTitle: 'Demon Slayer S2',
    );

    // 7. Demon Slayer Season 3 (AniList ID 145139)
    registerEpisodes(
      aniListId: 145139,
      seasonNumber: 3,
      count: 11,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
      seriesTitle: 'Demon Slayer S3',
    );

    // 8. Attack on Titan Season 1 (AniList ID 16498)
    registerEpisodes(
      aniListId: 16498,
      seasonNumber: 1,
      count: 25,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      seriesTitle: 'Attack on Titan S1',
    );

    // 9. Death Note (AniList ID 1535)
    registerEpisodes(
      aniListId: 1535,
      seasonNumber: 1,
      count: 37,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackSeeTheWorld.mp4',
      seriesTitle: 'Death Note',
    );

    // 10. Jujutsu Kaisen Season 1 (AniList ID 113415)
    registerEpisodes(
      aniListId: 113415,
      seasonNumber: 1,
      count: 24,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      seriesTitle: 'Jujutsu Kaisen',
    );

    // 11. Chainsaw Man (AniList ID 127720)
    registerEpisodes(
      aniListId: 127720,
      seasonNumber: 1,
      count: 12,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
      seriesTitle: 'Chainsaw Man',
    );

    // 12. Dandadan (AniList ID 166240)
    registerEpisodes(
      aniListId: 166240,
      seasonNumber: 1,
      count: 12,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
      seriesTitle: 'Dandadan',
    );

    // 13. Frieren: Beyond Journey's End (AniList ID 154587)
    registerEpisodes(
      aniListId: 154587,
      seasonNumber: 1,
      count: 28,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      seriesTitle: 'Frieren',
    );

    // 14. Spy x Family (AniList ID 140960)
    registerEpisodes(
      aniListId: 140960,
      seasonNumber: 1,
      count: 12,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      seriesTitle: 'Spy x Family',
    );

    // 15. Hunter x Hunter (AniList ID 11061)
    registerEpisodes(
      aniListId: 11061,
      seasonNumber: 1,
      count: 148,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      seriesTitle: 'Hunter x Hunter',
    );

    // 16. Fullmetal Alchemist: Brotherhood (AniList ID 5114)
    registerEpisodes(
      aniListId: 5114,
      seasonNumber: 1,
      count: 64,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      seriesTitle: 'Fullmetal Alchemist: Brotherhood',
    );

    // 17. One Piece (AniList ID 21)
    registerEpisodes(
      aniListId: 21,
      seasonNumber: 1,
      count: 1000,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      seriesTitle: 'One Piece',
    );

    // 18. Naruto (AniList ID 20)
    registerEpisodes(
      aniListId: 20,
      seasonNumber: 1,
      count: 220,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
      seriesTitle: 'Naruto',
    );

    // 19. Bleach (AniList ID 269)
    registerEpisodes(
      aniListId: 269,
      seasonNumber: 1,
      count: 366,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
      seriesTitle: 'Bleach',
    );

    // 20. Steins;Gate (AniList ID 9253)
    registerEpisodes(
      aniListId: 9253,
      seasonNumber: 1,
      count: 24,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      seriesTitle: 'Steins;Gate',
    );

    // 21. Kimi no Na wa (AniList ID 21827)
    registerEpisodes(
      aniListId: 21827,
      seasonNumber: 1,
      count: 1,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      seriesTitle: 'Kimi no Na wa',
    );

    // 22. Koe no Katachi (AniList ID 20954)
    registerEpisodes(
      aniListId: 20954,
      seasonNumber: 1,
      count: 1,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
      seriesTitle: 'Koe no Katachi',
    );

    // 23. Shigatsu wa Kimi no Uso (AniList ID 20665)
    registerEpisodes(
      aniListId: 20665,
      seasonNumber: 1,
      count: 22,
      baseUrlPattern: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
      seriesTitle: 'Shigatsu wa Kimi no Uso',
    );

    // 24. One Punch Man Season 1 (AniList ID 21087)
    final opmS1Titles = [
      'Pria Terkuat (The Strongest Man)',
      'Siklon Soliter (The Lone Cyborg)',
      'Ilmuwan Obsesif (The Obsessive Scientist)',
      'Ninja Modern (The Modern Ninja)',
      'Mentor Utama (The Ultimate Mentor)',
      'Kota Menakutkan (The Terrifying City)',
      'Murid Terbaik (The Ultimate Disciple)',
      'Raja Laut Dalam (The Deep Sea King)',
      'Keadilan yang Pantang Menyerah (Unyielding Justice)',
      'Bahaya yang Tak Tertandingi (Unmatched Peril)',
      'Dominator Alam Semesta (The Dominator of the Universe)',
      'Pahlawan Terkuat (The Strongest Hero)',
    ];
    for (int i = 0; i < opmS1Titles.length; i++) {
      final ep = i + 1;
      final epStr = ep.toString().padLeft(2, '0');
      registerVideo(UploadedAnimeVideo(
        aniListId: 21087,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Episode $ep - ${opmS1Titles[i]} Sub Indo',
        videoUrl: 'https://archive.org/download/one-punch-man-s1-ep-01/One.Punch.Man.S01E$epStr.mp4',
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 25. One Punch Man Season 2 (AniList ID 102194 & 97668)
    final opmS2Titles = [
      'Kembalinya Sang Pahlawan (Return of the Hero)',
      'Monster Manusia (The Human Monster)',
      'Perburuan Dimulai (The Hunt Begins)',
      'Kelelawar Logam (The Metal Bat)',
      'Turnamen Seni Bela Diri (The Martial Arts Tournament)',
      'Pemberontakan Monster (The Monster Uprising)',
      'Pahlawan Kelas S (The Class S Heroes)',
      'Perlawanan Orang Kuat (The Resistance of the Strong)',
      'Kekhawatiran Orang Kuat (The Troubles of the Strongest)',
      'Pengepungan Keadilan (Justice Under Siege)',
      'Kebanggaan Masing-Masing (The Variety of Pride)',
      'Pembersihan Murid (The Cleaning of the Disciple)',
    ];
    for (final s2Id in [102194, 97668]) {
      for (int i = 0; i < opmS2Titles.length; i++) {
        final ep = i + 1;
        final epStr = ep.toString().padLeft(2, '0');
        registerVideo(UploadedAnimeVideo(
          aniListId: s2Id,
          seasonNumber: 2,
          episodeNumber: ep,
          episodeTitle: 'Episode $ep - ${opmS2Titles[i]} Sub Indo',
          videoUrl: 'https://archive.org/download/one-punch-man-s2-ep-01/One.Punch.Man.S02E$epStr.mp4',
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
    }
  }
}

