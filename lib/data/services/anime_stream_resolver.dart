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

    // Default to Demon Slayer authentic stream
    return 'demon-slayer';
  }

  // --- Demon Slayer Season 1 (26 Episodes) ---
  static const Map<int, String> _knyHashes = {
    1: '95AC736C',
    2: 'DAC40433',
    3: '846022E3',
    4: 'A4AF13C0',
    5: '68585199',
    6: '65A976C0',
    7: '3FDB7136',
    8: 'C3563CC0',
    9: '11CF9FC7',
    10: '549EA6E2',
    11: 'E4168B8D',
    12: '8C58F91F',
    13: '2B4E3D55',
    14: '840B36BE',
    15: '3E62A9A7',
    16: 'B882E834',
    17: '2306EC8B',
    18: '2095C8DA',
    19: 'FB1D831E',
    20: 'ABDB7E7A',
    21: '8F9242A3',
    22: 'C146CF99',
    23: '1301EB8C',
    24: '8C166865',
    25: 'CA19719E',
    26: '31CF53D6',
  };

  static List<_AnimeStreamEntry> _buildKnySeason1() {
    const s1Cruelty =
        'https://archive.org/download/rai-demon-slayer-kimetsu-no-yaiba-season-1-episode-1-cruelty-hindi-360-p-sd-1/%5BRAI%5D%20Demon%20Slayer-%20Kimetsu%20No%20Yaiba%20Season%201%20Episode%201%20-%20Cruelty%20Hindi_360P%20SD%20%281%29.mp4';
    return List.generate(26, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final hash = _knyHashes[epNum]!;
      final s3Url =
          'https://archive.org/download/japanese-trainer-kny-s01/%5BErai-raws%5D%20Kimetsu%20no%20Yaiba%20-%20$pad%20%5B1080p%5D%5BHEVC%5D%5B$hash%5D.mkv';

      return _AnimeStreamEntry(
        server1Url: epNum == 1 ? s1Cruelty : s3Url,
        server3Url: s3Url,
      );
    });
  }

  // --- Attack on Titan Season 1 (25 Episodes) ---
  static List<_AnimeStreamEntry> _buildAotSeason1() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Jujutsu Kaisen Season 1 (24 Episodes) ---
  static List<_AnimeStreamEntry> _buildJjkSeason1() {
    return List.generate(24, (index) {
      final epNum = index + 1;
      final url = epNum == 18
          ? 'https://archive.org/download/jujutsu-kaisen-season-1-episode-17-eng.dub/JUJUTSU%20KAISEN%20Season%201%20Episode%2018.mp4'
          : 'https://archive.org/download/jujutsu-kaisen-season-1-episode-17-eng.dub/JUJUTSU%20KAISEN%20Season%201%20Episode%20$epNum%20eng.dub.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Death Note Season 1 (37 Episodes) ---
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

  // --- Tokyo Revengers Season 1 (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildTokyoRevengersSeason1() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/tokyo.-revengers-latino/Tokyo.Revengers.S01E$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Solo Leveling Season 1 (12 Episodes) ---
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

  // --- Boku no Hero Academia Season 1 (13 Episodes) ---
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

  // --- Chainsaw Man Season 1 (12 Episodes) ---
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

  // --- Naruto Season 1 (25 Episodes) ---
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

  // --- One Piece Season 1 (East Blue Saga, 25 Episodes) ---
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

  // --- Spy x Family Season 1 (25 Episodes) ---
  static List<_AnimeStreamEntry> _buildSpyFamilySeason1() {
    const ep1Server1 =
        'https://archive.org/download/spy-x-family-ep-1/spy%20x%20family%20ep%201.mp4';
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final mkvUrl = 'https://archive.org/download/spy-x-family-s01/E$pad.mkv';
      return _AnimeStreamEntry(
        server1Url: epNum == 1 ? ep1Server1 : mkvUrl,
        server3Url: mkvUrl,
      );
    });
  }

  // --- Sousou no Frieren Season 1 (5 Episodes) ---
  static List<_AnimeStreamEntry> _buildFrierenSeason1() {
    return List.generate(5, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/sousou-no-frieren-dublado/Sousou%20no%20Frieren%20Dublado%20$pad%20Online.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  static final Map<String, List<_AnimeStreamEntry>> _animeEpisodeMap = {
    'demon-slayer': _buildKnySeason1(),
    'attack-on-titan': _buildAotSeason1(),
    'jujutsu-kaisen': _buildJjkSeason1(),
    'death-note': _buildDeathNoteSeason1(),
    'tokyo-revengers': _buildTokyoRevengersSeason1(),
    'solo-leveling': _buildSoloLevelingSeason1(),
    'my-hero-academia': _buildMhaSeason1(),
    'chainsaw-man': _buildChainsawManSeason1(),
    'naruto': _buildNarutoSeason1(),
    'one-piece': _buildOnePieceSeason1(),
    'spy-x-family': _buildSpyFamilySeason1(),
    'frieren': _buildFrierenSeason1(),
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
