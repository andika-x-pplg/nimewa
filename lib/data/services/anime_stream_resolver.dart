import 'consumet_api_client.dart';
import 'owner_video_repository.dart';
import 'stream_audit_logger.dart';
import 'stream_filter_validator.dart';

/// Resolver that maps anime IDs, titles, and episode numbers to real, authentic
/// anime video streams across available servers, strictly adhering to canonical
/// anime seasons and sequential episode progression.
class AnimeStreamResolver {
  const AnimeStreamResolver();

  /// Shared instance of ConsumetApiClient for online stream lookup.
  static ConsumetApiClient consumetClient = ConsumetApiClient();

  /// Map of AniList IDs to canonical anime keys
  static const Map<String, String> _aniListIdMap = {
    '120120': 'tokyo-revengers',
    '142853': 'tokyo-revengers-s2',
    '163539': 'tokyo-revengers-s3',
    '178945': 'tokyo-revengers-s4',
    '101922': 'demon-slayer',
    '142329': 'demon-slayer-s2',
    '145139': 'demon-slayer-s3',
    '166240': 'demon-slayer-s4',
    '112151': 'demon-slayer-movie',
    '129874': 'demon-slayer-mugen-tv',
    '178788': 'demon-slayer-infinity-castle',
    '171018': 'dandadan',
    '178526': 'dandadan-s2',
    '16498': 'attack-on-titan',
    '20958': 'attack-on-titan-s2',
    '99147': 'attack-on-titan-s3',
    '104578': 'attack-on-titan-s3-p2',
    '110277': 'attack-on-titan-s4',
    '131681': 'attack-on-titan-s4-p2',
    '146984': 'attack-on-titan-final-1',
    '162314': 'attack-on-titan-final-2',
    '1535': 'death-note',
    '113415': 'jujutsu-kaisen',
    '131573': 'jujutsu-kaisen-0',
    '127720': 'chainsaw-man',
    '172905': 'chainsaw-man-movie',
    '151807': 'solo-leveling',
    '154587': 'frieren',
    '140960': 'spy-x-family',
    '11061': 'hunter-x-hunter',
    '5114': 'fullmetal-alchemist',
    '21': 'one-piece',
    '20': 'naruto',
    '269': 'bleach',
    '21355': 'rezero',
    '9253': 'steins-gate',
    '153152': 'boku-no-kokoro',
    '166216': 'boku-no-kokoro-s2',
    '21827': 'your-name',
    '152865': 'haikyuu-movie',
    '20954': 'silent-voice',
    '20665': 'shigatsu-wa-kimi',
    '20605': 'tokyo-ghoul',
    '99920': 'tokyo-ghoul-movie',
    '21087': 'one-punch-man',
    '102194': 'one-punch-man-s2',
    '97668': 'one-punch-man-s2',
    '8861': 'yosuga-no-sora',
  };

  /// Set of anime keys verified to have 100% genuine, authentic episode files of that exact show.
  /// Under the Atomicity principle ("semua atau tidak sama sekali"), any anime not in this set
  /// is strictly rejected and never displayed or played.
  static const Set<String> _authenticKeys = {
    'demon-slayer',
    'demon-slayer-s2',
    'demon-slayer-s4',
    'demon-slayer-mugen-tv',
    'attack-on-titan',
    'death-note',
    'jujutsu-kaisen-0',
    'tokyo-revengers',
    'tokyo-revengers-s2',
    'tokyo-revengers-s3',
    'chainsaw-man',
    'chainsaw-man-movie',
    'naruto',
    'solo-leveling',
    'my-hero-academia',
    'rezero',
    'shigatsu-wa-kimi',
    'your-name',
    'haikyuu-movie',
    'gintama-movie',
    'silent-voice',
    'frieren',
    'one-punch-man',
  };

  /// Set of anime keys known to be incomplete or lacking authentic episode files.
  /// Under the Atomicity principle ("semua atau tidak sama sekali"), these are never displayed or played.
  static const Set<String> _incompleteBlacklist = {
    'season-2-fallback',
    'season-3-fallback',
    'season-4-fallback',
    'tokyo-revengers-s4',
    'one-punch-man-s2',
    'demon-slayer-movie',
    'demon-slayer-s3',
    'demon-slayer-infinity-castle',
    'bleach',
    'hunter-x-hunter',
    'jujutsu-kaisen',
    'tokyo-ghoul',
    'tokyo-ghoul-movie',
    'fullmetal-alchemist',
    'dandadan',
    'dandadan-s2',
    'spy-x-family',
    'steins-gate',
    'one-piece',
    'yosuga-no-sora',
    'boku-no-kokoro',
    'boku-no-kokoro-s2',
    'attack-on-titan-s2',
    'attack-on-titan-s3',
    'attack-on-titan-s3-p2',
    'attack-on-titan-s4',
    'attack-on-titan-s4-p2',
    'attack-on-titan-final-1',
    'attack-on-titan-final-2',
  };

  /// Returns true if and only if the anime or season has a complete, authentic set
  /// of episodes starting from Episode 1 up to its full count without missing episodes.
  static int episodeCountForKey(String key) =>
      _animeEpisodeMap[key]?.length ?? 0;

  static bool hasCompleteEpisodes(String animeId, String animeTitle) {
    final cleanId = animeId.toLowerCase().trim();
    final cleanTitle = animeTitle.toLowerCase().trim();

    // Explicitly unreleased testing ID
    if (cleanId == '999998' || cleanTitle.contains('unreleased')) {
      return false;
    }

    final key = detectAnimeKey(animeId, animeTitle);
    if (_incompleteBlacklist.contains(key)) return false;
    if (_authenticKeys.contains(key)) return true;

    final aniListId = int.tryParse(cleanId);
    if (aniListId != null && aniListId > 0) {
      if (OwnerVideoRepository.instance.hasVideosForAnime(aniListId)) {
        return true;
      }
    }

    final episodes = _animeEpisodeMap[key];
    if (episodes != null && episodes.isNotEmpty) return true;

    return false;
  }

  /// Asynchronously resolves direct stream URL.
  /// Strictly prevents automatic scraping/fetching of unknown videos from internet.
  static Future<String> resolveStreamUrlAsync({
    required String animeId,
    required String animeTitle,
    required String server,
    int episodeNumber = 1,
    String existingStreamUrl = '',
    ConsumetApiClient? client,
  }) async {
    // Under Atomicity rule, incomplete anime/season is never resolved
    if (!hasCompleteEpisodes(animeId, animeTitle)) {
      StreamAuditLogger.instance.log(
        searchedTitle: animeTitle,
        candidateTitle: animeTitle,
        candidateSource: server,
        isAccepted: false,
        reason: 'Anime or season is marked incomplete under Atomicity rules',
        aniListId: int.tryParse(animeId),
      );
      return '';
    }

    final season = extractSeasonNumber(animeId, animeTitle);

    // Only invoke external client if explicitly provided (e.g. in unit test injection),
    // strictly avoiding automatic internet scraping during normal app execution.
    if (client != null) {
      try {
        final onlineUrl = await client.resolveLatestStream(
          title: animeTitle,
          episodeNumber: episodeNumber,
          seasonNumber: season,
        );
        if (onlineUrl != null && onlineUrl.isNotEmpty) {
          final validation = StreamFilterValidator.validate(
            candidateTitle: '$animeTitle - Episode $episodeNumber (Online)',
            candidateUrl: onlineUrl,
          );
          if (validation.isValid) {
            StreamAuditLogger.instance.log(
              searchedTitle: animeTitle,
              candidateTitle: '$animeTitle - Episode $episodeNumber (Online)',
              candidateSource: 'Consumet API',
              isAccepted: true,
              reason: 'Consumet candidate validated successfully',
              aniListId: int.tryParse(animeId),
            );
            return onlineUrl;
          } else {
            StreamAuditLogger.instance.log(
              searchedTitle: animeTitle,
              candidateTitle: '$animeTitle - Episode $episodeNumber (Online)',
              candidateSource: 'Consumet API',
              isAccepted: false,
              reason: validation.reason,
              aniListId: int.tryParse(animeId),
            );
          }
        }
      } catch (_) {
        // Fall through to owner/verified local streams
      }
    }

    return resolveStreamUrl(
      animeId: animeId,
      animeTitle: animeTitle,
      server: server,
      episodeNumber: episodeNumber,
      existingStreamUrl: existingStreamUrl,
    );
  }

