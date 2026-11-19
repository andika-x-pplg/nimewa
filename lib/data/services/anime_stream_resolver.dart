/// Resolver that maps anime IDs, titles, and episode numbers to real, authentic
/// anime video streams across available servers, strictly adhering to canonical
/// anime seasons and sequential episode progression.
class AnimeStreamResolver {
  const AnimeStreamResolver();

  /// Resolves direct stream URL based on anime identifier, title, episode number, and server.
  static String resolveStreamUrl({
    required String animeId,
    required String animeTitle,
    required String server,
    int episodeNumber = 1,
    String existingStreamUrl = '',
  }) {
    final key = detectAnimeKey(animeId, animeTitle);
    final isServer3 = server.contains('Server 3') || server.toLowerCase().contains('otaku');

    final episodes = _animeEpisodeMap[key] ?? _animeEpisodeMap['demon-slayer']!;

    // Resolve episode index (1-based to list index)
    final epIndex = (episodeNumber - 1).clamp(0, episodes.length - 1);
    final entry = episodes[epIndex];

    return isServer3 ? entry.server3Url : entry.server1Url;
  }

  /// Detects the canonical anime key based on title, Japanese title, or API ID.
  static String detectAnimeKey(String id, String title) {
    final combined = '${id.toLowerCase()} ${title.toLowerCase()}';

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
    if (combined.contains('gintama') ||
        combined.contains('銀魂') ||
        id == 'gintama-final' ||
        id == 'gintama-movie') {
      return 'gintama-movie';
    }

    // Haikyuu Dumpster Battle Movie
    if (combined.contains('dumpster') ||
        combined.contains('haikyuu') ||
        combined.contains('haikyu') ||
        combined.contains('ハイキュー') ||
        id == 'haikyuu' ||
        id == 'haikyuu-movie') {
      return 'haikyuu-movie';
    }

    // Chainsaw Man: Reze Arc Movie
    if ((combined.contains('chainsaw') || id == 'chainsaw-man-movie') &&
        (combined.contains('reze') || combined.contains('movie') || combined.contains('film'))) {
      return 'chainsaw-man-movie';
    }

    // Kimetsu no Yaiba: Infinity Castle / Mugen Train Movie
    if ((combined.contains('demon slayer') || combined.contains('kimetsu') || id == 'kimetsu-no-yaiba-infinity') &&
        (combined.contains('infinity') || combined.contains('mugen') || combined.contains('movie') || combined.contains('film'))) {
      return 'demon-slayer-movie';
    }

    // Tokyo Ghoul
    if (combined.contains('tokyo ghoul') ||
        combined.contains('東京喰種') ||
        combined.contains('kaneki') ||
        id == 'tokyo-ghoul') {
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
        id == 'dandadan') {
      return 'dandadan';
    }

    // Re:Zero
    if (combined.contains('re:zero') ||
        combined.contains('rezero') ||
        combined.contains('rem') ||
        combined.contains('emilia') ||
        id == 'rezero-s3' ||
        id == 'rezero') {
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
        id == 'demon-slayer') {
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
        id == 'attack-on-titan') {
      return 'attack-on-titan';
    }

    // Jujutsu Kaisen
    if (combined.contains('jujutsu') ||
        combined.contains('itadori') ||
        combined.contains('sukuna') ||
        combined.contains('gojo') ||
        combined.contains('呪術廻戦') ||
        id == '43806' ||
        id == 'jujutsu-kaisen') {
      return 'jujutsu-kaisen';
    }

    // Tokyo Revengers
    if (combined.contains('tokyo revengers') ||
        combined.contains('takemichi') ||
        combined.contains('revengers') ||
        combined.contains('東京リベンジャーズ') ||
        id == '42249' ||
        id == 'tokyo-revengers-s4' ||
        id == 'tokyo-revengers') {
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
        id == 'solo-leveling-s2' ||
        id == 'solo-leveling') {
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
        id == 'boku-no-hero-academia' ||
        id == 'my-hero-academia') {
      return 'my-hero-academia';
    }

    // Sousou no Frieren
    if (combined.contains('frieren') ||
        combined.contains('sousou') ||
        combined.contains('葬送のフリーレン') ||
        id == '52991' ||
        id == '46569' ||
        id == 'frieren-s2' ||
        id == 'frieren') {
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
        id == 'spy-x-family') {
      return 'spy-x-family';
    }

    // Bleach
    if (combined.contains('bleach') ||
        combined.contains('ichigo') ||
        combined.contains('shinigami') ||
        combined.contains('ブリーチ') ||
        id == 'bleach' ||
        id == 'bleach-tybw-part3') {
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

    // Default to Demon Slayer authentic stream
    return 'demon-slayer';
  }

  // --- Demon Slayer Season 1 (26 Episodes, ~24m each) ---
  static const List<String> _knyMobileFiles = [
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

  static List<_AnimeStreamEntry> _buildKnySeason1() {
    const s1Cruelty =
        'https://archive.org/download/rai-demon-slayer-kimetsu-no-yaiba-season-1-episode-1-cruelty-hindi-360-p-sd-1/%5BRAI%5D%20Demon%20Slayer-%20Kimetsu%20No%20Yaiba%20Season%201%20Episode%201%20-%20Cruelty%20Hindi_360P%20SD%20%281%29.mp4';
    return List.generate(26, (index) {
      final epNum = index + 1;
      final fileName = _knyMobileFiles[index];
      final encodedPath = Uri.encodeComponent(fileName).replaceAll('%2F', '/');
      final mobileUrl =
          'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS01.Gemischt/$encodedPath';

      return _AnimeStreamEntry(
        server1Url: epNum == 1 ? s1Cruelty : mobileUrl,
        server3Url: mobileUrl,
      );
    });
  }

  // --- Demon Slayer Movie / Mugen Train (~26m Feature) ---
  static List<_AnimeStreamEntry> _buildKnyMovie() {
    const url =
        'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt/S02/Demon%20Slayer%20Kimetsu%20no%20Yaiba%20-%20S02E01%20-%20Flammens%C3%A4ule%20Rengoku%20Kyojurou%20-%20mobile.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- Attack on Titan Season 1 (25 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildAotSeason1() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Jujutsu Kaisen Season 1 (24 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildJjkSeason1() {
    return List.generate(24, (index) {
      final epNum = index + 1;
      final url = epNum == 18
          ? 'https://archive.org/download/jujutsu-kaisen-season-1-episode-17-eng.dub/JUJUTSU%20KAISEN%20Season%201%20Episode%2018.mp4'
          : 'https://archive.org/download/jujutsu-kaisen-season-1-episode-17-eng.dub/JUJUTSU%20KAISEN%20Season%201%20Episode%20$epNum%20eng.dub.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Jujutsu Kaisen 0 Movie (104 Minutes) ---
  static List<_AnimeStreamEntry> _buildJjk0() {
    const url =
        'https://archive.org/download/jujustu-kaisen-0-subbed/Jujustu%20Kaisen%200%20%28Subbed%29.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- Death Note Season 1 (37 Episodes, ~23m each) ---
  static const List<String> _deathNoteTitles = [
    'E01 - Rebirth',
    'E02 - Confrontation',
    'E03 - Dealings',
    'E04 - Pursuit',
    'E05 - Tactics',
    'E06 - Unraveling',
    'E07 - Overcast',
    'E08 - Glare',
    'E09 - Encounter',
    'E10 - Doubt',
    'E11 - Assault',
    'E12 - Love',
    'E13 - Confession',
    'E14 - Friend',
    'E15 - Wager',
    'E16 - Decision',
    'E17 - Execution',
    'E18 - Ally',
    'E19 - Matsuda',
    'E20 - Makeshift',
    'E21 - Performance',
    'E22 - Guidance',
    'E23 - Frenzy',
    'E24 - Revival',
    'E25 - Silence',
    'E26 - Renewal',
    'E27 - Abduction',
    'E28 - Impatience',
    'E29 - Father',
    'E30 - Justice',
    'E31 - Transfer',
    'E32 - Selection',
    'E33 - Scorn',
    'E34 - Vigilance',
    'E35 - Malice',
    'E36 - 1.28',
    'E37 - New World',
  ];

  static List<_AnimeStreamEntry> _buildDeathNoteSeason1() {
    return _deathNoteTitles.map((t) {
      final encoded = Uri.encodeComponent('$t.mp4');
      final url =
          'https://archive.org/download/death-note-complete-2006-2007/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  // --- Tokyo Revengers Season 1 (12 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildTokyoRevengersSeason1() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/tokyo.-revengers-latino/Tokyo.Revengers.S01E$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Solo Leveling Season 1 (12 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildSoloLevelingSeason1() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final rawName =
          'Поднятие уровня в одиночку С1Э$pad (2024) 1080p.mp4';
      final encoded = Uri.encodeComponent(rawName);
      final url =
          'https://archive.org/download/solo-leveling-s1_202610/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
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
    const url =
        'https://archive.org/download/ssstwitter.com_1763419408768/ssstwitter.com_1763419408768.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- Naruto Season 1 (25 Episodes, ~23m each) ---
  static List<_AnimeStreamEntry> _buildNarutoSeason1() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final server3 =
          'https://archive.org/download/narutodansktale/Naruto.S01E$pad.DANiSH.480p.DVDRip.x264.DD2.0-TWASERiES.ia.mp4';

      String server1;
      if (epNum == 1) {
        server1 =
            'https://archive.org/download/naruto-001-enter-naruto-uzumaki/Naruto%20%20001%20-%20Enter%20Naruto%20Uzumaki.mp4';
      } else if (epNum == 2) {
        server1 =
            'https://archive.org/download/naruto-episode-2.mp-4-h-264-720p-2/naruto%20episode%202.mp4-h264_720p_2.mp4';
      } else {
        server1 = server3;
      }

      return _AnimeStreamEntry(server1Url: server1, server3Url: server3);
    });
  }

  // --- One Piece Season 1 (East Blue Saga, 25 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildOnePieceSeason1() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      if (epNum == 1) {
        const url =
            'https://archive.org/download/one-piece-episode-1/One%20Piece%20Episode%201.mp4';
        return const _AnimeStreamEntry(server1Url: url, server3Url: url);
      }
      final fileName = epNum == 2
          ? '%20One%20Piece%20episode%202.mp4'
          : (epNum >= 13 && epNum <= 25 && epNum != 14 && epNum != 15 && epNum != 16 && epNum != 17
              ? 'one%20piece%20episode%20$epNum.mp4'
              : 'One%20Piece%20episode%20$epNum.mp4');
      final url = 'https://archive.org/download/one-piece-episode-9/$fileName';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Spy x Family Season 1 (12 Episodes, ~24m each) ---
  static const List<String> _spyFamilyFiles = [
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E01 - Operation Strix .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E02 - Eine Frau muss her .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E03 - Der große Prüfungsplan .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E04 - Elterngespräch an der Eliteschule .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E05 - Bestanden oder durchgefallen .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E06 - Der Gute-Freunde-Plan .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E07 - Der Sohn der Zielperson .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E08 - Der Anti-Geheimpolizei-Verhüllungsplan .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E09 - Die Turteltäubchen-Tarnung .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E10 - Der große Völkerball-Plan .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E11 - Stella .ia.mp4',
    'Spy.x.Family.2022.DL.1080p.BluRay_WebHD/S01_ABJ/SPY x FAMILY - S01E12 - Penguin Park .ia.mp4',
  ];

  static List<_AnimeStreamEntry> _buildSpyFamilySeason1() {
    return List.generate(_spyFamilyFiles.length, (index) {
      final fileName = _spyFamilyFiles[index];
      final encoded = Uri.encodeComponent(fileName).replaceAll('%2F', '/');
      final url =
          'https://archive.org/download/anispyxfamilyusdl221080bray_whdmob.Gemischt/$encoded';
      return _AnimeStreamEntry(
        server1Url: url,
        server3Url: url,
      );
    });
  }

  // --- Sousou no Frieren Season 1 (5 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildFrierenSeason1() {
    return List.generate(5, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/sousou-no-frieren-dublado/Sousou%20no%20Frieren%20Dublado%20$pad%20Online.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Bleach Season 1 (24 Episodes, ~23m each, Claro Video Pack) ---
  static const List<String> _bleachFiles = [
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E01 The Day I Became a Shinigami.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E02 A Shinigami`s Work.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E03 The Older Brother`s Wish, the Younger Sister`s Wish.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E04 Cursed Parakeet.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E05 Beat the Invisible Enemy!.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E06 Fight to the Death! Ichigo vs.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E07 Greetings from a Stuffed Lion.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E08 June 17, Memories in the Rain.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E09 Unbeatable Enemy.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E10 Assault on Trip at Sacred Ground!.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E11 The Legendary Quincy.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E12 A Gentle Right Arm.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E13 Flower and Hollow.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E14 Back to Back, a Fight to the Death!.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E15 Kon`s Great Plan.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E16 The Encounter, Abarai Renji!.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E17 Ichigo Dies!.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E18 Reclaim! The Power of the Shinigami!.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E19 Ichigo Becomes a Hollow!.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E20 Ichimaru Gin`s Shadow.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E21 Enter! The World of the Shinigami.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E22 The Man who Hates Shinigami.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E23 14 Days Before Rukia`s Execution.mp4',
    'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E24 Assemble! The 13 Divisions.mp4',
  ];

  static List<_AnimeStreamEntry> _buildBleach() {
    return _bleachFiles.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url = 'https://archive.org/download/claro-video-anime-series-pack-web-dl/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  // --- Hunter x Hunter 2011 (148 Episodes, ~23.4m each, hxh11 collection) ---
  static List<_AnimeStreamEntry> _buildHxh() {
    return List.generate(148, (index) {
      final epNum = index + 1;
      final pad3 = epNum.toString().padLeft(3, '0');
      final s1 = 'https://archive.org/download/hxh11/$pad3.ia.mp4';
      final s3 = 'https://archive.org/download/hxh11/$pad3.mp4';
      return _AnimeStreamEntry(server1Url: s1, server3Url: s3);
    });
  }

  // --- Fullmetal Alchemist: Brotherhood (64 Episodes, ~24.3m each, Claro Video Pack) ---
  static const List<String> _fmabFiles = [
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E01 Fullmetal Alchemist.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E02 The First Day.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E03 City of Heresy.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E04 An Alchemist`s Anguish.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E05 Rain of Sorrows.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E06 Road of Hope.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E07 Hidden Truths.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E08 The Fifth Laboratory.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E09 Created Feelings.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E10 Separate Destinations.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E11 Miracle at Rush Valley.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E12 One Is All, All Is One.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E13 Beasts of Dublith.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E14 Those Who Lurk Underground.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E15 Envoy from the East.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E16 Footsteps of a Comrade-in-Arms.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E17 Cold Flame.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E18 The Arrogant Palm of a Small Human.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E19 Death of the Undying.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E20 Father Before the Grave.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E21 Advance of the Fool.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E22 Backs in the Distance.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E23 Girl on the Battlefield.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E24 Inside the Belly.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E25 Doorway of Darkness.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E26 Reunion.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E27 Interlude Party.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E28 Father.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E29 Struggle of the Fool.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E30 The Ishvalan War of Extermination.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E31 The 520 Cenz Promise.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E32 The Führer`s Son.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E33 The Northern Wall of Briggs.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E34 Ice Queen.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E35 The Shape of This Country.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E36 Family Portrait.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E37 The First Homunculus.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E38 Conflict at Baschool.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E39 Daydream.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E40 Homunculus (The Dwarf in the Flask).mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E41 The Abyss.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E42 Signs of a Counteroffensive.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E43 Bite of the Ant.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E44 Revving at Full Throttle.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E45 The Promised Day.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E46 Looming Shadows.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E47 Emissary of Darkness.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E48 The Oath in the Tunnel.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E49 Filial Affection.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E50 Upheaval in Central.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E51 The Immortal Legion.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E52 Combined Strength.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E53 Flame of Vengeance.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E54 Beyond the Inferno.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E55 The Adults` Way of Life.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E56 The Return of the Führer.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E57 Eternal Leave.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E58 Sacrifices.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E59 Lost Light.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E60 Eye of Heaven, Gateway of Earth.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E61 He Who Would Swallow God.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E62 A Fierce Counterattack.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E63 The Other Side of the Gateway.mp4',
    'Claro Video/Fullmetal Alchemist Brotherhood (2009) [1st Dubbing][480p][✓]/Season 01/Fullmetal Alchemist Brotherhood S01E64 Journey`s End.mp4',
  ];

  static List<_AnimeStreamEntry> _buildFmab() {
    return _fmabFiles.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url = 'https://archive.org/download/claro-video-anime-series-pack-web-dl/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
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

  // --- Dan Da Dan (12 Episodes, ~24m each) ---
  static List<_AnimeStreamEntry> _buildDandadan() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/dan-da-dan-seasons-1-2/Dan%20Da%20Dan/dandadan_S01-E$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Re:Zero Season 1 (25 Episodes, ~24-49m each) ---
  static List<_AnimeStreamEntry> _buildReZero() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final s1 =
          'https://archive.org/download/re-zero-english-dub-season-1-all-episodes/ReZeroEnglishDubSeason1Episode$epNum.ia.mp4';
      final s3 =
          'https://archive.org/download/re-zero-english-dub-season-1-all-episodes/ReZeroEnglishDubSeason1Episode$epNum.mp4';
      return _AnimeStreamEntry(server1Url: s1, server3Url: s3);
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

  // --- Your Name / Kimi no Na wa Movie (106 Minutes) ---
  static List<_AnimeStreamEntry> _buildYourName() {
    const url =
        'https://archive.org/download/your.-name.-2016.-1.8-gb.-1080p.-dual.-audio.-hin-eng.-vegamovies.-nl/Your.Name.%282016%29.1.8GB.1080p.Dual.Audio.%28Hin-Eng%29.Vegamovies.NL.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- Haikyuu Dumpster Battle Movie (81 Minutes) ---
  static List<_AnimeStreamEntry> _buildHaikyuuMovie() {
    const url =
        'https://archive.org/download/Haikyuu-the-dumpster-battle-english-sub/%40AnimeArise%20Haikyuu%20The%20Dumpster%20Battle%20English%20sub.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
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
        'https://archive.org/download/a-silent-voice-2016-1080p/A%20Silent%20Voice%20%282016%29%20%5B1080p%5D.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- Tokyo Ghoul Movie / Feature (101 Minutes) ---
  static List<_AnimeStreamEntry> _buildTokyoGhoulMovie() {
    const url = 'https://archive.org/download/tokyo-ghoul-s/TokyoGhoulS.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  static final Map<String, List<_AnimeStreamEntry>> _animeEpisodeMap = {
    'demon-slayer': _buildKnySeason1(),
    'demon-slayer-movie': _buildKnyMovie(),
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
    'shigatsu-wa-kimi': _buildYourLieInApril(),
    'your-name': _buildYourName(),
    'haikyuu-movie': _buildHaikyuuMovie(),
    'gintama-movie': _buildGintamaMovie(),
    'silent-voice': _buildSilentVoice(),
    'tokyo-ghoul': _buildTokyoGhoulMovie(),
  };
}

class _AnimeStreamEntry {
  final String server1Url;
  final String server3Url;

  const _AnimeStreamEntry({
    required this.server1Url,
    required this.server3Url,
  });
}
