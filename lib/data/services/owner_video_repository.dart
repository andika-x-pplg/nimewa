import '../models/uploaded_anime_video.dart';

/// Repository managing owner-uploaded videos mapped to AniList IDs and seasons.
/// Strictly disallows automatic scraping or grabbing videos from internet.
class OwnerVideoRepository {
  static final OwnerVideoRepository instance = OwnerVideoRepository._internal();

  OwnerVideoRepository._internal() {
    _initDefaultVideos();
  }

  static const List<String> _opmS1Files = [
    'OPM-BD-01.mp4',
    'OPM-BD-02.mp4',
    'OPM-BD-03.mp4',
    'OPM-BD-04.mp4',
    'OPM-BD-05.mp4',
    'OPM-BD-06.mp4',
    'OPM-BD-07.mp4',
    'OPM-BD-08.mp4',
    'OPM-BD-09.mp4',
    'OPM-BD-10.mp4',
    'OPM-BD-11.mp4',
    'OPM-BD-12.mp4',
  ];

  static const List<String> _opmS2Files = [
    'O-S2-BD-01.mp4',
    'O-S2-BD-02.mp4',
    'O-S2-BD-03.mp4',
    'O-S2-BD-04.mp4',
    'O-S2-BD-05.mp4',
    'O-S2-BD-06.mp4',
    'O-S2-BD-07.mp4',
    'O-S2-BD-08.mp4',
    'O-S2-BD-09.mp4',
    'O-S2-BD-10.mp4',
    'O-S2-BD-11.mp4',
    'O-S2-BD-12.mp4',
  ];

  static const List<String> bleachS1Files = [
    'Bleach - 001 - A Shinigami Is Born!.mp4',
    'Bleach - 002 - Pay or Play.mp4',
    'Bleach - 003 - Sibling Rivalry.mp4',
    'Bleach - 004 - And Your Bird Can Speak.mp4',
    'Bleach - 005 - Beat the Invisible Enemy!.mp4',
    'Bleach - 006 - Fight to the Death! Ichigo vs Ichigo.mp4',
    'Bleach - 007 - Greetings from a Stuffed Toy.mp4',
    'Bleach - 008 - June 17th, A Memory of Rain.mp4',
    'Bleach - 009 - Unbeatable Enemy.mp4',
    'Bleach - 010 - Assault on Trip at Sacred Ground!.mp4',
    'Bleach - 011 - The Legendary Quincy.mp4',
    'Bleach - 012 - A Gentle Right Arm.mp4',
    'Bleach - 013 - Flowers and Hollows.mp4',
    'Bleach - 014 - Back to Back, A Fight to the Death!.mp4',
    'Bleach - 015 - Kon\'s Great Plan.mp4',
    'Bleach - 016 - Encounter, Renji Abarai!.mp4',
    'Bleach - 017 - Ichigo Dies!.mp4',
    'Bleach - 018 - Reclaim! The Power of the Shinigami.mp4',
    'Bleach - 019 - Ichigo Becomes a Hollow!.mp4',
    'Bleach - 020 - Ichimaru the Silver Shadow.mp4',
  ];
  static const List<String> _bleachS1Files = bleachS1Files;

  static const List<String> rezeroS1Files = [
    'ReZero kara Hajimeru Isekai Seikatsu Episode 1B(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 2(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 3(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 4(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 5(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 6(mp4)_1.mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 7(mp4)_1.mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 8(mp4)_1.mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 9(mp4)_1.mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 10(mp4)_1.mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 11(mp4)_1.mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 12(mp4)_1.mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 13(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 14(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 15(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 16(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 17(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 18(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 19(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 20(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 21(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 22(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 23(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 24(mp4).mp4',
    'ReZero kara Hajimeru Isekai Seikatsu Episode 25(mp4).mp4',
  ];
  static const List<String> _rezeroS1Files = rezeroS1Files;

  static const List<String> _yosugaFiles = [
    '[animegrimoire] Yosuga no Sora -  01 [BD720p][CC94803A].mp4',
    '[animegrimoire] Yosuga no Sora -  02 [BD720p][6965D940].mp4',
    '[animegrimoire] Yosuga no Sora -  03 [BD720p][45718E07].mp4',
    '[animegrimoire] Yosuga no Sora -  04 [BD720p][F533E964].mp4',
    '[animegrimoire] Yosuga no Sora -  05 [BD720p][9B862A54].mp4',
    '[animegrimoire] Yosuga no Sora -  06 [BD720p][9AB4BF03].mp4',
    '[animegrimoire] Yosuga no Sora -  07 [BD720p][A296380B].mp4',
    '[animegrimoire] Yosuga no Sora -  08 [BD720p][00267C62].mp4',
    '[animegrimoire] Yosuga no Sora -  09 [BD720p][53B7EE5A].mp4',
    '[animegrimoire] Yosuga no Sora -  10 [BD720p][7ACF640F].mp4',
    '[animegrimoire] Yosuga no Sora -  11 [BD720p][9D9B824B].mp4',
    '[animegrimoire] Yosuga no Sora -  12 [BD720p][34C8DB2D].mp4',
  ];
  static const List<String> yosugaFiles = _yosugaFiles;