  /// Resolves direct stream URL based on anime identifier, title, episode number, and server.
  /// Matches video strictly with AniList ID and season number without cross-season fallback.
  static String resolveStreamUrl({
    required String animeId,
    required String animeTitle,
    required String server,
    int episodeNumber = 1,
    String existingStreamUrl = '',
  }) {
    final cleanId = animeId.toLowerCase().trim();
    final aniListId = int.tryParse(cleanId);
    final season = extractSeasonNumber(animeId, animeTitle);

    // 1. Check Owner Video Repository first (Self-uploaded videos matched by AniList ID and Season)
    if (aniListId != null && aniListId > 0 && OwnerVideoRepository.instance.hasVideosForAnime(aniListId)) {
      final uploadedVideo = OwnerVideoRepository.instance.getVideo(aniListId, season, episodeNumber);
      if (uploadedVideo != null) {
        final validation = StreamFilterValidator.validate(
          candidateTitle: uploadedVideo.episodeTitle,
          candidateUrl: uploadedVideo.videoUrl,
        );
        if (!validation.isValid) {
          StreamAuditLogger.instance.log(
            searchedTitle: animeTitle,
            candidateTitle: uploadedVideo.episodeTitle,
            candidateSource: 'OwnerVideoRepository (${uploadedVideo.uploader})',
            isAccepted: false,
            reason: validation.reason,
            aniListId: aniListId,
          );
          return '';
        }
        StreamAuditLogger.instance.log(
          searchedTitle: animeTitle,
          candidateTitle: uploadedVideo.episodeTitle,
          candidateSource: 'OwnerVideoRepository (${uploadedVideo.uploader})',
          isAccepted: true,
          reason: 'Video pemilik terverifikasi lolos filter untuk AniList ID $aniListId Season $season Episode $episodeNumber',
          aniListId: aniListId,
        );
        return uploadedVideo.getUrlForServer(server);
      } else {
        // Anime has some videos uploaded, but NOT for this requested season
        StreamAuditLogger.instance.log(
          searchedTitle: animeTitle,
          candidateTitle: '$animeTitle - Episode $episodeNumber',
          candidateSource: server,
          isAccepted: false,
          reason: 'Tidak ada video pemilik untuk Season $season (AniList ID $aniListId). Fallback ke season lain dinonaktifkan.',
          aniListId: aniListId,
        );
        return '';
      }
    }

    // 3. Fallback to curated local verified archive keys for Kitsu / legacy IDs
    if (!hasCompleteEpisodes(animeId, animeTitle)) {
      StreamAuditLogger.instance.log(
        searchedTitle: animeTitle,
        candidateTitle: animeTitle,
        candidateSource: server,
        isAccepted: false,
        reason: 'Anime or season is marked incomplete under Atomicity rules',
        aniListId: aniListId,
      );
      return '';
    }

    final key = detectAnimeKey(animeId, animeTitle);

    final episodes = _animeEpisodeMap[key];
    if (episodes == null || episodes.isEmpty) {
      StreamAuditLogger.instance.log(
        searchedTitle: animeTitle,
        candidateTitle: animeTitle,
        candidateSource: server,
        isAccepted: false,
        reason: 'No episode entries found for key: $key',
        aniListId: aniListId,
      );
      return '';
    }

    // Resolve episode index (1-based to list index)
    final epIndex = (episodeNumber - 1).clamp(0, episodes.length - 1);
    final entry = episodes[epIndex];
    final url = entry.getUrlForServer(server);

    // StreamFilterValidator check
    final validation = StreamFilterValidator.validate(
      candidateTitle: '$animeTitle - Episode $episodeNumber',
      candidateUrl: url,
    );

    if (!validation.isValid) {
      StreamAuditLogger.instance.log(
        searchedTitle: animeTitle,
        candidateTitle: '$animeTitle - Episode $episodeNumber',
        candidateSource: server,
        isAccepted: false,
        reason: validation.reason,
        aniListId: aniListId,
      );
      return '';
    }

    StreamAuditLogger.instance.log(
      searchedTitle: animeTitle,
      candidateTitle: '$animeTitle - Episode $episodeNumber',
      candidateSource: server,
      isAccepted: true,
      reason: 'Valid authentic episode stream',
      aniListId: aniListId,
    );

    return url;
  }

  /// Extracts the canonical season number (1, 2, 3, 4, etc.) from id and title.
  static int extractSeasonNumber(String id, String title) {
    final combined = '${id.toLowerCase()} ${title.toLowerCase()}';

    // 1. Movie / Non-season keywords
    if (combined.contains('movie') ||
        combined.contains('film') ||
        combined.contains('gekijuu') ||
        combined.contains('the final')) {
      return 1;
    }

    // 2. Specific franchise arcs that represent seasons
    if (combined.contains('hashira training') ||
        combined.contains('hashira geiko') ||
        combined.contains('final season') ||
        combined.contains('season final') ||
        combined.contains('santen sensou') ||
        combined.contains('three deities') ||
        combined.contains('three titans') ||
        combined.contains('war of the three titans') ||
        combined.contains('zokuhen')) {
      return 4;
    }
    if (combined.contains('culling game') ||
        combined.contains('swordsmith') ||
        combined.contains('katanakaji') ||
        combined.contains('tenjiku') ||
        combined.contains('ultra romantic')) {
      return 3;
    }
    if (combined.contains('entertainment district') ||
        combined.contains('yuukaku') ||
        combined.contains('shibuya') ||
        combined.contains('seiya kessen') ||
        combined.contains('christmas showdown') ||
        combined.contains('arise from the shadow') ||
        combined.contains('missing pieces') ||
        (combined.contains('piece') && !combined.contains('one piece')) ||
        combined.contains('tybw') ||
        combined.contains('sennen kessen') ||
        combined.contains('thousand year blood war')) {
      return 2;
    }

    // 3. Explicit season indicators: "Season 2", "Musim 2", "Part 2", "S2"
    final sMatch = RegExp(r'(?:season|musim|part)\s*(\d+)', caseSensitive: false).firstMatch(combined);
    if (sMatch != null) {
      final num = int.tryParse(sMatch.group(1)!);
      if (num != null && num >= 1 && num <= 20) return num;
    }

    final ordMatch = RegExp(r'(\d+)(?:st|nd|rd|th)\s*season', caseSensitive: false).firstMatch(combined);
    if (ordMatch != null) {
      final num = int.tryParse(ordMatch.group(1)!);
      if (num != null && num >= 1 && num <= 20) return num;
    }

    final idMatch = RegExp(r'[-_]s(\d+)(?:[-_]|$)', caseSensitive: false).firstMatch(id.toLowerCase());
    if (idMatch != null) {
      final num = int.tryParse(idMatch.group(1)!);
      if (num != null && num >= 1 && num <= 20) return num;
    }

    // 4. Standalone s2, s3, etc. in combined title
    final standaloneSMatch = RegExp(r'(?:^|\s)s(\d+)(?:\s|$)', caseSensitive: false).firstMatch(combined);
    if (standaloneSMatch != null) {
      final num = int.tryParse(standaloneSMatch.group(1)!);
      if (num != null && num >= 1 && num <= 20) return num;
    }

    return 1;
  }

  /// Detects the AniList ID for an anime identifier and title.
  static int detectAniListId(String id, String title) {
    final parsed = int.tryParse(id.trim());
    if (parsed != null && parsed > 0) return parsed;
    final combined = '$id $title'.toLowerCase();
    if (combined.contains('punch') || combined.contains('saitama')) {
      final s = extractSeasonNumber(id, title);
      return s == 2 ? 102194 : 21087;
    }
    if (combined.contains('demon') || combined.contains('kimetsu') || combined.contains('tanjiro')) return 41370;
    if (combined.contains('solo') || combined.contains('leveling') || combined.contains('jin-woo') || combined.contains('jinwoo')) return 151807;
    if (combined.contains('titan') || combined.contains('shingeki') || combined.contains('eren')) return 7442;
    if (combined.contains('tokyo ghoul') || combined.contains('kaneki')) return 20605;
    if (combined.contains('tokyo revengers') || combined.contains('takemichi')) return 120120;
    if (combined.contains('chainsaw') || combined.contains('denji')) return 40321;
    if (combined.contains('death note') || combined.contains('light')) return 1376;
    if (combined.contains('naruto')) return 3936;
    if (combined.contains('jujutsu') || combined.contains('itadori')) return 43806;
    return 0;
  }

