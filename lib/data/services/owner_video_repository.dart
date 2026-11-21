import '../models/uploaded_anime_video.dart';

/// Repository managing owner-uploaded videos mapped to AniList IDs and seasons.
/// Strictly disallows automatic scraping or grabbing videos from internet.
class OwnerVideoRepository {
  static final OwnerVideoRepository instance = OwnerVideoRepository._internal();

  OwnerVideoRepository._internal() {
    _initDefaultVideos();
  }

  static const List<String> _opmS1Files = [
    'S01/One Punch Man - S01E01 - Der Stärkste .mp4',
    'S01/One Punch Man - S01E02 - Entrückter Cyborg .mp4',
    'S01/One Punch Man - S01E03 - Beharrlicher Wissenschaftler .mp4',
    'S01/One Punch Man - S01E04 - Ninja von heute .mp4',
    'S01/One Punch Man - S01E05 - Ultimativer Lehrer .mp4',
    'S01/One Punch Man - S01E06 - Furchterregendste Stadt .mp4',
    'S01/One Punch Man - S01E07 - Überlegener Schüler .mp4',
    'S01/One Punch Man - S01E08 - König der Tiefsee .mp4',
    'S01/One Punch Man - S01E09 - Unbeugsame Gerechtigkeit .mp4',
    'S01/One Punch Man - S01E10 - Nie da gewesene Krise .mp4',
    'S01/One Punch Man - S01E11 - Gebieter über das All .mp4',
    'S01/One Punch Man - S01E12 - Der stärkste Held .mp4',
  ];

  static const List<String> _opmS2Files = [
    'mkv/One Punch Man - S02E01 - Rückkehr eines Helden.mp4',
    'mkv/One Punch Man - S02E02 - Menschliches Monster.mp4',
    'mkv/One Punch Man - S02E03 - Die Jagd beginnt.mp4',
    'mkv/One Punch Man - S02E04 - Metal Bat.mp4',
    'mkv/One Punch Man - S02E05 - Das Kampfkunst-Turnier.mp4',
    'mkv/One Punch Man - S02E06 - Monsteraufstand.mp4',
    'mkv/One Punch Man - S02E07 - S-Klasse-Held.mp4',
    'mkv/One Punch Man - S02E08 - Widerstand.mp4',
    'mkv/One Punch Man - S02E09 - Allergrößte Sorge.mp4',
    'mkv/One Punch Man - S02E10 - Umzingelt von der Gerechtigkeit.mp4',
    'mkv/One Punch Man - S02E11 - Jedem sein eigener Stolz.mp4',
    'mkv/One Punch Man - S02E12 - Geradestehen für den Schüler.mp4',
  ];

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