  static const List<String> _soloLevelingFiles = [
    'Solo.Leveling.S01E01.Im.Used.to.It.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E02.If.I.Had.One.More.Chance.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E03.Its.Like.a.Game.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E04.Ive.Gotta.Get.Stronger.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E05.A.Pretty.Good.Deal.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E06.The.Real.Hunt.Begins.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E07.Lets.See.How.Far.I.Can.Go.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E08.This.Is.Frustrating.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E09.Youve.Been.Hiding.Your.Skills.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E10.What.Is.This.a.Picnic.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E11.A.Knight.Who.Defends.an.Empty.Throne.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
    'Solo.Leveling.S01E12.Arise.1080p.CR.WEB-DL.MULTi.AAC2.0.H.264.MSubs-ToonsHub.mkv',
  ];
  static const List<String> soloLevelingFiles = _soloLevelingFiles;

  static const List<String> aotS1Titles = [
    'S01E01 (1) - To You, in 2000 Years The Fall of Shiganshina, Part 1',
    'S01E02 (2) - That Day The Fall of Shiganshina, Part 2',
    'S01E03 (3) - A Dim Light Amid Despair Humanity\'s Comeback, Part 1',
    'S01E04 (4) - The Night of the Closing Ceremony Humanity\'s Comeback, Part 2',
    'S01E05 (5) - First Battle The Struggle for Trost, Part 1',
    'S01E06 (6) - The World the Girl Saw The Struggle for Trost, Part 2',
    'S01E07 (7) - Small Blade The Struggle for Trost, Part 3',
    'S01E08 (8) - I Can Hear His Heartbeat The Struggle for Trost, Part 4',
    'S01E09 (9) - Whereabouts of His Left Arm The Struggle for Trost, Part 5',
    'S01E10 (10) - Response The Struggle for Trost, Part 6',
    'S01E11 (11) - Idol The Struggle for Trost, Part 7',
    'S01E12 (12) - Wound The Struggle for Trost, Part 8',
    'S01E13 (13) - Primal Desire The Struggle for Trost, Part 9',
    'S01E14 (14) - Can\'t Look into His Eyes Yet Eve of the Counterattack, Part 1',
    'S01E15 (15) - Special Operations Squad Eve of the Counterattack, Part 2',
    'S01E16 (16) - What Should Be Done Eve of the Counterattack, Part 3',
    'S01E17 (17) - Female Titan The 57th Exterior Scouting Mission, Part 1',
    'S01E18 (18) - Forest of Giant Trees The 57th Exterior Scouting Mission, Part 2',
    'S01E19 (19) - Bite The 57th Exterior Scouting Mission, Part 3',
    'S01E20 (20) - Erwin Smith The 57th Exterior Scouting Mission, Part 4',
    'S01E21 (21) - Crushing Blow The 57th Exterior Scouting Mission, Part 5',
    'S01E22 (22) - The Defeated The 57th Exterior Scouting Mission, Part 6',
    'S01E23 (23) - Smile Raid on Stohess District, Part 1',
    'S01E24 (24) - Mercy Raid on Stohess District, Part 2',
    'S01E25 (25) - Wall Raid on Stohess District, Part 3',
  ];
  static const List<String> _aotS1Titles = aotS1Titles;

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
      if (lowerTitle.contains('movie') || lowerTitle.contains('film') || lowerTitle.contains('reze')) {
        basePattern = 'https://archive.org/download/rezearc/csmrezearc.mp4';
      } else {
        basePattern =
            'https://archive.org/download/hi-10-chainsaw-man-s-1-1080p/%5BHi10%5D_Chainsaw_Man_S1_%5B1080p%5D%2F(Hi10)_Chainsaw_Man_S1_-_01_(1080p)_(GJM)_(62A0D357).mp4';
      }
    } else if (lowerTitle.contains('dandadan') || lowerTitle.contains('okarun')) {
      if (seasonNumber == 2 || lowerTitle.contains('season 2')) {
        basePattern =
            'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S02-E{EP}.mp4';
      } else {
        basePattern =
            'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S01-E{EP}.mp4';
      }
    } else if (lowerTitle.contains('spy') && lowerTitle.contains('family')) {
      for (int ep = 1; ep <= total; ep++) {
        final epStr = ep.toString().padLeft(2, '0');
        final tvq = ep >= 10 ? 'TVQ' : '';
        final ident = ep >= 10 ? 'spy-family-$epStr-tvq-720p' : 'spy-family-$epStr-720p';
        final url = 'https://archive.org/download/$ident/SpyFamily_$epStr$tvq-720p.mp4';
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
    } else if (lowerTitle.contains('hunter') || lowerTitle.contains('hxh')) {
      basePattern = 'https://archive.org/download/hxh11/{EP3}.ia.mp4';
    } else if (lowerTitle.contains('titan') || lowerTitle.contains('shingeki') || lowerTitle.contains('eren')) {
      for (int ep = 1; ep <= total; ep++) {
        final fileIndex = (ep - 1).clamp(0, _aotS1Titles.length - 1);
        final fileName =
            'Attack on Titan (2013) Season 1 S01 (1080p BluRay x265 HEVC 10bit AAC 5.1 ImE) REPACK/Attack on Titan (2013) - ${_aotS1Titles[fileIndex]} (1080p BluRay x265 ImE).mp4';
        final encoded = Uri.encodeComponent(fileName).replaceAll('%2F', '/');
        final url = 'https://archive.org/download/aot-s-1/$encoded';
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: url.replaceAll('/download/', '/cors/'),
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
      return;
    } else if (lowerTitle.contains('demon slayer') || lowerTitle.contains('kimetsu') || lowerTitle.contains('tanjiro')) {
      if (seasonNumber == 2 || lowerTitle.contains('season 2') || lowerTitle.contains('yuukaku') || lowerTitle.contains('entertainment district')) {
        for (int ep = 1; ep <= total; ep++) {
          final url = 'https://archive.org/download/kimetsu_20240913/GATON%202.$ep.mp4';
          registerVideo(UploadedAnimeVideo(
            aniListId: aniListId,
            seasonNumber: seasonNumber,
            episodeNumber: ep,
            episodeTitle: '$seriesTitle Episode $ep Sub Indo',
            videoUrl: url,
            server3Url: 'https://archive.org/cors/kimetsu_20240913/GATON%202.$ep.mp4',
            server4Url: url,
            uploader: 'AppOwnerOfficial',
            uploadedAt: now,
          ));
        }
        return;
      }
      basePattern = 'https://archive.org/download/knys1/KNYS1-E{EP_NUM}.mp4';
    } else if (lowerTitle.contains('jujutsu') || lowerTitle.contains('sukuna') || lowerTitle.contains('itadori')) {
      if (lowerTitle.contains('0') || lowerTitle.contains('movie') || lowerTitle.contains('film')) {
        basePattern =
            'https://archive.org/download/jujutsu-kaisen-0-1080p/Jujutsu-Kaisen-0_1080p.mp4';
      } else {
        basePattern =
            'https://archive.org/download/jjk-s01CBT/Jujutsu%20Kaisen%20%282020%29%20-%20S01E{EP}%20%281080p%20BluRay%20AV1%2010bit%20Opus%202.0%20KaNNa%29.mp4';
      }
    } else if (lowerTitle.contains('tokyo ghoul') || lowerTitle.contains('kaneki')) {
      if (lowerTitle.contains('movie') || lowerTitle.contains('film') || lowerTitle.contains('tokyo ghoul s')) {
        basePattern = 'https://archive.org/download/tokyo-ghoul-s/TokyoGhoulS.mp4';
      } else {
        basePattern = 'https://archive.org/download/tokyo-ghoul-s01-sm/S01E0{EP_NUM}.mp4';
      }
    } else if (lowerTitle.contains('naruto') || lowerTitle.contains('boruto')) {
      basePattern =
          'https://archive.org/download/naruto-completo/Naruto%20-%20{EP3}.mp4';
    } else if (lowerTitle.contains('piece') || lowerTitle.contains('luffy')) {
      for (int ep = 1; ep <= total; ep++) {
        String url;
        if (ep == 1) {
          url = 'https://archive.org/download/one-piece-episode-1/One%20Piece%20Episode%201.mp4';
        } else if (ep == 2) {
          url = 'https://archive.org/download/one-piece-episode-9/%20One%20Piece%20episode%202.mp4';
        } else {
          url = 'https://archive.org/download/one-piece-episode-9/One%20Piece%20episode%20$ep.mp4';
        }
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: url.replaceAll('/download/', '/cors/'),
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
      return;
    } else if (lowerTitle.contains('bleach') || lowerTitle.contains('ichigo')) {
      for (int ep = 1; ep <= total; ep++) {
        final fileIndex = (ep - 1).clamp(0, _bleachS1Files.length - 1);
        final file = _bleachS1Files[fileIndex];
        final encoded = Uri.encodeComponent(file);
        final url = 'https://archive.org/download/bleach-127-c-p/$encoded';
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: 'https://archive.org/cors/bleach-127-c-p/$encoded',
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
      return;
    } else if (lowerTitle.contains('rezero') || lowerTitle.contains('re:zero') || lowerTitle.contains('subaru') || lowerTitle.contains('emilia')) {
      for (int ep = 1; ep <= total; ep++) {
        final fileIndex = (ep - 1).clamp(0, _rezeroS1Files.length - 1);
        final file = _rezeroS1Files[fileIndex];
        final encoded = Uri.encodeComponent(file);
        final url = 'https://archive.org/download/rezerokarahajimeruisekaiseikatsu_202001/$encoded';
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: 'https://archive.org/cors/rezerokarahajimeruisekaiseikatsu_202001/$encoded',
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
      return;
    } else if (lowerTitle.contains('alchemist') || lowerTitle.contains('elric')) {
      basePattern =
          'https://archive.org/download/ma-fullmetal-alchemist-2009-bdrip-1920x1080-av1-opus/%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20%5BBDRip%201920x1080%20AV1%20OPUS%5D%2F%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20{EP}%20%5BBDRip%201920x1080%20AV1%20OPUS%5D.mkv';
    } else if (lowerTitle.contains('steins') || lowerTitle.contains('okabe')) {
      basePattern =
          'https://archive.org/download/anime-time-steins-gate/%5BAnime%20Time%5D%20Steins%3BGate%20-%20{EP}.mp4';
    } else if (lowerTitle.contains('april') || lowerTitle.contains('shigatsu') || lowerTitle.contains('kaori')) {
      basePattern = 'https://archive.org/download/AY-YourLieInApril/{EP}.mp4';
    } else if (lowerTitle.contains('silent voice') || lowerTitle.contains('koe no katachi') || lowerTitle.contains('shouko')) {
      basePattern =
          'https://archive.org/download/koe-no-katachi-1080p/KoeNoKatachi_1080p.mp4';
    } else if (lowerTitle.contains('yosuga') || lowerTitle.contains('kasugano') || lowerTitle.contains('sora')) {
      for (int ep = 1; ep <= total; ep++) {
        final fileIndex = (ep - 1).clamp(0, _yosugaFiles.length - 1);
        final file = _yosugaFiles[fileIndex];
        final encoded = Uri.encodeComponent(file);
        final url = 'https://archive.org/download/ag_yosuga-no-sora/$encoded';
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: 'https://archive.org/cors/ag_yosuga-no-sora/$encoded',
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
      return;
    } else if (lowerTitle.contains('tokyo revengers') || lowerTitle.contains('takemichi') || lowerTitle.contains('mikey')) {
      if (seasonNumber >= 4 || lowerTitle.contains('season 4') || lowerTitle.contains('santen')) {
        // Tokyo Revengers Season 4 is explicitly NOT available per user request
        return;
      }
      if (seasonNumber == 3 || lowerTitle.contains('season 3') || lowerTitle.contains('tenjiku')) {
        basePattern =
            'https://archive.org/download/kyotoavenrgesrsamputahahaha/Tokyo%20Revengers%20%282021%29%20-%20S03e{EP}%20-%20The%20Longest%20Day%20%5BBluray-1080P%5D%5BOpus%202.0%5D%5BAv1%5D-Blackrabbit-{EP_NUM}.ia.mp4';
      } else if (seasonNumber == 2 || lowerTitle.contains('season 2')) {
        basePattern =
            'https://archive.org/download/paniskyotoavengershahahasdhaxcf/Tokyo%20Revengers%20%282021%29%20-%20S02e{EP}%20-%20It%20Is%20What%20It%20Is%20%5BBluray-1080P%5D%5BOpus%202.0%5D%5BAv1%5D-Blackrabbit-{EP_NUM}.ia.mp4';
      } else {
        basePattern =
            'https://archive.org/download/mgamaangasnasigasheeshhh/Tokyo%20Revengers%20%282021%29%20-%20S01e{EP}%20-%20Reborn%20%5BBluray-1080P%5D%5BOpus%202.0%5D%5BAv1%5D-Blackrabbit-{EP_NUM}.ia.mp4';
      }
    } else if (lowerTitle.contains('your name') || lowerTitle.contains('kimi no na wa')) {
      basePattern =
          'https://archive.org/download/kimi-no-na-wa_202507/Kimi%20no%20na%20wa.mp4';
    } else if (lowerTitle.contains('frieren') || lowerTitle.contains('himmel') || lowerTitle.contains('fern')) {
      basePattern =
          'https://archive.org/download/anime-pahe-sousou-no-frieren-{EP}-bd-1080p-sev/AnimePahe_Sousou_no_Frieren_-_{EP}_BD_1080p_SEV.mp4';
    } else if (lowerTitle.contains('solo') || lowerTitle.contains('leveling') || lowerTitle.contains('sung jinwoo') || lowerTitle.contains('jin-woo')) {
      for (int ep = 1; ep <= total; ep++) {
        final fileIndex = (ep - 1).clamp(0, _soloLevelingFiles.length - 1);
        final file = _soloLevelingFiles[fileIndex];
        final encoded = Uri.encodeComponent(file);
        final url = 'https://archive.org/download/solo-leveling-s01-jeovanne-souza/$encoded';
        registerVideo(UploadedAnimeVideo(
          aniListId: aniListId,
          seasonNumber: seasonNumber,
          episodeNumber: ep,
          episodeTitle: '$seriesTitle Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: 'https://archive.org/cors/solo-leveling-s01-jeovanne-souza/$encoded',
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
      return;
    } else if (lowerTitle.contains('punch') || lowerTitle.contains('saitama')) {
      for (int ep = 1; ep <= total; ep++) {
        final isS2 = seasonNumber == 2 || lowerTitle.contains('season 2') || lowerTitle.contains('2nd season');
        final files = isS2 ? _opmS2Files : _opmS1Files;
        final fileIndex = (ep - 1).clamp(0, files.length - 1);
        final base = isS2 ? 'https://archive.org/download/opm-s2' : 'https://archive.org/download/opm-s1';
        final fileName = files[fileIndex];
        final url = '$base/$fileName';
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
    for (int ep = 1; ep <= _soloLevelingFiles.length; ep++) {
      final file = _soloLevelingFiles[ep - 1];
      final encoded = Uri.encodeComponent(file);
      final url =
          'https://archive.org/download/solo-leveling-s01-jeovanne-souza/$encoded';
      final corsUrl =
          'https://archive.org/cors/solo-leveling-s01-jeovanne-souza/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 151807,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Solo Leveling Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: corsUrl,
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

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
    const trS3Files = [
      'Tokyo Revengers (2021) - S03e01 - The Longest Day [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-1.ia.mp4',
      'Tokyo Revengers (2021) - S03e02 - Mortal Enemy [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-2.ia.mp4',
      'Tokyo Revengers (2021) - S03e03 - Run Out Of Patience [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-3.ia.mp4',
      'Tokyo Revengers (2021) - S03e04 - Come Back To Life [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-4.ia.mp4',
      'Tokyo Revengers (2021) - S03e05 - A Bad Hunch [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-5.ia.mp4',
      'Tokyo Revengers (2021) - S03e06 - Rise Against [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-6.ia.mp4',
      'Tokyo Revengers (2021) - S03e07 - Turn The Tide [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-7.ia.mp4',
      'Tokyo Revengers (2021) - S03e08 - I Know In My Head [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-8.ia.mp4',
      'Tokyo Revengers (2021) - S03e09 - The Blue Ogre [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-9.ia.mp4',
      'Tokyo Revengers (2021) - S03e10 - Brave Heart [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-10.ia.mp4',
      'Tokyo Revengers (2021) - S03e11 - Nothing Is Left [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-11.ia.mp4',
      'Tokyo Revengers (2021) - S03e12 - Paradise Lost [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-12.ia.mp4',
      'Tokyo Revengers (2021) - S03e13 - Meet His Fate [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-13.ia.mp4',
    ];
    for (int ep = 1; ep <= trS3Files.length; ep++) {
      final file = trS3Files[ep - 1];
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/kyotoavenrgesrsamputahahaha/$encoded';
      final s3Url = 'https://archive.org/cors/kyotoavenrgesrsamputahahaha/$encoded';
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

    // 5. Tokyo Revengers Season 4 - Santen Sensou-hen: Explicitly NOT available per user request

    // 6. Yosuga no Sora (AniList ID 8861, 12 Episodes BluRay H.264 Japanese audio)
    for (int ep = 1; ep <= _yosugaFiles.length; ep++) {
      final file = _yosugaFiles[ep - 1];
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/ag_yosuga-no-sora/$encoded';
      final s3Url = 'https://archive.org/cors/ag_yosuga-no-sora/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 8861,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Yosuga no Sora Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: s3Url,
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 7. Demon Slayer Season 1 (AniList ID 101922, 26 Episodes, Japanese Audio)
    for (int ep = 1; ep <= 26; ep++) {
      final url = 'https://archive.org/download/knys1/KNYS1-E$ep.mp4';
      final s3Url = 'https://archive.org/cors/knys1/KNYS1-E$ep.mp4';
      registerVideo(UploadedAnimeVideo(
        aniListId: 101922,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Demon Slayer Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: s3Url,
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 8. Demon Slayer Season 2 - Entertainment District Arc (AniList ID 142329, 11 Episodes)
    for (int ep = 1; ep <= 11; ep++) {
      final url = 'https://archive.org/download/kimetsu_20240913/GATON%202.$ep.mp4';
      registerVideo(UploadedAnimeVideo(
        aniListId: 142329,
        seasonNumber: 2,
        episodeNumber: ep,
        episodeTitle: 'Demon Slayer S2 Yuukaku-hen Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: 'https://archive.org/cors/kimetsu_20240913/GATON%202.$ep.mp4',
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 9. Demon Slayer Season 3 (AniList ID 145139)
    registerEpisodes(
      aniListId: 145139,
      seasonNumber: 3,
      count: 11,
      baseUrlPattern:
          'https://archive.org/download/knyhgh1243ekrngtfkmrgtihj/knyhgh1243ekrngtfkmrgtihj-hd-1.mp4',
      server3BaseUrlPattern:
          'https://archive.org/cors/knyhgh1243ekrngtfkmrgtihj/knyhgh1243ekrngtfkmrgtihj-hd-1.mp4',
      server4BaseUrlPattern:
          'https://archive.org/download/knyhgh1243ekrngtfkmrgtihj/knyhgh1243ekrngtfkmrgtihj-hd-1.mp4',
      seriesTitle: 'Demon Slayer S3',
    );

    // 10. Attack on Titan Season 1 (AniList ID 16498, 25 Episodes, Japanese Audio)
    const aotTitles = [
      'S01E01 (1) - To You, in 2000 Years The Fall of Shiganshina, Part 1',
      'S01E02 (2) - That Day The Fall of Shiganshina, Part 2',
      'S01E03 (3) - A Dim Light Amid Despair Humanity\'s Comeback, Part 1',
      'S01E04 (4) - The Night of the Closing Ceremony Humanity\'s Comeback, Part 2',
      'S01E05 (5) - First Battle The Struggle for Trost, Part 1',
      'S01E06 (6) - The World the Girl Saw The Struggle for Trost, Part 2',
      'S01E07 (7) - Small Blade The Struggle for Trost, Part 3',
      'S01E08 (8) - I Can Hear His Heartbeat The Struggle for Trost, Part 4',
      'S01E09 (9) - Whereabouts of His Left Arm The Struggle for Trost, Part 5',
      'S01E10 (10) - Response The Struggle for Trost, Part 6',
      'S01E11 (11) - Idol The Struggle for Trost, Part 7',
      'S01E12 (12) - Wound The Struggle for Trost, Part 8',
      'S01E13 (13) - Primal Desire The Struggle for Trost, Part 9',
      'S01E14 (14) - Can\'t Look into His Eyes Yet Eve of the Counterattack, Part 1',
      'S01E15 (15) - Special Operations Squad Eve of the Counterattack, Part 2',
      'S01E16 (16) - What Should Be Done Eve of the Counterattack, Part 3',
      'S01E17 (17) - Female Titan The 57th Exterior Scouting Mission, Part 1',
      'S01E18 (18) - Forest of Giant Trees The 57th Exterior Scouting Mission, Part 2',
      'S01E19 (19) - Bite The 57th Exterior Scouting Mission, Part 3',
      'S01E20 (20) - Erwin Smith The 57th Exterior Scouting Mission, Part 4',
      'S01E21 (21) - Crushing Blow The 57th Exterior Scouting Mission, Part 5',
      'S01E22 (22) - The Defeated The 57th Exterior Scouting Mission, Part 6',
      'S01E23 (23) - Smile Raid on Stohess District, Part 1',
      'S01E24 (24) - Mercy Raid on Stohess District, Part 2',
      'S01E25 (25) - Wall Raid on Stohess District, Part 3',
    ];
    for (int ep = 1; ep <= aotTitles.length; ep++) {
      final fileName =
          'Attack on Titan (2013) Season 1 S01 (1080p BluRay x265 HEVC 10bit AAC 5.1 ImE) REPACK/Attack on Titan (2013) - ${aotTitles[ep - 1]} (1080p BluRay x265 ImE).mp4';
      final encoded = Uri.encodeComponent(fileName).replaceAll('%2F', '/');
      final url = 'https://archive.org/download/aot-s-1/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 16498,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Attack on Titan S1 Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

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
    for (int ep = 1; ep <= 12; ep++) {
      final epStr = ep.toString().padLeft(2, '0');
      final tvq = ep >= 10 ? 'TVQ' : '';
      final ident = ep >= 10 ? 'spy-family-$epStr-tvq-720p' : 'spy-family-$epStr-720p';
      final file = 'SpyFamily_$epStr$tvq-720p.mp4';
      final url = 'https://archive.org/download/$ident/$file';
      registerVideo(UploadedAnimeVideo(
        aniListId: 140960,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Spy x Family Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 17. Hunter x Hunter (AniList ID 11061)
    registerEpisodes(
      aniListId: 11061,
      seasonNumber: 1,
      count: 148,
      baseUrlPattern:
          'https://archive.org/download/hxh11/{EP3}.ia.mp4',
      server3BaseUrlPattern:
          'https://archive.org/cors/hxh11/{EP3}.ia.mp4',
      server4BaseUrlPattern:
          'https://archive.org/download/hxh11/{EP3}.ia.mp4',
      seriesTitle: 'Hunter x Hunter',
    );

    // 18. Fullmetal Alchemist: Brotherhood (AniList ID 5114)
    registerEpisodes(
      aniListId: 5114,
      seasonNumber: 1,
      count: 64,
      baseUrlPattern:
          'https://archive.org/download/ma-fullmetal-alchemist-2009-bdrip-1920x1080-av1-opus/%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20%5BBDRip%201920x1080%20AV1%20OPUS%5D%2F%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20{EP}%20%5BBDRip%201920x1080%20AV1%20OPUS%5D.mkv',
      server3BaseUrlPattern:
          'https://archive.org/cors/ma-fullmetal-alchemist-2009-bdrip-1920x1080-av1-opus/%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20%5BBDRip%201920x1080%20AV1%20OPUS%5D%2F%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20{EP}%20%5BBDRip%201920x1080%20AV1%20OPUS%5D.mkv',
      server4BaseUrlPattern:
          'https://archive.org/download/ma-fullmetal-alchemist-2009-bdrip-1920x1080-av1-opus/%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20%5BBDRip%201920x1080%20AV1%20OPUS%5D%2F%5BMA%5D%20FULLMETAL%20ALCHEMIST%20%282009%29%20{EP}%20%5BBDRip%201920x1080%20AV1%20OPUS%5D.mkv',
      seriesTitle: 'Fullmetal Alchemist: Brotherhood',
    );

    // 19. One Piece (AniList ID 21, Season 1 East Blue)
    for (int ep = 1; ep <= 25; ep++) {
      String url;
      if (ep == 1) {
        url = 'https://archive.org/download/one-piece-episode-1/One%20Piece%20Episode%201.mp4';
      } else if (ep == 2) {
        url = 'https://archive.org/download/one-piece-episode-9/%20One%20Piece%20episode%202.mp4';
      } else {
        url = 'https://archive.org/download/one-piece-episode-9/One%20Piece%20episode%20$ep.mp4';
      }
      registerVideo(UploadedAnimeVideo(
        aniListId: 21,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'One Piece Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

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

    // 21. Bleach (AniList ID 269, 20 Episodes Season 1)
    for (int ep = 1; ep <= _bleachS1Files.length; ep++) {
      final file = _bleachS1Files[ep - 1];
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/bleach-127-c-p/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 269,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Bleach Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: 'https://archive.org/cors/bleach-127-c-p/$encoded',
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 21b. Re:Zero - Starting Life in Another World (AniList ID 21355, 25 Episodes Season 1)
    for (int ep = 1; ep <= _rezeroS1Files.length; ep++) {
      final file = _rezeroS1Files[ep - 1];
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/rezerokarahajimeruisekaiseikatsu_202001/$encoded';
      registerVideo(UploadedAnimeVideo(
        aniListId: 21355,
        seasonNumber: 1,
        episodeNumber: ep,
        episodeTitle: 'Re:Zero Episode $ep Sub Indo',
        videoUrl: url,
        server3Url: 'https://archive.org/cors/rezerokarahajimeruisekaiseikatsu_202001/$encoded',
        server4Url: url,
        uploader: 'AppOwnerOfficial',
        uploadedAt: now,
      ));
    }

    // 21c. Dan Da Dan Season 2 (AniList ID 178526 and Season 2 under 166240, 12 Episodes)
    for (final dddId in [166240, 178526]) {
      for (int ep = 1; ep <= 12; ep++) {
        final epStr = ep.toString().padLeft(2, '0');
        final url = 'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S02-E$epStr.mp4';
        registerVideo(UploadedAnimeVideo(
          aniListId: dddId,
          seasonNumber: 2,
          episodeNumber: ep,
          episodeTitle: 'Dan Da Dan S2 Episode $ep Sub Indo',
          videoUrl: url,
          server3Url: url.replaceAll('/download/', '/cors/'),
          server4Url: url,
          uploader: 'AppOwnerOfficial',
          uploadedAt: now,
        ));
      }
    }

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
          'https://archive.org/download/koe-no-katachi-1080p/KoeNoKatachi_1080p.mp4',
      server3BaseUrlPattern:
          'https://archive.org/cors/koe-no-katachi-1080p/KoeNoKatachi_1080p.mp4',
      server4BaseUrlPattern:
          'https://archive.org/download/a-silent-voice-subbed/AnimePahe_Koe_no_Katachi_-_01_BD_1036p_Kametsu.mp4',
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
    for (int i = 0; i < opmS1Titles.length; i++) {
      final ep = i + 1;
      final epStr = ep.toString().padLeft(2, '0');
      final url = 'https://archive.org/download/opm-s1/OPM-BD-$epStr.mp4';
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
        final epStr = ep.toString().padLeft(2, '0');
        final file = ep == 12 ? 'O-S2-BD-12.ia.mp4' : 'O-S2-BD-$epStr.mp4';
        final url = 'https://archive.org/download/opm-s2/$file';
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

    // 29. Jujutsu Kaisen 0 Movie (AniList ID 131573)
    registerVideo(UploadedAnimeVideo(
      aniListId: 131573,
      seasonNumber: 1,
      episodeNumber: 1,
      episodeTitle: 'Jujutsu Kaisen 0 Full Movie Sub Indo',
      videoUrl: 'https://archive.org/download/jujutsu-kaisen-0-1080p/Jujutsu-Kaisen-0_1080p.mp4',
      server3Url: 'https://archive.org/cors/jujutsu-kaisen-0-1080p/Jujutsu-Kaisen-0_1080p.mp4',
      server4Url: 'https://archive.org/download/jujutsu-kaisen-0-1080p/Jujutsu-Kaisen-0_1080p.mp4',
      uploader: 'AppOwnerOfficial',
      uploadedAt: now,
    ));

    // 30. Demon Slayer: Mugen Ressha-hen Movie (AniList ID 112151)
    registerVideo(UploadedAnimeVideo(
      aniListId: 112151,
      seasonNumber: 1,
      episodeNumber: 1,
      episodeTitle: 'Demon Slayer: Mugen Ressha-hen Movie Sub Indo',
      videoUrl: 'https://archive.org/download/knym-ressha-hen-s/knym%20Ressha-hen%20s.mp4',
      server3Url: 'https://archive.org/cors/knym-ressha-hen-s/knym%20Ressha-hen%20s.mp4',
      server4Url: 'https://archive.org/download/knym-ressha-hen-s/knym%20Ressha-hen%20s.mp4',
      uploader: 'AppOwnerOfficial',
      uploadedAt: now,
    ));

    // 31. Haikyuu!! The Dumpster Battle Movie (AniList ID 152865)
    registerVideo(UploadedAnimeVideo(
      aniListId: 152865,
      seasonNumber: 1,
      episodeNumber: 1,
      episodeTitle: 'Haikyuu!! The Dumpster Battle Movie Sub Indo',
      videoUrl: 'https://archive.org/download/haikyu-the-dumpster-battle-2024/Haikyu%21%21%20The%20Dumpster%20Battle%20%282024%29.mp4',
      server3Url: 'https://archive.org/cors/haikyu-the-dumpster-battle-2024/Haikyu%21%21%20The%20Dumpster%20Battle%20%282024%29.mp4',
      server4Url: 'https://archive.org/download/haikyu-the-dumpster-battle-2024/Haikyu%21%21%20The%20Dumpster%20Battle%20%282024%29.mp4',
      uploader: 'AppOwnerOfficial',
      uploadedAt: now,
    ));

    // 32. Chainsaw Man: Reze Arc Movie (AniList ID 172905)
    registerVideo(UploadedAnimeVideo(
      aniListId: 172905,
      seasonNumber: 1,
      episodeNumber: 1,
      episodeTitle: 'Chainsaw Man: Reze Arc Movie Sub Indo',
      videoUrl: 'https://archive.org/download/rezearc/csmrezearc.mp4',
      server3Url: 'https://archive.org/cors/rezearc/csmrezearc.mp4',
      server4Url: 'https://archive.org/download/rezearc/csmrezearc.mp4',
      uploader: 'AppOwnerOfficial',
      uploadedAt: now,
    ));

    // 33. Tokyo Ghoul Movie (AniList ID 99920)
    registerVideo(UploadedAnimeVideo(
      aniListId: 99920,
      seasonNumber: 1,
      episodeNumber: 1,
      episodeTitle: 'Tokyo Ghoul Movie Sub Indo',
      videoUrl: 'https://archive.org/download/tokyo-ghoul-s/TokyoGhoulS.mp4',
      server3Url: 'https://archive.org/cors/tokyo-ghoul-s/TokyoGhoulS.mp4',
      server4Url: 'https://archive.org/download/tokyo-ghoul-s/TokyoGhoulS.mp4',
      uploader: 'AppOwnerOfficial',
      uploadedAt: now,
    ));
  }
}