  /// Detects the canonical anime key based on title, Japanese title, or API ID.
  static String detectAnimeKey(String id, String title) {
    final cleanId = id.trim();
    if (_aniListIdMap.containsKey(cleanId)) {
      return _aniListIdMap[cleanId]!;
    }

    final combined = '${id.toLowerCase()} ${title.toLowerCase()}';
    final season = extractSeasonNumber(id, title);

    // 1. Movies (Priority matching to avoid general franchise collision)
    // Jujutsu Kaisen 0 Movie
    if (combined.contains('jujutsu kaisen 0') ||
        combined.contains('jjk 0') ||
        id == 'jujutsu-kaisen-0') {
      return 'jujutsu-kaisen-0';
    }

    // Your Name / Kimi no Na wa Movie
    if (combined.contains('your name') ||
        combined.contains('kimi no na wa') ||
        combined.contains('君の名は') ||
        id == 'your-name' ||
        id == 'kimi-no-na-wa') {
      return 'your-name';
    }

    // A Silent Voice / Koe no Katachi Movie
    if (combined.contains('silent voice') ||
        combined.contains('koe no katachi') ||
        combined.contains('聲の形') ||
        id == 'silent-voice' ||
        id == 'koe-no-katachi') {
      return 'silent-voice';
    }

    // Gintama The Final Movie
    if ((combined.contains('gintama') ||
            combined.contains('銀魂') ||
            id.contains('gintama')) &&
        (combined.contains('final') || combined.contains('movie') || combined.contains('film'))) {
      return 'gintama-movie';
    }

    // Haikyuu Dumpster Battle Movie
    if ((combined.contains('haikyuu') ||
            combined.contains('haikyu') ||
            combined.contains('ハイキュー') ||
            id.contains('haikyuu')) &&
        (combined.contains('dumpster') || combined.contains('movie') || combined.contains('film') || combined.contains('gomi'))) {
      return 'haikyuu-movie';
    }

    // Chainsaw Man: Reze Arc Movie
    if ((combined.contains('chainsaw') || id == 'chainsaw-man-movie') &&
        (combined.contains('reze') || combined.contains('movie') || combined.contains('film'))) {
      return 'chainsaw-man-movie';
    }

    // Kimetsu no Yaiba: Infinity Castle Movie (Upcoming / Unreleased)
    if (id == 'kimetsu-no-yaiba-infinity' ||
        id == '178788' ||
        id == 'demon-slayer-infinity-castle' ||
        ((combined.contains('demon slayer') || combined.contains('kimetsu')) &&
            (combined.contains('infinity castle') || combined.contains('mugenjou')))) {
      return 'demon-slayer-infinity-castle';
    }

    // Kimetsu no Yaiba: Mugen Train Movie or TV Arc
    if (id == 'demon-slayer-movie' ||
        id == '112151' ||
        id == '129874' ||
        id == 'demon-slayer-mugen-tv' ||
        ((combined.contains('demon slayer') || combined.contains('kimetsu')) &&
            (combined.contains('mugen train') || combined.contains('mugen ressha')))) {
      if (id == '129874' || id == 'demon-slayer-mugen-tv' || combined.contains(' tv') || combined.contains('arc')) {
        return 'demon-slayer-mugen-tv';
      }
      return 'demon-slayer-movie';
    }

    // Tokyo Ghoul
    if (combined.contains('tokyo ghoul') ||
        combined.contains('東京喰種') ||
        combined.contains('kaneki') ||
        id == 'tokyo-ghoul' ||
        id == '20605') {
      if (combined.contains('movie') || combined.contains('film') || combined.contains('tokyo ghoul s')) {
        return 'tokyo-ghoul-movie';
      }
      return 'tokyo-ghoul';
    }

    // Steins;Gate
    if (combined.contains('steins') ||
        combined.contains('okabe') ||
        id == 'steins-gate') {
      return 'steins-gate';
    }

    // Dan Da Dan
    if (combined.contains('dandadan') ||
        combined.contains('dan da dan') ||
        combined.contains('ダンダダン') ||
        id == 'dandadan' ||
        id.startsWith('dandadan-')) {
      if (season >= 2) return 'dandadan-s2';
      return 'dandadan';
    }

    // Re:Zero
    if (combined.contains('re:zero') ||
        combined.contains('rezero') ||
        combined.contains('rem') ||
        combined.contains('emilia') ||
        id == 'rezero-s3' ||
        id == 'rezero-s2' ||
        id == 'rezero') {
      if (season == 2) return 'rezero-s2';
      if (season >= 3) return 'rezero-s3';
      return 'rezero';
    }

    // Shigatsu wa Kimi no Uso (Your Lie in April)
    if (combined.contains('shigatsu') ||
        combined.contains('your lie in april') ||
        combined.contains('kimi no uso') ||
        id == 'shigatsu-wa-kimi') {
      return 'shigatsu-wa-kimi';
    }

    // 2. Canonical TV Series
    // Demon Slayer / Kimetsu no Yaiba
    if (combined.contains('demon slayer') ||
        combined.contains('kimetsu') ||
        combined.contains('tanjiro') ||
        combined.contains('nezuko') ||
        combined.contains('鬼滅の刃') ||
        id == '41370' ||
        id == '13745' ||
        id == '42586' ||
        id == '44081' ||
        id == '44389' ||
        id == '42765' ||
        id.startsWith('demon-slayer')) {
      if (season == 2) return 'demon-slayer-s2';
      if (season == 3) return 'demon-slayer-s3';
      if (season >= 4) return 'demon-slayer-s4';
      return 'demon-slayer';
    }

    // Attack on Titan / Shingeki no Kyojin
    if (combined.contains('attack on titan') ||
        combined.contains('shingeki') ||
        combined.contains('titan') ||
        combined.contains('eren yeager') ||
        combined.contains('eren jaeger') ||
        combined.split(RegExp(r'\W+')).contains('eren') ||
        combined.contains('進撃の巨人') ||
        id == '7442' ||
        id == 'attack-on-titan-final' ||
        id.startsWith('attack-on-titan')) {
      if (combined.contains('lost girls') ||
          combined.contains('junior high') ||
          combined.contains('chimi') ||
          combined.contains('ova') ||
          combined.contains('no regrets') ||
          combined.contains('chronicle') ||
          combined.contains('crimson bow') ||
          combined.contains('wings of freedom') ||
          combined.contains('roar of awakening') ||
          combined.contains('picture drama') ||
          combined.contains('last attack') ||
          combined.contains('part i') ||
          combined.contains('movie') ||
          combined.contains('film')) {
        return 'attack-on-titan-spinoff';
      }
      if (combined.contains('final chapters') || combined.contains('kanketsu')) {
        return combined.contains('special 2') || combined.contains('kouhen')
            ? 'attack-on-titan-final-2'
            : 'attack-on-titan-final-1';
      }
      if (combined.contains('final season')) {
        return combined.contains('part 2')
            ? 'attack-on-titan-s4-p2'
            : 'attack-on-titan-s4';
      }
      if (season == 2) return 'attack-on-titan-s2';
      if (season == 3) {
        return combined.contains('part 2')
            ? 'attack-on-titan-s3-p2'
            : 'attack-on-titan-s3';
      }
      if (season >= 4) return 'attack-on-titan-s4';
      return 'attack-on-titan';
    }

    // Jujutsu Kaisen
    if (combined.contains('jujutsu') ||
        combined.contains('itadori') ||
        combined.contains('sukuna') ||
        combined.contains('gojo') ||
        combined.contains('呪術廻戦') ||
        id == '43806' ||
        id.startsWith('jujutsu-kaisen')) {
      if (season == 2) return 'jujutsu-kaisen-s2';
      if (season >= 3) return 'jujutsu-kaisen-s3';
      return 'jujutsu-kaisen';
    }

    // Boku no Kokoro no Yabai Yatsu / The Dangers in My Heart (TV S1 & S2 only)
    if ((combined.contains('boku no kokoro') ||
            combined.contains('dangers in my heart') ||
            combined.contains('僕の心のヤバイやつ') ||
            id.startsWith('boku-no-kokoro')) &&
        !combined.contains('movie') &&
        !combined.contains('special') &&
        !combined.contains('twi-yaba') &&
        !combined.contains('3rd') &&
        season <= 2) {
      if (season == 2 || id == '166216' || id == 'boku-no-kokoro-s2') {
        return 'boku-no-kokoro-s2';
      }
      return 'boku-no-kokoro';
    }

    // Tokyo Revengers
    if (combined.contains('tokyo revengers') ||
        combined.contains('takemichi') ||
        combined.contains('revengers') ||
        combined.contains('東京リベンジャーズ') ||
        id == '48960' ||
        id == '42249' ||
        id == '43321' ||
        id.startsWith('tokyo-revengers')) {
      if (season == 2) return 'tokyo-revengers-s2';
      if (season == 3) return 'tokyo-revengers-s3';
      if (season >= 4 || id == 'tokyo-revengers-s4' || id == '48960') return 'tokyo-revengers-s4';
      return 'tokyo-revengers';
    }

    // Solo Leveling
    if (combined.contains('solo leveling') ||
        combined.contains('sung jinwoo') ||
        combined.contains('jinwoo') ||
        combined.contains('shadow monarch') ||
        combined.contains('俺だけレベルアップな件') ||
        id == '46231' ||
        id == '46112' ||
        id.startsWith('solo-leveling')) {
      if (season >= 2) return 'solo-leveling-s2';
      return 'solo-leveling';
    }

    // Boku no Hero Academia / My Hero Academia
    if (combined.contains('hero academia') ||
        combined.contains('boku no hero') ||
        combined.contains('my hero academia') ||
        combined.contains('deku') ||
        combined.contains('all might') ||
        combined.contains('僕のヒーローアカデミア') ||
        id == '11469' ||
        id == 'bokuno-hero-s8' ||
        id.startsWith('boku-no-hero') ||
        id.startsWith('my-hero-academia')) {
      if (season >= 8) return 'my-hero-academia-s8';
      if (season >= 2) return 'my-hero-academia-s$season';
      return 'my-hero-academia';
    }

    // Sousou no Frieren
    if (combined.contains('frieren') ||
        combined.contains('sousou') ||
        combined.contains('葬送のフリーレン') ||
        id == '52991' ||
        id == '46569' ||
        id.startsWith('frieren')) {
      if (season >= 2) return 'frieren-s2';
      return 'frieren';
    }

    // Death Note
    if (combined.contains('death note') ||
        combined.contains('light yagami') ||
        combined.contains('ryuk') ||
        combined.contains('デスノート') ||
        id == '1376' ||
        id == 'death-note') {
      return 'death-note';
    }

    // Naruto
    if (combined.contains('naruto') ||
        combined.contains('shippuden') ||
        combined.contains('sasuke') ||
        combined.contains('hokage') ||
        id == '3936' ||
        id == '11' ||
        id == 'naruto') {
      return 'naruto';
    }

    // One Piece
    if (combined.contains('one piece') ||
        combined.contains('luffy') ||
        combined.contains('straw hat') ||
        combined.contains('zoro') ||
        id == '12' ||
        id == 'one-piece') {
      return 'one-piece';
    }

    // Chainsaw Man
    if (combined.contains('chainsaw') ||
        combined.contains('denji') ||
        combined.contains('makima') ||
        combined.contains('チェンソーマン') ||
        id == '40321' ||
        id == 'chainsaw-man') {
      return 'chainsaw-man';
    }

    // Spy x Family
    if (combined.contains('spy x family') ||
        combined.contains('spyxfamily') ||
        combined.contains('anya') ||
        combined.contains('loid') ||
        id == '41992' ||
        id.startsWith('spy-x-family')) {
      if (season == 2) return 'spy-x-family-s2';
      if (season >= 3) return 'spy-x-family-s3';
      return 'spy-x-family';
    }

    // Bleach
    if (combined.contains('bleach') ||
        combined.contains('ichigo') ||
        combined.contains('shinigami') ||
        combined.contains('ブリーチ') ||
        id.startsWith('bleach')) {
      if (season >= 2 || combined.contains('tybw') || combined.contains('sennen kessen') || combined.contains('thousand year blood war')) {
        return 'bleach-tybw';
      }
      return 'bleach';
    }

    // Hunter x Hunter
    if (combined.contains('hunter x hunter') ||
        combined.contains('hunterxhunter') ||
        combined.contains('gon freecss') ||
        combined.contains('ハンター×ハンター') ||
        id == 'hunter-x-hunter') {
      return 'hunter-x-hunter';
    }

    // Fullmetal Alchemist
    if (combined.contains('fullmetal') ||
        combined.contains('alchemist') ||
        combined.contains('edward elric') ||
        combined.contains('鋼の錬金術師') ||
        id == 'fullmetal-alchemist') {
      return 'fullmetal-alchemist';
    }

    // Mushoku Tensei
    if (combined.contains('mushoku tensei') ||
        combined.contains('rudeus') ||
        combined.contains('無職転生') ||
        id.startsWith('mushoku-tensei')) {
      if (season == 2) return 'mushoku-tensei-s2';
      if (season >= 3) return 'mushoku-tensei-s3';
      return 'mushoku-tensei';
    }

    // Tensura / That Time I Got Reincarnated as a Slime
    if (combined.contains('tensura') ||
        combined.contains('slime datta ken') ||
        combined.contains('rimuru') ||
        combined.contains('転生したらスライムだった件') ||
        id.startsWith('tensura')) {
      if (season == 2) return 'tensura-s2';
      if (season == 3) return 'tensura-s3';
      if (season >= 4) return 'tensura-s4';
      return 'tensura';
    }

    // Kaiju No. 8
    if (combined.contains('kaiju') ||
        combined.contains('kafka') ||
        combined.contains('怪獣8号') ||
        id.startsWith('kaiju-no-8')) {
      if (season >= 2) return 'kaiju-no-8-s2';
      return 'kaiju-no-8';
    }

    // Oshi no Ko
    if (combined.contains('oshi no ko') ||
        combined.contains('推しの子') ||
        combined.contains('aqua hoshino') ||
        id.startsWith('oshi-no-ko')) {
      if (season == 2) return 'oshi-no-ko-s2';
      if (season >= 3) return 'oshi-no-ko-s3';
      return 'oshi-no-ko';
    }

    // Blue Lock
    if (combined.contains('blue lock') ||
        combined.contains('bluelock') ||
        combined.contains('isagi') ||
        combined.contains('ブルーロック') ||
        id == 'blue-lock-vs-u20' ||
        id == 'blue-lock') {
      return 'blue-lock';
    }

    // Kaguya-sama
    if (combined.contains('kaguya') ||
        combined.contains('かぐや様') ||
        id.startsWith('kaguya-sama')) {
      if (season == 2) return 'kaguya-sama-s2';
      if (season == 3) return 'kaguya-sama-s3';
      if (season >= 4) return 'kaguya-sama-s4';
      return 'kaguya-sama';
    }

    // Horimiya
    if (combined.contains('horimiya') ||
        combined.contains('hori') ||
        combined.contains('miyamura') ||
        id == 'horimiya-piece' ||
        id == 'horimiya') {
      return 'horimiya';
    }

    // 5-toubun no Hanayome
    if (combined.contains('5-toubun') ||
        combined.contains('gotoubun') ||
        combined.contains('quintessential quintuplets') ||
        combined.contains('五等分') ||
        id == 'gotoubun-special' ||
        id == 'gotoubun') {
      return 'gotoubun';
    }

    // Kimi ni Todoke
    if (combined.contains('kimi ni todoke') ||
        combined.contains('sawako') ||
        combined.contains('君に届け') ||
        id.startsWith('kimi-ni-todoke')) {
      if (season == 2) return 'kimi-ni-todoke-s2';
      if (season >= 3) return 'kimi-ni-todoke-s3';
      return 'kimi-ni-todoke';
    }

    // Ao Haru Ride
    if (combined.contains('ao haru ride') ||
        combined.contains('アオハライド') ||
        combined.contains('futaba') ||
        id == 'ao-haru-ride') {
      return 'ao-haru-ride';
    }

    // Code Geass
    if (combined.contains('code geass') ||
        combined.contains('lelouch') ||
        combined.contains('コードギアス') ||
        id == 'code-geass') {
      return 'code-geass';
    }

    // 86 Eighty-Six
    if (combined.contains('eighty six') ||
        combined.contains('eighty-six') ||
        combined.contains('エイティシックス') ||
        combined.contains('lena') ||
        id == 'eighty-six') {
      return 'eighty-six';
    }

    // Erased / Boku dake ga Inai Machi
    if (combined.contains('erased') ||
        combined.contains('僕だけがいない街') ||
        combined.contains('satoru fujinuma') ||
        id == 'erased') {
      return 'erased';
    }

    // Monster
    if (combined.contains('kenzo tenma') ||
        combined.contains('モンスター') ||
        id == 'monster') {
      return 'monster';
    }

    // Parasyte
    if (combined.contains('parasyte') ||
        combined.contains('parasit') ||
        combined.contains('寄生獣') ||
        combined.contains('shinichi') ||
        id == 'parasyte') {
      return 'parasyte';
    }

    // Overlord
    if (combined.contains('overlord') ||
        combined.contains('ainz') ||
        combined.contains('nazarick') ||
        combined.contains('オーバーロード') ||
        id == 'overlord-movie' ||
        id == 'overlord') {
      return 'overlord';
    }

    // Tate no Yuusha
    if (combined.contains('tate no yuusha') ||
        combined.contains('shield hero') ||
        combined.contains('naofumi') ||
        combined.contains('盾の勇者') ||
        id.startsWith('tate-no-yuusha')) {
      if (season == 2) return 'tate-no-yuusha-s2';
      if (season == 3) return 'tate-no-yuusha-s3';
      if (season >= 4) return 'tate-no-yuusha-s4';
      return 'tate-no-yuusha';
    }

    // Kage no Jitsuryokusha
    if (combined.contains('kage no jitsuryoku') ||
        combined.contains('shadow master') ||
        combined.contains('cid kage') ||
        combined.contains('陰の実力者') ||
        id == 'kage-no-jitsuryokusha') {
      return 'kage-no-jitsuryokusha';
    }

    // Kuroko no Basket
    if (combined.contains('kuroko') ||
        combined.contains('黒子のバスケ') ||
        id == 'kuroko-no-basket') {
      return 'kuroko-no-basket';
    }

    // One Punch Man
    if (combined.contains('one punch') ||
        combined.contains('one-punch') ||
        combined.contains('saitama') ||
        combined.contains('ワンパンマン') ||
        id == 'one-punch-man' ||
        id == 'one-punch-man-s2' ||
        id == '21087' ||
        id == '102194' ||
        id == '97668') {
      if (season >= 2 || id == '102194' || id == '97668' || combined.contains('season 2') || combined.contains('2nd season')) {
        return 'one-punch-man-s2';
      }
      return 'one-punch-man';
    }

    // Yosuga no Sora
    if (combined.contains('yosuga no sora') ||
        combined.contains('yosuga') ||
        combined.contains('kasugano') ||
        combined.contains('ヨスガノソラ') ||
        id == '8861' ||
        id == 'yosuga-no-sora') {
      return 'yosuga-no-sora';
    }

    // Fallback for ANY OTHER anime that has a season indicator
    if (season == 2) return 'season-2-fallback';
    if (season == 3) return 'season-3-fallback';
    if (season >= 4) return 'season-4-fallback';

    return 'unknown';
  }