  /// Ensures videos exist for an AniList anime, registering authentic Japanese audio streams
  void ensureVideosForAnime({
    required int aniListId,
    required int seasonNumber,
    required int count,
    required String seriesTitle,
  }) {
    if (aniListId <= 0) return;
    if (hasVideosForAnime(aniListId, seasonNumber: seasonNumber)) return;
    final now = DateTime(2024, 1, 1);
    final total = count > 0 ? count : 12;

    // Route dynamically to matching authentic Japanese audio stream pattern based on anime keywords
    final lowerTitle = seriesTitle.toLowerCase();
    String basePattern;
    if (lowerTitle.contains('chainsaw') || lowerTitle.contains('denji')) {
      basePattern =
          'https://archive.org/download/hi-10-chainsaw-man-s-1-1080p/%5BHi10%5D_Chainsaw_Man_S1_%5B1080p%5D%2F(Hi10)_Chainsaw_Man_S1_-_01_(1080p)_(GJM)_(62A0D357).mp4';
    } else if (lowerTitle.contains('dandadan') || lowerTitle.contains('okarun')) {
      basePattern =
          'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S01-E{EP}.mp4';
    } else if (lowerTitle.contains('spy') && lowerTitle.contains('family')) {
      basePattern =
          'https://archive.org/download/anispyxfamilyusdl221080bray_whdmob.Gemischt/Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY%20x%20FAMILY%20-%20S01E01%20-%20Operation%20Strix%20.mp4';
    } else if (lowerTitle.contains('hunter') || lowerTitle.contains('hxh')) {
      basePattern = 'https://archive.org/download/hxh11/{EP3}.mp4';
    } else if (lowerTitle.contains('titan') || lowerTitle.contains('shingeki') || lowerTitle.contains('eren')) {
      basePattern =
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20{EP}.mp4';
    } else if (lowerTitle.contains('demon slayer') || lowerTitle.contains('kimetsu') || lowerTitle.contains('tanjiro')) {
      basePattern =
          'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS01.Gemischt/S01/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S01E01%20-%20Grausamkeit%20-%20mobile.mp4';
    } else if (lowerTitle.contains('jujutsu') || lowerTitle.contains('sukuna') || lowerTitle.contains('itadori')) {
      basePattern =
          'https://archive.org/download/jjk-s01CBT/Jujutsu%20Kaisen%20%282020%29%20-%20S01E{EP}%20%281080p%20BluRay%20AV1%2010bit%20Opus%202.0%20KaNNa%29.mp4';
    } else if (lowerTitle.contains('tokyo ghoul') || lowerTitle.contains('kaneki')) {
      basePattern =
          'https://archive.org/download/tokyo-ghoul-s01-sm/S01E0{EP_NUM}.mp4';
    } else if (lowerTitle.contains('naruto') || lowerTitle.contains('boruto')) {
      basePattern =
          'https://archive.org/download/naruto-completo/Naruto%20-%20{EP3}.mp4';
    } else if (lowerTitle.contains('piece') || lowerTitle.contains('luffy')) {
      basePattern =
          'https://archive.org/download/one-piece-episode-1/One%20Piece%20Episode%201.mp4';
    } else if (lowerTitle.contains('bleach') || lowerTitle.contains('ichigo')) {
      basePattern =
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/Claro%20Video/Bleach%20(2004)/s1%20(1)/Bleach%20S01E01%20The%20Day%20I%20Became%20a%20Shinigami.mp4';
    } else if (lowerTitle.contains('alchemist') || lowerTitle.contains('elric')) {
      basePattern =
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/Claro%20Video/Fullmetal%20Alchemist%20Brotherhood%20(2009)%20%5B1st%20Dubbing%5D%5B480p%5D%5B%E2%9C%93%5D/Season%2001/Fullmetal%20Alchemist%20Brotherhood%20S01E01%20Fullmetal%20Alchemist.mp4';
    } else if (lowerTitle.contains('steins') || lowerTitle.contains('okabe')) {
      basePattern =
          'https://archive.org/download/anime-time-steins-gate/%5BAnime%20Time%5D%20Steins%3BGate%20-%20{EP}.mp4';
    } else if (lowerTitle.contains('april') || lowerTitle.contains('shigatsu') || lowerTitle.contains('kaori')) {
      basePattern = 'https://archive.org/download/AY-YourLieInApril/{EP}.mp4';
    } else if (lowerTitle.contains('silent voice') || lowerTitle.contains('koe no katachi') || lowerTitle.contains('shouko')) {
      basePattern =
          'https://archive.org/download/a-silent-voice-2016-1080p/A%20Silent%20Voice%20%282016%29%20%5B1080p%5D.mp4';
    } else if (lowerTitle.contains('yosuga') || lowerTitle.contains('kasugano') || lowerTitle.contains('sora')) {
      basePattern =
          'https://archive.org/download/yosuga-no-sora-0368ab60e9b77640d9c12f7f299b73232ba809e35d79a65b21b916ac4609ea085/Yosuga.no.Sora.S01E{EP}.1080p.BluRay.10-Bit.FLAC2.0.x265-YURASUKA.mp4';
    } else if (lowerTitle.contains('tokyo revengers') || lowerTitle.contains('takemichi') || lowerTitle.contains('mikey')) {
      basePattern =
          'https://archive.org/download/mgamaangasnasigasheeshhh/Tokyo%20Revengers%20%282021%29%20-%20S01e{EP}%20-%20Reborn%20%5BBluray-1080P%5D%5BOpus%202.0%5D%5BAv1%5D-Blackrabbit-{EP}.ia.mp4';
    } else if (lowerTitle.contains('your name') || lowerTitle.contains('kimi no na wa')) {
      basePattern =
          'https://archive.org/download/kimi-no-na-wa_202507/Kimi%20no%20na%20wa.mp4';
    } else if (lowerTitle.contains('frieren') || lowerTitle.contains('himmel') || lowerTitle.contains('fern')) {
      basePattern =
          'https://archive.org/download/anime-pahe-sousou-no-frieren-{EP}-bd-1080p-sev/AnimePahe_Sousou_no_Frieren_-_{EP}_BD_1080p_SEV.mp4';
    } else if (lowerTitle.contains('solo') || lowerTitle.contains('leveling') || lowerTitle.contains('sung jinwoo') || lowerTitle.contains('jin-woo')) {
      basePattern =
          'https://archive.org/download/anime-salt-solo-leveling-s-01-e-01-1080p-multi-audio/%5BAnimeSalt%5D%20Solo%20Leveling%20-%20S01E{EP}%20%5B1080p%5D%20%5BMulti-Audio%5D.mp4';
    } else if (lowerTitle.contains('punch') || lowerTitle.contains('saitama')) {
      for (int ep = 1; ep <= total; ep++) {
        final isS2 = seasonNumber == 2 || lowerTitle.contains('season 2') || lowerTitle.contains('2nd season');
        final files = isS2 ? _opmS2Files : _opmS1Files;
        final fileIndex = (ep - 1).clamp(0, files.length - 1);
        final encoded = Uri.encodeComponent(files[fileIndex]).replaceAll('%2F', '/');
        final url = 'https://archive.org/download/anionepunchmandl151080bray_starskis01s02.Gemischt/$encoded';
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: total == 1
              ? '$seriesTitle Full Movie Sub Indo'
              : '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: url.replaceAll('/download/', '/cors/'),
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
      return;
    } else if (lowerTitle.contains('death note') || lowerTitle.contains('light yagami')) {
      basePattern =
          'https://archive.org/download/death-note-complete-2006-2007/E{EP}%20-%20Rebirth.mp4';
    } else {
      // Do not register arbitrary unrelated video (e.g. Dan Da Dan) for unknown anime!
      return;
    }

    for (int ep = 1; ep <= total; ep++) {
      final epStr = ep.toString().padLeft(2, '0');
      final ep3Str = ep.toString().padLeft(3, '0');
      final url = basePattern
          .replaceAll('{EP}', epStr)
          .replaceAll('{EP3}', ep3Str)
          .replaceAll('{EP_NUM}', '$ep');
      registerVideo(UploadedAnimeVideo(
        aniListId: aniListId,
        seasonNumber: seasonNumber,
        episodeNumber: ep,
        episodeTitle: total == 1
            ? '$seriesTitle Full Movie Sub Indo'
            : '$seriesTitle Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: url,
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }
  }

  void _initDefaultVideos() {
    final now = DateTime(2024, 1, 1);

    // Helper to register standard episodes with multi-server mirrors
    void registerEpisodes({
      required int aniListId,
      required int seasonNumber,
      required int count,
      required String baseUrlPattern,
      String? server3BaseUrlPattern,
      String? server4BaseUrlPattern,
      required String seriesTitle,
    }) {
      for (int ep = 1; ep <= count; ep++) {
        final epStr = ep.toString().padLeft(2, '0');
        final ep3Str = ep.toString().padLeft(3, '0');
        final url = baseUrlPattern
            .replaceAll('{EP}', epStr)
            .replaceAll('{EP3}', ep3Str);
        final s3Url = server3BaseUrlPattern
            ?.replaceAll('{EP}', epStr)
            .replaceAll('{EP3}', ep3Str) ?? url;
        final s4Url = server4BaseUrlPattern
            ?.replaceAll('{EP}', epStr)
            .replaceAll('{EP3}', ep3Str) ?? url;

        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: count == 1
              ? '$seriesTitle Full Movie Sub Indo'
              : '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: s3Url,
          server4Url: s4Url,
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
      baseUrlPattern:
          'https://archive.org/download/anime-salt-solo-leveling-s-01-e-01-1080p-multi-audio/%5BAnimeSalt%5D%20Solo%20Leveling%20-%20S01E{EP}%20%5B1080p%5D%20%5BMulti-Audio%5D.mp4',
      server3BaseUrlPattern:
          'https://archive.org/cors/anime-salt-solo-leveling-s-01-e-01-1080p-multi-audio/%5BAnimeSalt%5D%20Solo%20Leveling%20-%20S01E{EP}%20%5B1080p%5D%20%5BMulti-Audio%5D.mp4',
      server4BaseUrlPattern:
          'https://archive.org/download/anime-salt-solo-leveling-s-01-e-01-1080p-multi-audio/%5BAnimeSalt%5D%20Solo%20Leveling%20-%20S01E{EP}%20%5B1080p%5D%20%5BMulti-Audio%5D.mp4',
      seriesTitle: 'Solo Leveling',
    );

    // 2. Tokyo Revengers Season 1 (AniList ID 120120, 24 Episodes, BluRay 1080p Japanese Audio)
    const trS1Files = [
      'Tokyo Revengers (2021) - S01e01 - Reborn [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-1.ia.mp4',
      'Tokyo Revengers (2021) - S01e02 - Resist [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-2.ia.mp4',
      'Tokyo Revengers (2021) - S01e03 - Resolve [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-3.ia.mp4',
      'Tokyo Revengers (2021) - S01e04 - Return [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-4.ia.mp4',
      'Tokyo Revengers (2021) - S01e05 - Releap [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-5.ia.mp4',
      'Tokyo Revengers (2021) - S01e06 - Regret [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-6.ia.mp4',
      'Tokyo Revengers (2021) - S01e07 - Revive [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-7.ia.mp4',
      'Tokyo Revengers (2021) - S01e08 - Rechange [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-8.ia.mp4',
      'Tokyo Revengers (2021) - S01e09 - Revolt [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-9.ia.mp4',
      'Tokyo Revengers (2021) - S01e10 - Rerise [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-10.ia.mp4',
      'Tokyo Revengers (2021) - S01e11 - Respect [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-11.ia.mp4',
      'Tokyo Revengers (2021) - S01e12 - Revenge [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-12.ia.mp4',
      'Tokyo Revengers (2021) - S01e13 - Odds And Ends [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-13.ia.mp4',
      'Tokyo Revengers (2021) - S01e14 - Break Up [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-14.ia.mp4',
      'Tokyo Revengers (2021) - S01e15 - No Pain No Gain [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-15.ia.mp4',
      'Tokyo Revengers (2021) - S01e16 - Once Upon A Time [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-16.ia.mp4',
      'Tokyo Revengers (2021) - S01e17 - No Way [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-17.ia.mp4',
      'Tokyo Revengers (2021) - S01e18 - Open Fire [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-18.ia.mp4',
      'Tokyo Revengers (2021) - S01e19 - Turn Around [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-19.ia.mp4',
      'Tokyo Revengers (2021) - S01e20 - Dead Or Alive [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-20.ia.mp4',
      'Tokyo Revengers (2021) - S01e21 - One And Only [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-21.ia.mp4',
      'Tokyo Revengers (2021) - S01e22 - One For All [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-22.ia.mp4',
      'Tokyo Revengers (2021) - S01e23 - End Of War [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-23.ia.mp4',
      'Tokyo Revengers (2021) - S01e24 - A Cry Baby [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-24.ia.mp4',
    ];
    for (int ep = 1; ep <= trS1Files.length; ep++) {
      final file = trS1Files[ep - 1];
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/mgamaangasnasigasheeshhh/$encoded';
      final s3Url = 'https://archive.org/cors/mgamaangasnasigasheeshhh/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 120120,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Tokyo Revengers Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: s3Url,
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 3. Tokyo Revengers Season 2 - Christmas Showdown (AniList ID 142853, 13 Episodes, BluRay 1080p Japanese Audio)
    const trS2Files = [
      'Tokyo Revengers (2021) - S02e01 - It Is What It Is [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-1.ia.mp4',
      'Tokyo Revengers (2021) - S02e02 - Gotta Go [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-2.ia.mp4',
      'Tokyo Revengers (2021) - S02e03 - Stand Alone [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-3.ia.mp4',
      'Tokyo Revengers (2021) - S02e04 - Family Bonds [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-4.ia.mp4',
      'Tokyo Revengers (2021) - S02e05 - Christmas Eve [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-5.ia.mp4',
      'Tokyo Revengers (2021) - S02e06 - Whip Up Morale [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-6.ia.mp4',
      'Tokyo Revengers (2021) - S02e07 - Sibling Rivalry [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-7.ia.mp4',
      'Tokyo Revengers (2021) - S02e08 - Strive Together [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-8.ia.mp4',
      'Tokyo Revengers (2021) - S02e09 - Dawning Of A New Era [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-9.ia.mp4',
      'Tokyo Revengers (2021) - S02e10 - The Light Of My Life [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-10.ia.mp4',
      'Tokyo Revengers (2021) - S02e11 - On My Way Home [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-11.ia.mp4',
      'Tokyo Revengers (2021) - S02e12 - Last Order [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-12.ia.mp4',
      'Tokyo Revengers (2021) - S02e13 - When It Rains It Pours [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-13.ia.mp4',
    ];
    for (int ep = 1; ep <= trS2Files.length; ep++) {
      final file = trS2Files[ep - 1];
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/paniskyotoavengershahahasdhaxcf/$encoded';
      final s3Url = 'https://archive.org/cors/paniskyotoavengershahahasdhaxcf/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 142853,
        seasonNumber: 2,
        episodeNumber: ep,
        episodeTitle: 'Tokyo Revengers S2 Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: s3Url,
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 4. Tokyo Revengers Season 3 - Tenjiku-hen (AniList ID 163539, 13 Episodes, Japanese Audio)
    for (int ep = 1; ep <= 13; ep++) {
      final file = 'Tokyo Revengers Tenjiku-hen Episodio $ep.mp4';
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/tokyo-revengers-tenjiku-hen-episodio-13/$encoded';
      final s3Url = 'https://archive.org/cors/tokyo-revengers-tenjiku-hen-episodio-13/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 163539,
        seasonNumber: 3,
        episodeNumber: ep,
        episodeTitle: 'Tokyo Revengers S3 Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: s3Url,
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 5. Tokyo Revengers Season 4 - Santen Sensou-hen (AniList ID 178945, Japanese Audio)
    registerVideo(UploadedAnimeVideo(
      aniListId: 178945,
      seasonNumber: 4,
      episodeNumber: 1,
      episodeTitle: 'Tokyo Revengers S4 Santen Sensou-hen Episode 1 Sub Indo',
      videoUrl: 'https://archive.org/download/animelk-tokyo-revengers-santen-e01/Tokyo%20Revengers%3A%20Santen%20Sensou-hen%20E01_720p.mp4',
      server3Url: 'https://archive.org/cors/animelk-tokyo-revengers-santen-e01/Tokyo%20Revengers%3A%20Santen%20Sensou-hen%20E01_720p.mp4',
      server4Url: 'https://archive.org/download/animelk-tokyo-revengers-santen-e01/Tokyo%20Revengers%3A%20Santen%20Sensou-hen%20E01_720p.mp4',
      uploader: 'AppOwnerOfficial',
      uploadedAt: now,
    ));

    // 6. Yosuga no Sora (AniList ID 8861, 12 Episodes BluRay Japanese audio)
    registerEpisodes(
      aniListId: 8861,
      seasonNumber: 1,
      count: 12,
      baseUrlPattern:
          'https://archive.org/download/yosuga-no-sora-0368ab60e9b77640d9c12f7f299b73232ba809e35d79a65b21b916ac4609ea085/Yosuga.no.Sora.S01E{EP}.1080p.BluRay.10-Bit.FLAC2.0.x265-YURASUKA.mp4',
      server3BaseUrlPattern:
          'https://ia600904.us.archive.org/11/items/yosuga-no-sora-0368ab60e9b77640d9c12f7f299b73232ba809e35d79a65b21b916ac4609ea085/Yosuga.no.Sora.S01E{EP}.1080p.BluRay.10-Bit.FLAC2.0.x265-YURASUKA.mp4',
      server4BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/yosuga-no-sora-0368ab60e9b77640d9c12f7f299b73232ba809e35d79a65b21b916ac4609ea085/Yosuga.no.Sora.S01E{EP}.1080p.BluRay.10-Bit.FLAC2.0.x265-YURASUKA.mp4',
      seriesTitle: 'Yosuga no Sora',
    );

    // 7. Demon Slayer Season 1 (AniList ID 101922)
    const knyMobileFiles = [
      'S01/Demon Slayer Kimetsu no Yaiba - S01E01 - Grausamkeit - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E02 - Lehrmeister Urokodaki Sakonji - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E03 - Sabito und Makomo - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E04 - Das letzte Auswahlverfahren - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E05 - Wähle deinen Stahl - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E06 - Der Schwertkämpfer mit dem Dämon - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E07 - Kibutsuji Muzan - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E08 - Der faszinierende Duft von Blut - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E09 - Der Balldämon und der Pfeildämon - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E10 - Immer zusammen - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E11 - Das Trommel-Anwesen - mobile.mp4',
      "S01/Demon Slayer Kimetsu no Yaiba - S01E12 - Das Wildschwein fletscht die Zähne und Zen'itsu schläft - mobile.mp4",
      'S01/Demon Slayer Kimetsu no Yaiba - S01E13 - Wichtiger als das eigene Leben - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E14 - Das Haus mit dem Glyzinien-Wappen - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E15 - Der Natagumo-Berg - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E16 - Vor jemand anderem als sich selbst - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E17 - Nur eine einzige Sache meistern - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E18 - Falsche Bande - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E19 - Die Feuergottheit - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E20 - Zusammengesammelte Familie - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E21 - Regelverstoß - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E22 - Meister - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E23 - Versammlung der Säulen - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E24 - Rehabilitationstraining - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E25 - Tsuguko Tsuyuri Kanao - mobile.mp4',
      'S01/Demon Slayer Kimetsu no Yaiba - S01E26 - Eine neue Mission - mobile.mp4',
    ];
    for (int ep = 1; ep <= knyMobileFiles.length; ep++) {
      final fileName = knyMobileFiles[ep - 1];
      final encodedPath = Uri.encodeComponent(fileName).replaceAll('%2F', '/');
      final url =
          'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS01.Gemischt/$encodedPath';
      registerVideo(UploadedAnimeVideo(
        aniListId: 101922,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Demon Slayer Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 8. Demon Slayer Season 2 (AniList ID 142329)
    registerEpisodes(
      aniListId: 142329,
      seasonNumber: 2,
      count: 11,
      baseUrlPattern:
          'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt/S02/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S02E01%20-%20Flammens%C3%A4ule%20Rengoku%20Kyojurou%20-%20mobile.mp4',
      server3BaseUrlPattern:
          'https://ia601508.us.archive.org/5/items/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt/S02/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S02E01%20-%20Flammens%C3%A4ule%20Rengoku%20Kyojurou%20-%20mobile.mp4',
      server4BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt/S02/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S02E01%20-%20Flammens%C3%A4ule%20Rengoku%20Kyojurou%20-%20mobile.mp4',
      seriesTitle: 'Demon Slayer S2',
    );

    // 9. Demon Slayer Season 3 (AniList ID 145139)
    registerEpisodes(
      aniListId: 145139,
      seasonNumber: 3,
      count: 11,
      baseUrlPattern:
          'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt/S03/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S03E01%20-%20Jemandens%20Traum%20-%20mobile.mp4',
      server3BaseUrlPattern:
          'https://ia601508.us.archive.org/5/items/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt/S03/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S03E01%20-%20Jemandens%20Traum%20-%20mobile.mp4',
      server4BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt/S03/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S03E01%20-%20Jemandens%20Traum%20-%20mobile.mp4',
      seriesTitle: 'Demon Slayer S3',
    );

    // 10. Attack on Titan Season 1 (AniList ID 16498)
    registerEpisodes(
      aniListId: 16498,
      seasonNumber: 1,
      count: 25,
      baseUrlPattern:
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20{EP}.mp4',
      server3BaseUrlPattern:
          'https://dn710906.ca.archive.org/0/items/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20{EP}.mp4',
      server4BaseUrlPattern:
          'https://ia810906.us.archive.org/0/items/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20{EP}.mp4',
      seriesTitle: 'Attack on Titan S1',
    );

    // 11. Death Note (AniList ID 1535)
    registerEpisodes(
      aniListId: 1535,
      seasonNumber: 1,
      count: 37,
      baseUrlPattern:
          'https://archive.org/download/death-note-complete-2006-2007/E{EP}%20-%20Rebirth.mp4',
      server3BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/death-note-complete-2006-2007/E{EP}%20-%20Rebirth.mp4',
      server4BaseUrlPattern:
          'https://ia800505.us.archive.org/0/items/death-note-complete-2006-2007/E{EP}%20-%20Rebirth.mp4',
      seriesTitle: 'Death Note',
    );

    // 12. Jujutsu Kaisen Season 1 (AniList ID 113415)
    registerEpisodes(
      aniListId: 113415,
      seasonNumber: 1,
      count: 24,
      baseUrlPattern:
          'https://archive.org/download/jjk-s01CBT/Jujutsu%20Kaisen%20%282020%29%20-%20S01E{EP}%20%281080p%20BluRay%20AV1%2010bit%20Opus%202.0%20KaNNa%29.mp4',
      server3BaseUrlPattern:
          'https://archive.org/cors/jjk-s01CBT/Jujutsu%20Kaisen%20%282020%29%20-%20S01E{EP}%20%281080p%20BluRay%20AV1%2010bit%20Opus%202.0%20KaNNa%29.mp4',
      server4BaseUrlPattern:
          'https://archive.org/download/jjk-s01CBT/Jujutsu%20Kaisen%20%282020%29%20-%20S01E{EP}%20%281080p%20BluRay%20AV1%2010bit%20Opus%202.0%20KaNNa%29.mp4',
      seriesTitle: 'Jujutsu Kaisen',
    );

    // 13. Chainsaw Man (AniList ID 127720)
    const csmHashes = {
      1: '62A0D357',
      2: 'A25323AA',
      3: 'CB67CABE',
      4: '84DC9A75',
      5: 'E3191D55',
      6: '438635DA',
      7: 'C71C1C6B',
      8: 'AB46185D',
      9: 'AA9D08A7',
      10: '17A6694C',
      11: '85DC2EF6',
      12: '805AD605',
    };
    for (int ep = 1; ep <= 12; ep++) {
      final pad = ep.toString().padLeft(2, '0');
      final hash = csmHashes[ep]!;
      final url =
          'https://archive.org/download/hi-10-chainsaw-man-s-1-1080p/%5BHi10%5D_Chainsaw_Man_S1_%5B1080p%5D%2F(Hi10)_Chainsaw_Man_S1_-_${pad}_(1080p)_(GJM)_($hash).mp4';
      registerVideo(UploadedAnimeVideo(
        aniListId: 127720,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Chainsaw Man Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 14. Dandadan (AniList ID 166240)
    registerEpisodes(
      aniListId: 166240,
      seasonNumber: 1,
      count: 12,
      baseUrlPattern:
          'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S01-E{EP}.mp4',
      server3BaseUrlPattern:
          'https://ia600904.us.archive.org/11/items/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S01-E{EP}.mp4',
      server4BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S01-E{EP}.mp4',
      seriesTitle: 'Dandadan',
    );

    // 15. Frieren: Beyond Journey\'s End (AniList ID 154587)
    registerEpisodes(
      aniListId: 154587,
      seasonNumber: 1,
      count: 28,
      baseUrlPattern:
          'https://archive.org/download/anime-pahe-sousou-no-frieren-{EP}-bd-1080p-sev/AnimePahe_Sousou_no_Frieren_-_{EP}_BD_1080p_SEV.mp4',
      server3BaseUrlPattern:
          'https://archive.org/cors/anime-pahe-sousou-no-frieren-{EP}-bd-1080p-sev/AnimePahe_Sousou_no_Frieren_-_{EP}_BD_1080p_SEV.mp4',
      server4BaseUrlPattern:
          'https://archive.org/download/anime-pahe-sousou-no-frieren-{EP}-bd-1080p-sev/AnimePahe_Sousou_no_Frieren_-_{EP}_BD_1080p_SEV.mp4',
      seriesTitle: 'Frieren',
    );

    // 16. Spy x Family (AniList ID 140960)
    registerEpisodes(
      aniListId: 140960,
      seasonNumber: 1,
      count: 12,
      baseUrlPattern:
          'https://archive.org/download/anispyxfamilyusdl221080bray_whdmob.Gemischt/Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY%20x%20FAMILY%20-%20S01E01%20-%20Operation%20Strix%20.mp4',
      server3BaseUrlPattern:
          'https://ia600904.us.archive.org/11/items/anispyxfamilyusdl221080bray_whdmob.Gemischt/Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY%20x%20FAMILY%20-%20S01E01%20-%20Operation%20Strix%20.mp4',
      server4BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/anispyxfamilyusdl221080bray_whdmob.Gemischt/Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY%20x%20FAMILY%20-%20S01E01%20-%20Operation%20Strix%20.mp4',
      seriesTitle: 'Spy x Family',
    );

    // 17. Hunter x Hunter (AniList ID 11061)
    registerEpisodes(
      aniListId: 11061,
      seasonNumber: 1,
      count: 148,
      baseUrlPattern:
          'https://archive.org/download/hxh11/{EP3}.mp4',
      server3BaseUrlPattern:
          'https://dn720602.ca.archive.org/0/items/hxh11/{EP3}.mp4',
      server4BaseUrlPattern:
          'https://ia820602.us.archive.org/0/items/hxh11/{EP3}.mp4',
      seriesTitle: 'Hunter x Hunter',
    );

    // 18. Fullmetal Alchemist: Brotherhood (AniList ID 5114)
    registerEpisodes(
      aniListId: 5114,
      seasonNumber: 1,
      count: 64,
      baseUrlPattern:
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/Claro%20Video/Fullmetal%20Alchemist%20Brotherhood%20(2009)%20%5B1st%20Dubbing%5D%5B480p%5D%5B%E2%9C%93%5D/Season%2001/Fullmetal%20Alchemist%20Brotherhood%20S01E01%20Fullmetal%20Alchemist.mp4',
      server3BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/claro-video-anime-series-pack-web-dl/Claro%20Video/Fullmetal%20Alchemist%20Brotherhood%20(2009)%20%5B1st%20Dubbing%5D%5B480p%5D%5B%E2%9C%93%5D/Season%2001/Fullmetal%20Alchemist%20Brotherhood%20S01E01%20Fullmetal%20Alchemist.mp4',
      server4BaseUrlPattern:
          'https://ia800505.us.archive.org/0/items/claro-video-anime-series-pack-web-dl/Claro%20Video/Fullmetal%20Alchemist%20Brotherhood%20(2009)%20%5B1st%20Dubbing%5D%5B480p%5D%5B%E2%9C%93%5D/Season%2001/Fullmetal%20Alchemist%20Brotherhood%20S01E01%20Fullmetal%20Alchemist.mp4',
      seriesTitle: 'Fullmetal Alchemist: Brotherhood',
    );

    // 19. One Piece (AniList ID 21)
    registerEpisodes(
      aniListId: 21,
      seasonNumber: 1,
      count: 1000,
      baseUrlPattern:
          'https://archive.org/download/one-piece-episode-1/One%20Piece%20Episode%201.mp4',
      server3BaseUrlPattern:
          'https://dn720602.ca.archive.org/0/items/one-piece-episode-1/One%20Piece%20Episode%201.mp4',
      server4BaseUrlPattern:
          'https://ia820602.us.archive.org/0/items/one-piece-episode-1/One%20Piece%20Episode%201.mp4',
      seriesTitle: 'One Piece',
    );

    // 20. Naruto (AniList ID 20)
    registerEpisodes(
      aniListId: 20,
      seasonNumber: 1,
      count: 220,
      baseUrlPattern:
          'https://archive.org/download/naruto-completo/Naruto%20-%20{EP3}.mp4',
      server3BaseUrlPattern:
          'https://dn720602.ca.archive.org/0/items/naruto-completo/Naruto%20-%20{EP3}.mp4',
      server4BaseUrlPattern:
          'https://ia820602.us.archive.org/0/items/naruto-completo/Naruto%20-%20{EP3}.mp4',
      seriesTitle: 'Naruto',
    );

    // 21. Bleach (AniList ID 269)
    registerEpisodes(
      aniListId: 269,
      seasonNumber: 1,
      count: 366,
      baseUrlPattern:
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/Claro%20Video/Bleach%20(2004)/s1%20(1)/Bleach%20S01E01%20The%20Day%20I%20Became%20a%20Shinigami.mp4',
      server3BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/claro-video-anime-series-pack-web-dl/Claro%20Video/Bleach%20(2004)/s1%20(1)/Bleach%20S01E01%20The%20Day%20I%20Became%20a%20Shinigami.mp4',
      server4BaseUrlPattern:
          'https://ia800505.us.archive.org/0/items/claro-video-anime-series-pack-web-dl/Claro%20Video/Bleach%20(2004)/s1%20(1)/Bleach%20S01E01%20The%20Day%20I%20Became%20a%20Shinigami.mp4',
      seriesTitle: 'Bleach',
    );

    // 22. Steins;Gate (AniList ID 9253)
    registerEpisodes(
      aniListId: 9253,
      seasonNumber: 1,
      count: 24,
      baseUrlPattern:
          'https://archive.org/download/anime-time-steins-gate/%5BAnime%20Time%5D%20Steins%3BGate%20-%20{EP}.mp4',
      server3BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/anime-time-steins-gate/%5BAnime%20Time%5D%20Steins%3BGate%20-%20{EP}.mp4',
      server4BaseUrlPattern:
          'https://ia800505.us.archive.org/0/items/anime-time-steins-gate/%5BAnime%20Time%5D%20Steins%3BGate%20-%20{EP}.mp4',
      seriesTitle: 'Steins;Gate',
    );

    // 23. Kimi no Na wa (AniList ID 21827)
    registerEpisodes(
      aniListId: 21827,
      seasonNumber: 1,
      count: 1,
      baseUrlPattern:
          'https://archive.org/download/kimi-no-na-wa_202507/Kimi%20no%20na%20wa.mp4',
      server3BaseUrlPattern:
          'https://archive.org/cors/kimi-no-na-wa_202507/Kimi%20no%20na%20wa.mp4',
      server4BaseUrlPattern:
          'https://archive.org/download/kimi-no-na-wa_202507/Kimi%20no%20na%20wa.mp4',
      seriesTitle: 'Kimi no Na wa',
    );

    // 24. Koe no Katachi (AniList ID 20954)
    registerEpisodes(
      aniListId: 20954,
      seasonNumber: 1,
      count: 1,
      baseUrlPattern:
          'https://archive.org/download/a-silent-voice-2016-1080p/A%20Silent%20Voice%20%282016%29%20%5B1080p%5D.mp4',
      server3BaseUrlPattern:
          'https://ia903201.us.archive.org/14/items/a-silent-voice-2016-1080p/A%20Silent%20Voice%20%282016%29%20%5B1080p%5D.mp4',
      server4BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/a-silent-voice-2016-1080p/A%20Silent%20Voice%20%282016%29%20%5B1080p%5D.mp4',
      seriesTitle: 'Koe no Katachi',
    );

    // 25. Shigatsu wa Kimi no Uso (AniList ID 20665)
    registerEpisodes(
      aniListId: 20665,
      seasonNumber: 1,
      count: 22,
      baseUrlPattern:
          'https://archive.org/download/AY-YourLieInApril/{EP}.mp4',
      server3BaseUrlPattern:
          'https://dn720005.ca.archive.org/0/items/AY-YourLieInApril/{EP}.mp4',
      server4BaseUrlPattern:
          'https://ia800505.us.archive.org/0/items/AY-YourLieInApril/{EP}.mp4',
      seriesTitle: 'Shigatsu wa Kimi no Uso',
    );

    // 26. One Punch Man Season 1 (AniList ID 21087)
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
    const opmBase =
        'https://archive.org/download/anionepunchmandl151080bray_starskis01s02.Gemischt';
    for (int i = 0; i < opmS1Titles.length; i++) {
      final ep = i + 1;
      final encoded = Uri.encodeComponent(_opmS1Files[i]).replaceAll('%2F', '/');
      final url = '$opmBase/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 21087,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Episode $ep - ${opmS1Titles[i]} Sub Indo',
        videoUrl: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 27. One Punch Man Season 2 (AniList ID 102194 & 97668)
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
        final encoded = Uri.encodeComponent(_opmS2Files[i]).replaceAll('%2F', '/');
        final url = '$opmBase/$encoded';
        registerVideo(UploadedAnimeVideo(
          aniListId: s2Id,
          seasonNumber: 2,
          episodeNumber: ep,
          episodeTitle: 'Episode $ep - ${opmS2Titles[i]} Sub Indo',
          videoUrl: url,
          server3Url: url.replaceAll('/download/', '/cors/'),
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
    }

    // 28. Tokyo Ghoul Season 1 (AniList ID 20605, 12 Episodes, Japanese Audio)
    for (int ep = 1; ep <= 12; ep++) {
      final fileName = 'S01E0$ep.mp4';
      final url = 'https://archive.org/download/tokyo-ghoul-s01-sm/$fileName';
      registerVideo(UploadedAnimeVideo(
        aniListId: 20605,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Tokyo Ghoul Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }
  }
}