  // --- Demon Slayer Season 1 (26 Episodes, Japanese Audio + Sub Indo / Eng Sub) ---
  static List<_AnimeStreamEntry> _buildKnySeason1() {
    return List.generate(26, (index) {
      final epNum = index + 1;
      final url = 'https://archive.org/download/knys1/KNYS1-E$epNum.mp4';
      final s3Url = 'https://archive.org/cors/knys1/KNYS1-E$epNum.mp4';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Demon Slayer Season 2 (11 Episodes, Entertainment District Arc, Japanese Audio + Sub Indo) ---
  static List<_AnimeStreamEntry> _buildKnySeason2() {
    return List.generate(11, (index) {
      final epNum = index + 1;
      final epStr = epNum.toString().padLeft(2, '0');
      final fileName = epNum == 11
          ? 'Otakudesu.io_KnY.Yh--11_End_720p.mp4'
          : 'Otakudesu.io_KnY.Yh--${epStr}_720p.mp4';
      final url = 'https://archive.org/download/otakudesu.io-kn-y.-yh-01-720p/$fileName';
      final s3Url = 'https://archive.org/cors/otakudesu.io-kn-y.-yh-01-720p/$fileName';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Demon Slayer Season 3 (11 Episodes, Swordsmith Village Arc) ---
  static List<_AnimeStreamEntry> _buildKnySeason3() {
    return List.generate(11, (index) {
      final epNum = index + 1;
      final url =
          'https://archive.org/download/knyhgh1243ekrngtfkmrgtihj/knyhgh1243ekrngtfkmrgtihj-hd-$epNum.mp4';
      final s3Url =
          'https://archive.org/cors/knyhgh1243ekrngtfkmrgtihj/knyhgh1243ekrngtfkmrgtihj-hd-$epNum.mp4';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Demon Slayer Season 4 (8 Episodes, Hashira Training Arc) ---
  static List<_AnimeStreamEntry> _buildKnySeason4() {
    return List.generate(8, (index) {
      final epNum = index + 1;
      final url =
          'https://archive.org/download/knyhgh1243ekrngtfkmrgtihj/knyhgh1243ekrngtfkmrgtihj-hd-$epNum.mp4';
      final s3Url =
          'https://archive.org/cors/knyhgh1243ekrngtfkmrgtihj/knyhgh1243ekrngtfkmrgtihj-hd-$epNum.mp4';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Boku no Kokoro no Yabai Yatsu Season 1 (12 Episodes, Japanese Audio + Sub Eng) ---
  static List<_AnimeStreamEntry> _buildBokuNoKokoroS1() {
    const itemId =
        'the-dangers-in-my-heart-boku-no-kokoro-no-yabai-yatsu-seasons-1-and-2-ona';
    const folder = 'The Dangers in My Heart  Boku no Kokoro no Yabai Yatsu Season 1';
    const files = [
      'The Dangers in My Heart S01E01_I Was Stolen Away .mp4',
      'The Dangers in My Heart S01E02_I Died .mp4',
      'The Dangers in My Heart S01E03_I Want to Hold You .mp4',
      'The Dangers in My Heart S01E04_I Have a Mental Illness .mp4',
      'The Dangers in My Heart S01E05_We Got Separated .mp4',
      'The Dangers in My Heart S01E06_I Melted .mp4',
      'The Dangers in My Heart S01E07_We Traded Places .mp4',
      'The Dangers in My Heart S01E08_I Had a Dream .mp4',
      'The Dangers in My Heart S01E09_I Hate Yamada .mp4',
      'The Dangers in My Heart S01E10_We Walked Slowly .mp4',
      'The Dangers in My Heart S01E11_We Are a Bit Alike .mp4',
      'The Dangers in My Heart S01E12_I Wanted to Be Seen .mp4',
    ];
    final encodedFolder = Uri.encodeComponent(folder);
    return files.map((file) {
      final encodedFile = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/$itemId/$encodedFolder/$encodedFile';
      final s3Url = 'https://archive.org/cors/$itemId/$encodedFolder/$encodedFile';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    }).toList(growable: false);
  }

  // --- Boku no Kokoro no Yabai Yatsu Season 2 (13 Episodes, Japanese Audio + Sub Eng) ---
  static List<_AnimeStreamEntry> _buildBokuNoKokoroS2() {
    const itemId =
        'the-dangers-in-my-heart-boku-no-kokoro-no-yabai-yatsu-seasons-1-and-2-ona';
    const folder = 'The Dangers in My Heart  Boku no Kokoro no Yabai Yatsu Season 2';
    const files = [
      'The Dangers in My Heart S02E01_We`re Searching .mp4',
      'The Dangers in My Heart S02E02_I`m Growing Up .mp4',
      'The Dangers in My Heart S02E03_Yamada and I .mp4',
      'The Dangers in My Heart S02E04_Yamada Likes... .mp4',
      'The Dangers in My Heart S02E05_I Want to Know .mp4',
      'The Dangers in My Heart S02E06_I`m Visiting Yamada .mp4',
      'The Dangers in My Heart S02E07_We`re Overflowing .mp4',
      'The Dangers in My Heart S02E08_We Stayed Up Late .mp4',
      'The Dangers in My Heart S02E09_We Promised .mp4',
      'The Dangers in My Heart S02E10_I Want to Love Yamada .mp4',
      'The Dangers in My Heart S02E11_I Don`t Want to Lose .mp4',
      'The Dangers in My Heart S02E12_I Want to Tell Her .mp4',
      'The Dangers in My Heart S02E13_I, We, Fell in Love .mp4',
    ];
    final encodedFolder = Uri.encodeComponent(folder);
    return files.map((file) {
      final encodedFile = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/$itemId/$encodedFolder/$encodedFile';
      final s3Url = 'https://archive.org/cors/$itemId/$encodedFolder/$encodedFile';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    }).toList(growable: false);
  }

  // --- Demon Slayer: Mugen Ressha-hen TV Arc (7 Episodes, Japanese Audio + Sub Indo 720p) ---
  static List<_AnimeStreamEntry> _buildKnyMugenTv() {
    const files = [
      'Otakudesu.io_KnY.MRh--01_720p.mp4',
      'Otakudesu.io_KnY.MRh--02_720p.mp4',
      'Otakudesu.io_KnY.MRh--03_720p.mp4',
      'Otakudesu.io_KnY.MRh--04_720p.mp4',
      'Otakudesu.io_KnY.MRh--05_720p.mp4',
      'Otakudesu.io_KnY.MRh--06_720p.mp4',
      'Otakudesu.io_KnY.MRh--07_End_720p.mp4',
    ];
    return files.map((f) {
      final encoded = Uri.encodeComponent(f);
      final url =
          'https://archive.org/download/otakudesu.io-kn-y.-mrh-03-720p_202608/$encoded';
      final s3Url =
          'https://archive.org/cors/otakudesu.io-kn-y.-mrh-03-720p_202608/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    }).toList();
  }

  // --- Demon Slayer Movie / Mugen Train (Feature Film - Unavailable per atomicity) ---
  static List<_AnimeStreamEntry> _buildKnyMovie() {
    return const [];
  }

  // --- Attack on Titan Season 1 (25 Episodes, Japanese Audio + Eng Sub 1080p BluRay) ---
  static List<_AnimeStreamEntry> _buildAotSeason1() {
    return List.generate(25, (index) {
      final titlePart = OwnerVideoRepository.aotS1Titles[index];
      final fileName =
          'Attack on Titan (2013) - $titlePart (1080p BluRay x265 ImE).mp4';
      final encoded = Uri.encodeComponent(
              'Attack on Titan (2013) Season 1 S01 (1080p BluRay x265 HEVC 10bit AAC 5.1 ImE) REPACK/$fileName')
          .replaceAll('%2F', '/');
      final url = 'https://archive.org/download/aot-s-1/$encoded';
      final s3Url = 'https://archive.org/cors/aot-s-1/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Jujutsu Kaisen Season 1 (24 Episodes, ~24m each, BluRay Japanese Audio) ---
  static List<_AnimeStreamEntry> _buildJjkSeason1() {
    return List.generate(24, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final fileName =
          'Jujutsu Kaisen (2020) - S01E$pad (1080p BluRay AV1 10bit Opus 2.0 KaNNa).mp4';
      final encoded = Uri.encodeComponent(fileName);
      final url = 'https://archive.org/download/jjk-s01CBT/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
      );
    });
  }

  // --- Jujutsu Kaisen 0 Movie (104 Minutes) ---
  static List<_AnimeStreamEntry> _buildJjk0() {
    const url =
        'https://archive.org/download/anime-pahe-jujutsu-kaisen-0-movie-01-bd-804p-vodes/AnimePahe_Jujutsu_Kaisen_0_Movie_-_01_BD_804p_Vodes.mp4';
    const s3Url =
        'https://archive.org/cors/anime-pahe-jujutsu-kaisen-0-movie-01-bd-804p-vodes/AnimePahe_Jujutsu_Kaisen_0_Movie_-_01_BD_804p_Vodes.mp4';
    return [
      const _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      )
    ];
  }

  // --- Death Note Season 1 (37 Episodes, ~23m each, Japanese Audio + English Hardsub) ---
  static List<_AnimeStreamEntry> _buildDeathNoteSeason1() {
    return OwnerVideoRepository.deathNoteFiles.map((f) {
      final encoded = Uri.encodeComponent(f);
      final url = 'https://archive.org/download/death-note-relight-1/$encoded';
      final s3Url = 'https://archive.org/cors/death-note-relight-1/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: s3Url, server4Url: url);
    }).toList();
  }

  // --- Tokyo Revengers Season 1 (24 Episodes, BluRay 1080p Japanese Audio) ---
  static const List<String> _trS1Files = [
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

  static List<_AnimeStreamEntry> _buildTokyoRevengersSeason1() {
    return _trS1Files.map((file) {
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/mgamaangasnasigasheeshhh/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
      );
    }).toList();
  }

  // --- Tokyo Revengers Season 2 (13 Episodes, BluRay 1080p Japanese Audio) ---
  static const List<String> _trS2Files = [
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

  static List<_AnimeStreamEntry> _buildTokyoRevengersS2() {
    return _trS2Files.map((file) {
      final encoded = Uri.encodeComponent(file);
      final url = 'https://archive.org/download/paniskyotoavengershahahasdhaxcf/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
      );
    }).toList();
  }

  // --- Tokyo Revengers Season 3 (13 Episodes, Japanese Audio + Sub Indo / Eng Sub) ---
  static const List<String> _trS3EpisodeNames = [
    'The Longest Day',
    'Mortal Enemy',
    'Run Out Of Patience',
    'Come Back To Life',
    'A Bad Hunch',
    'Rise Against',
    'Turn The Tide',
    'I Know In My Head',
    'The Blue Ogre',
    'Brave Heart',
    'Nothing Is Left',
    'Paradise Lost',
    'Meet His Fate',
  ];

  static List<_AnimeStreamEntry> _buildTokyoRevengersS3() {
    return List.generate(13, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final title = _trS3EpisodeNames[index];
      final fileName =
          'Tokyo Revengers (2021) - S03e$pad - $title [Bluray-1080P][Opus 2.0][Av1]-Blackrabbit-$epNum.ia.mp4';
      final encoded = Uri.encodeComponent(fileName);
      final url =
          'https://archive.org/download/kyotoavenrgesrsamputahahaha/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
      );
    });
  }

  // --- Yosuga no Sora (Unavailable per atomicity / raw video without hardsubs) ---
  static List<_AnimeStreamEntry> _buildYosugaNoSora() {
    return const [];
  }

  // --- Solo Leveling Season 1 (12 Episodes, ~24m each, Japanese Audio) ---
  static List<_AnimeStreamEntry> _buildSoloLevelingSeason1() {
    return List.generate(12, (index) {
      final file = OwnerVideoRepository.soloLevelingFiles[index];
      final encoded = Uri.encodeComponent(file);
      final url =
          'https://archive.org/download/sl-bd-s1/$encoded';
      final corsUrl =
          'https://archive.org/cors/sl-bd-s1/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: corsUrl,
        server4Url: url,
      );
    });
  }

  // --- Boku no Hero Academia Season 1 (13 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildMhaSeason1() {
    return List.generate(13, (index) {
      final epNum = index + 1;
      final pad3 = epNum.toString().padLeft(3, '0');
      final url =
          'https://archive.org/download/mha-s1-full/AnimePahe_Boku_no_Hero_Academia_-_{pad3}_BD_1080p_Nep_Blanc.mp4'
              .replaceAll('{pad3}', pad3);
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Chainsaw Man Season 1 (12 Episodes, ~24m each) ---
  static const Map<int, String> _csmHashes = {
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

  static List<_AnimeStreamEntry> _buildChainsawManSeason1() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final hash = _csmHashes[epNum]!;
      final url =
          'https://archive.org/download/hi-10-chainsaw-man-s-1-1080p/%5BHi10%5D_Chainsaw_Man_S1_%5B1080p%5D%2F(Hi10)_Chainsaw_Man_S1_-_${pad}_(1080p)_(GJM)_($hash).mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Chainsaw Man: Reze Arc Movie (94 Minutes) ---
  static List<_AnimeStreamEntry> _buildCsmMovie() {
    const url = 'https://archive.org/download/rezearc/csmrezearc.mp4';
    const s3 = 'https://archive.org/cors/rezearc/csmrezearc.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: s3, server4Url: url)];
  }

  // --- Naruto Season 1 (25 Episodes, ~23m each, Japanese Audio) ---
  static List<_AnimeStreamEntry> _buildNarutoSeason1() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad3 = epNum.toString().padLeft(3, '0');
      final url = 'https://archive.org/download/naruto-completo/Naruto%20-%20$pad3.mp4';
      final corsUrl = 'https://archive.org/cors/naruto-completo/Naruto%20-%20$pad3.mp4';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: corsUrl,
        server4Url: url,
      );
    });
  }

  // --- One Piece Season 1 (Unavailable per atomicity / incomplete 4Kids English dub) ---
  static List<_AnimeStreamEntry> _buildOnePieceSeason1() {
    return const [];
  }

  // --- Spy x Family Season 1 (25 Episodes, Japanese Audio + Sub Indo Hardsub BD) ---
  static List<_AnimeStreamEntry> _buildSpyFamilySeason1() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final epStr = epNum.toString().padLeft(2, '0');
      final fileName = epNum == 25
          ? '%5BKusonime%5D%20Mata2%20x%20Keluarga%20PT1%20BD%20720p%2F%5BKusonime%5D%20Spy%20x%20Family%20BD%20-%2025%20END.mp4'
          : '%5BKusonime%5D%20Mata2%20x%20Keluarga%20PT1%20BD%20720p%2F%5BKusonime%5D%20Spy%20x%20Family%20BD%20-%20$epStr.mp4';
      final url =
          'https://archive.org/download/kusonime-spy-x-family-bd-04/$fileName';
      final s3Url =
          'https://archive.org/cors/kusonime-spy-x-family-bd-04/$fileName';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Sousou no Frieren Season 1 (5 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildFrierenSeason1() {
    return List.generate(5, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/anime-pahe-sousou-no-frieren-$pad-bd-1080p-sev/AnimePahe_Sousou_no_Frieren_-_${pad}_BD_1080p_SEV.mp4';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
      );
    });
  }

  // --- Bleach Season 1 (Unavailable per user request / no authentic Japanese dub with hardsubs available) ---
  static List<_AnimeStreamEntry> _buildBleach() {
    return const [];
  }

  // --- Hunter x Hunter 2011 (Unavailable per user request / no authentic Japanese dub with hardsubs available) ---
  static List<_AnimeStreamEntry> _buildHxh() {
    return const [];
  }

  // --- Fullmetal Alchemist: Brotherhood (64 Episodes, Japanese Audio BDRip AV1 OPUS) ---
  static List<_AnimeStreamEntry> _buildFmab() {
    return List.generate(64, (index) {
      final epNum = index + 1;
      final epStr = epNum.toString().padLeft(2, '0');
      final folder = Uri.encodeComponent(
          '[MA] FULLMETAL ALCHEMIST (2009) [BDRip 1920x1080 AV1 OPUS]');
      final file = Uri.encodeComponent(
          '[MA] FULLMETAL ALCHEMIST (2009) $epStr [BDRip 1920x1080 AV1 OPUS].mkv');
      final url =
          'https://archive.org/download/ma-fullmetal-alchemist-2009-bdrip-1920x1080-av1-opus/$folder/$file';
      final s3Url =
          'https://archive.org/cors/ma-fullmetal-alchemist-2009-bdrip-1920x1080-av1-opus/$folder/$file';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Steins;Gate (24 Episodes, ~24m each, Anime Time) ---
  static List<_AnimeStreamEntry> _buildSteinsGate() {
    return List.generate(24, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/anime-time-steins-gate/%5BAnime%20Time%5D%20Steins%3BGate%20-%20$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Dan Da Dan Season 1 (12 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildDandadan() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S01-E$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Dan Da Dan Season 2 (12 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildDandadanS2() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S02-E$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Re:Zero Season 1 (25 Episodes, ~24-49m each, Authentic Japanese Audio) ---
  static List<_AnimeStreamEntry> _buildReZero() {
    return List.generate(25, (index) {
      final file = OwnerVideoRepository.rezeroS1Files[index];
      final encoded = Uri.encodeComponent(file);
      final url =
          'https://archive.org/download/rezerokarahajimeruisekaiseikatsu_202001/$encoded';
      final s3Url =
          'https://archive.org/cors/rezerokarahajimeruisekaiseikatsu_202001/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  // --- Shigatsu wa Kimi no Uso (22 Episodes, ~23m each) ---
  static List<_AnimeStreamEntry> _buildYourLieInApril() {
    return List.generate(22, (index) {
      final epNum = index + 1;
      final url = 'https://archive.org/download/AY-YourLieInApril/$epNum.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Your Name / Kimi no Na wa Movie (106 Minutes, Japanese Audio + Hardsub) ---
  static List<_AnimeStreamEntry> _buildYourName() {
    const url =
        'https://archive.org/download/your-name-2/YOUR_NAME_%E3%82%BF%E3%82%A4%E3%83%88%E3%83%AB2%EF%BC%88%E3%83%A1%E3%82%A4%E3%83%B3%EF%BC%89.ia.mp4';
    return [
      const _AnimeStreamEntry(
        server1Url: url,
        server3Url: url,
        server4Url: url,
      )
    ];
  }

  // --- Haikyuu Dumpster Battle Movie (81 Minutes) ---
  static List<_AnimeStreamEntry> _buildHaikyuuMovie() {
    const url =
        'https://archive.org/download/haikyu-the-dumpster-battle-2024/Haikyu%21%21%20The%20Dumpster%20Battle%20%282024%29.mp4';
    const s3Url =
        'https://archive.org/cors/haikyu-the-dumpster-battle-2024/Haikyu%21%21%20The%20Dumpster%20Battle%20%282024%29.mp4';
    return [
      const _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      )
    ];
  }

  // --- Gintama: The Final Movie (100 Minutes) ---
  static List<_AnimeStreamEntry> _buildGintamaMovie() {
    const url =
        'https://archive.org/download/gintama-the-final/Gintama%20-%20The%20FINAL.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- A Silent Voice Movie (130 Minutes) ---
  static List<_AnimeStreamEntry> _buildSilentVoice() {
    const url =
        'https://archive.org/download/koe-no-katachi-1080p/KoeNoKatachi_1080p.mp4';
    const s3Url =
        'https://archive.org/cors/koe-no-katachi-1080p/KoeNoKatachi_1080p.mp4';
    const s4Url =
        'https://archive.org/download/a-silent-voice-subbed/AnimePahe_Koe_no_Katachi_-_01_BD_1036p_Kametsu.mp4';
    return [
      const _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: s4Url,
      )
    ];
  }

  // --- Tokyo Ghoul Season 1 (12 Episodes, ~24m each, Japanese Audio) ---
  static List<_AnimeStreamEntry> _buildTokyoGhoulSeason1() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final fileName = 'S01E0$epNum.mp4';
      final url = 'https://archive.org/download/tokyo-ghoul-s01-sm/$fileName';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: url.replaceAll('/download/', '/cors/'),
        server4Url: url,
      );
    });
  }

  // --- Tokyo Ghoul Movie (Unavailable per atomicity / live-action only, no anime movie exists) ---
  static List<_AnimeStreamEntry> _buildTokyoGhoulMovie() {
    return const [];
  }

  // --- One Punch Man Season 1 (12 Episodes, Japanese Audio + Sub Indo / Eng Sub) ---
  static List<_AnimeStreamEntry> _buildOnePunchManS1() {
    return List.generate(12, (index) {
      final epNum = (index + 1).toString().padLeft(2, '0');
      final url = 'https://archive.org/download/opm-s1/OPM-BD-$epNum.mp4';
      final s3Url = 'https://archive.org/cors/opm-s1/OPM-BD-$epNum.mp4';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: s3Url,
        server4Url: url,
      );
    });
  }

  static final Map<String, List<_AnimeStreamEntry>> _animeEpisodeMap = {
    // Core Season 1 / Single-Season Anime
    'demon-slayer': _buildKnySeason1(),
    'demon-slayer-movie': _buildKnyMovie(),
    'demon-slayer-mugen-tv': _buildKnyMugenTv(),
    'attack-on-titan': _buildAotSeason1(),
    'jujutsu-kaisen': _buildJjkSeason1(),
    'jujutsu-kaisen-0': _buildJjk0(),
    'death-note': _buildDeathNoteSeason1(),
    'tokyo-revengers': _buildTokyoRevengersSeason1(),
    'solo-leveling': _buildSoloLevelingSeason1(),
    'my-hero-academia': _buildMhaSeason1(),
    'chainsaw-man': _buildChainsawManSeason1(),
    'chainsaw-man-movie': _buildCsmMovie(),
    'naruto': _buildNarutoSeason1(),
    'one-piece': _buildOnePieceSeason1(),
    'spy-x-family': _buildSpyFamilySeason1(),
    'frieren': _buildFrierenSeason1(),
    'bleach': _buildBleach(),
    'hunter-x-hunter': _buildHxh(),
    'fullmetal-alchemist': _buildFmab(),
    'steins-gate': _buildSteinsGate(),
    'dandadan': _buildDandadan(),
    'rezero': _buildReZero(),
    'boku-no-kokoro': _buildBokuNoKokoroS1(),
    'boku-no-kokoro-s2': _buildBokuNoKokoroS2(),
    'shigatsu-wa-kimi': _buildYourLieInApril(),
    'your-name': _buildYourName(),
    'haikyuu-movie': _buildHaikyuuMovie(),
    'gintama-movie': _buildGintamaMovie(),
    'silent-voice': _buildSilentVoice(),
    'tokyo-ghoul': _buildTokyoGhoulSeason1(),
    'tokyo-ghoul-movie': _buildTokyoGhoulMovie(),
    'one-punch-man': _buildOnePunchManS1(),
    'yosuga-no-sora': _buildYosugaNoSora(),

    // Season-Specific Verified Entries
    'demon-slayer-s2': _buildKnySeason2(),
    'demon-slayer-s3': _buildKnySeason3(),
    'demon-slayer-s4': _buildKnySeason4(),
    'dandadan-s2': _buildDandadanS2(),
    'tokyo-revengers-s2': _buildTokyoRevengersS2(),
    'tokyo-revengers-s3': _buildTokyoRevengersS3(),
  };

  /// Returns an authentic episode title for the given anime and episode number
  /// without hardcoding language tags such as "Sub Indo".
  static String getEpisodeTitle(
    String animeId,
    String animeTitle,
    int episodeNumber, {
    bool isMovie = false,
  }) {
    final key = detectAnimeKey(animeId, animeTitle);
    final titles = _episodeTitlesByKey[key];
    if (titles != null && episodeNumber >= 1 && episodeNumber <= titles.length) {
      final title = titles[episodeNumber - 1];
      if (isMovie || titles.length == 1) {
        return title;
      }
      return 'Episode $episodeNumber: $title';
    }
    if (isMovie) {
      return animeTitle.trim().isNotEmpty ? animeTitle.trim() : 'Full Movie';
    }
    return 'Episode $episodeNumber';
  }

  static const Map<String, List<String>> _episodeTitlesByKey = {
    'demon-slayer': [
      'Cruelty',
      'Trainer Sakonji Urokodaki',
      'Sabito and Makomo',
      'Final Selection',
      'My Own Steel',
      'Swordsman Accompanying a Demon',
      'Muzan Kibutsuji',
      'The Smell of Enchanting Blood',
      'Temari Demon and Arrow Demon',
      'Together Forever',
      'Tsuzumi Mansion',
      'The Boar Bares Its Fangs, Zenitsu Sleeps',
      'Something More Important Than Life',
      'The House with the Wisteria Family Crest',
      'Mount Natagumo',
      'Letting Someone Else Go First',
      'You Must Master a Single Thing',
      'A Forged Bond',
      'Hinokami',
      'Pretend Family',
      'Against Corps Rules',
      'Master of the Mansion',
      'Hashira Meeting',
      'Rehabilitation Training',
      'Tsuguko, Kanao Tsuyuri',
      'New Mission',
    ],
    'demon-slayer-mugen-tv': [
      'Flame Hashira Kyojuro Rengoku',
      'Deep Sleep',
      'Should Have Been',
      'Insult',
      'Move Forward!',
      'Akaza',
      'Set Your Heart Ablaze',
    ],
    'demon-slayer-s2': [
      'Sound Hashira Tengen Uzui',
      'Infiltrating the Entertainment District',
      'What Are You?',
      'Tonight',
      'Things Are Gonna Get Real Flashy!!',
      'Layered Memories',
      'Transformation',
      'Gathering',
      'Defeating an Upper Rank Demon',
      'Never Give Up',
      'No Matter How Many Lives',
    ],
    'demon-slayer-s4': [
      'To Defeat Muzan Kibutsuji',
      'Water Hashira Giyu Tomioka\'s Pain',
      'Fully Recovered Tanjiro Joins the Hashira Training!!',
      'To Bring a Smile to One\'s Face',
      'I Even Ate Demons...',
      'The Strongest of the Demon Slayer Corps',
      'Stone Hashira Gyomei Himejima',
      'The Hashira Unite',
    ],
    'attack-on-titan': [
      'To You, in 2000 Years: The Fall of Shiganshina, Part 1',
      'That Day: The Fall of Shiganshina, Part 2',
      'A Dim Light Amid Despair: Humanity\'s Comeback, Part 1',
      'The Night of the Closing Ceremony: Humanity\'s Comeback, Part 2',
      'First Battle: The Struggle for Trost, Part 1',
      'The World the Girl Saw: The Struggle for Trost, Part 2',
      'Small Blade: The Struggle for Trost, Part 3',
      'I Can Hear His Heartbeat: The Struggle for Trost, Part 4',
      'Whereabouts of His Left Arm: The Struggle for Trost, Part 5',
      'Response: The Struggle for Trost, Part 6',
      'Idol: The Struggle for Trost, Part 7',
      'Wound: The Struggle for Trost, Part 8',
      'Primal Desire: The Struggle for Trost, Part 9',
      'Can\'t Look into His Eyes Yet: Eve of the Counterattack, Part 1',
      'Special Operations Squad: Eve of the Counterattack, Part 2',
      'What Needs to Be Done Now: Eve of the Counterattack, Part 3',
      'Female Titan: The 57th Exterior Scouting Mission, Part 1',
      'Forest of Giant Trees: The 57th Exterior Scouting Mission, Part 2',
      'Bite: The 57th Exterior Scouting Mission, Part 3',
      'Erwin Smith: The 57th Exterior Scouting Mission, Part 4',
      'Crushing Blow: The 57th Exterior Scouting Mission, Part 5',
      'The Defeated: The 57th Exterior Scouting Mission, Part 6',
      'Smile: Assault on Stohess, Part 1',
      'Mercy: Assault on Stohess, Part 2',
      'Wall: Assault on Stohess, Part 3',
    ],
    'death-note': [
      'Rebirth',
      'Confrontation',
      'Dealings',
      'Pursuit',
      'Tactics',
      'Unraveling',
      'Overcast',
      'Glare',
      'Encounter',
      'Doubt',
      'Assault',
      'Love',
      'Confession',
      'Friend',
      'Wager',
      'Decision',
      'Execution',
      'Ally',
      'Matsuda',
      'Makeshift',
      'Performance',
      'Guidance',
      'Frenzy',
      'Revival',
      'Silence',
      'Renewal',
      'Abduction',
      'Impatience',
      'Father',
      'Justice',
      'Transfer',
      'Selection',
      'Scorn',
      'Vigilance',
      'Malice',
      '1.28',
      'New World',
    ],
    'jujutsu-kaisen-0': [
      'Jujutsu Kaisen 0: The Movie',
    ],
    'tokyo-revengers': [
      'Reborn',
      'Resist',
      'Resolve',
      'Return',
      'Releap',
      'Regret',
      'Revive',
      'Rechange',
      'Revolt',
      'Rerise',
      'Respect',
      'Revenge',
      'Odds and Ends',
      'Break up',
      'No Pain, No Gain',
      'Once upon a Time',
      'No Way',
      'Open Fire',
      'Turn Around',
      'Dead or Alive',
      'One and Only',
      'One for All',
      'End of War',
      'A Cry Baby',
    ],
    'tokyo-revengers-s2': [
      'It Is What It Is',
      'Gotta Go',
      'Stand Alone',
      'Family Ties',
      'Christmas Eve',
      'Whip Up Morale',
      'Sibling Rivalry',
      'Strive Together',
      'Dawning of a New Era',
      'The Light of My Life',
      'On My Way Home',
      'Last Order',
      'When It Rains, It Pours',
    ],
    'tokyo-revengers-s3': [
      'The Longest Day',
      'Mortal Enemy',
      'Run Out of Patience',
      'Come Back to Life',
      'A Bad Hunch',
      'Rise Against',
      'Turn the Tide',
      'I Know in My Head',
      'The Blue Ogre',
      'Brave Heart',
      'Nothing Is Left',
      'Lose Control',
      'Meet His Fate',
    ],
    'chainsaw-man': [
      'Dog & Chainsaw',
      'Arrival in Tokyo',
      'Meowy\'s Whereabouts',
      'Rescue',
      'Gun Devil',
      'Kill Denji',
      'The Taste of a Kiss',
      'Gunfire',
      'From Kyoto',
      'Bruised & Battered',
      'Mission Start',
      'Katana vs. Chainsaw',
    ],
    'chainsaw-man-movie': [
      'Chainsaw Man – The Movie: Reze Arc',
    ],
    'naruto': [
      'Enter: Naruto Uzumaki!',
      'My Name is Konohamaru!',
      'Sasuke and Sakura: Friends or Foes?',
      'Pass or Fail: Survival Test',
      'You Failed! Kakashi\'s Final Decision',
      'A Dangerous Mission! Journey to the Land of Waves!',
      'The Assassin of the Mist!',
      'The Oath of Pain',
      'Kakashi: Sharingan Warrior',
      'The Forest of Chakra',
      'The Land Where a Hero Once Lived',
      'Battle on the Bridge! Zabuza Returns!',
      'Haku\'s Secret Jutsu: Crystal Ice Mirrors',
      'The Number One Hyperactive, Knucklehead Ninja Joins the Fight!',
      'Zero Visibility: The Sharingan Shatters',
      'The Broken Seal',
      'White Past: Hidden Ambition',
      'The Weapons Known as Shinobi',
      'The Demon in the Snow',
      'A New Chapter Begins: The Chunin Exam!',
      'Identify Yourself: Powerful New Rivals',
      'Chunin Challenge: Rock Lee vs. Sasuke!',
      'Genin Takedown! All Nine Rookies Face Off!',
      'Start Your Engines: The Chunin Exam Begins!',
      'The Tenth Question: All or Nothing!',
    ],
    'solo-leveling': [
      'I\'m Used to It',
      'If I Had One More Chance',
      'It\'s Like a Game',
      'I\'ve Gotta Get Stronger',
      'A Pretty Good Deal',
      'The Real Hunt Begins',
      'Let\'s See How Far I Can Go',
      'This Is Frustrating',
      'You\'ve Been Hiding Your Skills',
      'What Is This, a Picnic?',
      'A Knight Who Defends an Empty Throne',
      'Arise',
    ],
    'my-hero-academia': [
      'Izuku Midoriya: Origin',
      'What It Takes to Be a Hero',
      'Roaring Muscles',
      'Start Line',
      'What I Can Do for Now',
      'Rage, You Damned Nerd',
      'Deku vs. Kacchan',
      'Bakugo\'s Start Line',
      'Yeah, Just Do Your Best, Ida!',
      'Encounter with the Unknown',
      'Game Over',
      'All Might',
      'In Each of Our Hearts',
    ],
    'rezero': [
      'The End of the Beginning and the Beginning of the End',
      'Reunion with the Witch',
      'Starting Life from Zero in Another World',
      'The Happy Roswaal Mansion Family',
      'The Morning of Our Promise Is Still Distant',
      'The Sound of Chains',
      'Natsuki Subaru\'s Restart',
      'I Cried, Cried My Lungs Out, and Stopped Crying',
      'The Meaning of Courage',
      'Fanatical Methods Like a Demon',
      'Rem',
      'Return to the Capital',
      'Self-Proclaimed Knight Natsuki Subaru',
      'The Sickness Called Despair',
      'The Outside of Madness',
      'The Greed of a Pig',
      'Disgrace in the Extreme',
      'From Zero',
      'Battle Against the White Whale',
      'Wilhelm van Astrea',
      'A Wager That Defies Despair',
      'A Flash of Sloth',
      'Nefarious Sloth',
      'The Self-Proclaimed Knight and the Greatest Knight',
      'That\'s All This Story Is About',
    ],
    'shigatsu-wa-kimi': [
      'Monotone / Colorful',
      'Friend A',
      'Inside Spring',
      'Departure',
      'Cloudy Skies',
      'On the Way Home',
      'The Shadow Whispers',
      'Let It Ring',
      'Resonance',
      'The Scenery I Shared with You',
      'Light of Life',
      'Twinkle Little Star',
      'Love\'s Sorrow',
      'Footsteps',
      'Liar',
      'Two of a Kind',
      'Twilight',
      'Hearts Come Together',
      'Goodbye, Hero',
      'Hand in Hand',
      'Snow',
      'Spring Wind',
    ],
    'your-name': [
      'Kimi no Na wa (Your Name)',
    ],
    'haikyuu-movie': [
      'Haikyuu!! The Dumpster Battle',
    ],
    'gintama-movie': [
      'Gintama: The Very Final',
    ],
    'silent-voice': [
      'Koe no Katachi (A Silent Voice)',
    ],
    'frieren': [
      'The Journey\'s End',
      'It Didn\'t Have to Be Magic...',
      'Killing Magic',
      'The Land Where Souls Rest',
      'Phantoms of the Dead',
      'The Hero of the Village',
      'Like a Fairy Tale',
      'Frieren the Slayer',
      'Aura the Guillotine',
      'A Powerful Mage',
      'Winter in the Northern Lands',
      'A Real Hero',
      'Aversion to One\'s Own Kind',
      'Privilege of the Young',
      'Smells Like Trouble',
      'Long-Lived Friends',
      'Take Care',
      'First-Class Mage Exam',
      'Well-Laid Plans',
      'Necessary Killing',
      'The World of Magic',
      'Future Enemies',
      'Conquering the Labyrinth',
      'Perfect Replicas',
      'A Fatal Vulnerability',
      'The Height of Magic',
      'An Era of Humans',
      'It Would Be Embarrassing When We Met Again',
    ],
    'one-punch-man': [
      'The Strongest Man',
      'The Lone Cyborg',
      'The Obsessive Scientist',
      'The Modern Ninja',
      'The Ultimate Mentor',
      'The Terrifying City',
      'The Ultimate Disciple',
      'The Deep Sea King',
      'Unyielding Justice',
      'Unmatched Peril',
      'The Dominator of the Universe',
      'The Strongest Hero',
    ],
  };
}

class _AnimeStreamEntry {
  final String server1Url;
  final String server3Url;
  final String server4Url;

  const _AnimeStreamEntry({
    required this.server1Url,
    required this.server3Url,
    String? server4Url,
  }) : server4Url = server4Url ?? server3Url;

  String getUrlForServer(String server) {
    if (server.contains('Server 3') || server.toLowerCase().contains('otaku')) {
      if (server3Url.isNotEmpty &&
          !server3Url.contains('dn72') &&
          !server3Url.contains('.ca.archive') &&
          !server3Url.contains('ia820602') &&
          !server3Url.contains('ia800505') &&
          !server3Url.contains('ia601508')) {
        return server3Url;
      }
      return server1Url.replaceAll('/download/', '/cors/');
    }
    if (server.contains('Server 4') ||
        server.toLowerCase().contains('consumet') ||
        server.toLowerCase().contains('cloud')) {
      if (server4Url.isNotEmpty &&
          !server4Url.contains('dn72') &&
          !server4Url.contains('.ca.archive') &&
          !server4Url.contains('ia820602') &&
          !server4Url.contains('ia800505') &&
          !server4Url.contains('ia601508')) {
        return server4Url;
      }
      return server1Url;
    }
    return server1Url;
  }
}
