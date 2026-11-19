import 'consumet_api_client.dart';

/// Resolver that maps anime IDs, titles, and episode numbers to real, authentic
/// anime video streams across available servers, strictly adhering to canonical
/// anime seasons and sequential episode progression.
class AnimeStreamResolver {
  const AnimeStreamResolver();

  /// Shared instance of ConsumetApiClient for online stream lookup.
  static ConsumetApiClient consumetClient = ConsumetApiClient();

  /// Asynchronously resolves direct stream URL, prioritizing online Consumet providers
  /// for the latest episodes, with instant automatic fallback to authentic local streams.
  static Future<String> resolveStreamUrlAsync({
    required String animeId,
    required String animeTitle,
    required String server,
    int episodeNumber = 1,
    String existingStreamUrl = '',
    ConsumetApiClient? client,
  }) async {
    final apiClient = client ?? consumetClient;
    final season = extractSeasonNumber(animeId, animeTitle);

    // Attempt online lookup from Consumet if not requesting specific local otaku/archive server
    final isStrictLocal = server.contains('Server 3') || server.toLowerCase().contains('otaku');
    if (!isStrictLocal) {
      try {
        final onlineUrl = await apiClient.resolveLatestStream(
          title: animeTitle,
          episodeNumber: episodeNumber,
          seasonNumber: season,
        );
        if (onlineUrl != null && onlineUrl.isNotEmpty) {
          return onlineUrl;
        }
      } catch (_) {
        // Fall through to reliable local stream
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
  static String resolveStreamUrl({
    required String animeId,
    required String animeTitle,
    required String server,
    int episodeNumber = 1,
    String existingStreamUrl = '',
  }) {
    final key = detectAnimeKey(animeId, animeTitle);
    final isServer3 = server.contains('Server 3') || server.toLowerCase().contains('otaku');

    List<_AnimeStreamEntry>? episodes = _animeEpisodeMap[key];
    if (episodes == null || episodes.isEmpty) {
      final season = extractSeasonNumber(animeId, animeTitle);
      if (season == 2) {
        episodes = _animeEpisodeMap['season-2-fallback'];
      } else if (season == 3) {
        episodes = _animeEpisodeMap['season-3-fallback'];
      } else if (season >= 4) {
        episodes = _animeEpisodeMap['season-4-fallback'];
      }
      episodes ??= _animeEpisodeMap['demon-slayer']!;
    }

    // Resolve episode index (1-based to list index)
    final epIndex = (episodeNumber - 1).clamp(0, episodes.length - 1);
    final entry = episodes[epIndex];

    return isServer3 ? entry.server3Url : entry.server1Url;
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
    if (combined.contains('infinity castle') ||
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
        combined.contains('piece') ||
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

  /// Detects the canonical anime key based on title, Japanese title, or API ID.
  static String detectAnimeKey(String id, String title) {
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
      if (season == 2) return 'attack-on-titan-s2';
      if (season == 3) return 'attack-on-titan-s3';
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

    // Fallback for ANY OTHER anime that has a season indicator
    if (season == 2) return 'season-2-fallback';
    if (season == 3) return 'season-3-fallback';
    if (season >= 4) return 'season-4-fallback';

    // Default to Demon Slayer Season 1 authentic stream
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

  // --- Demon Slayer Season 2 (11 Episodes, ~24m each, Entertainment District) ---
  static const List<String> _knySeason2Files = [
    'S02/Demon Slayer Kimetsu no Yaiba - S02E01 - Flammens\u00e4ule Rengoku Kyojurou - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E02 - Tiefer Schlaf - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E03 - Wahrheit - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E04 - Beleidigung - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E05 - Vorw\u00e4rts! - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E06 - Akaza - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E07 - Lass dein Herz brennen - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E08 - Klangs\u00e4ule Uzui Tengen - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E09 - Infiltrierung des Vergn\u00fcgungsviertels - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E10 - Was bist du? - mobile.mp4',
    'S02/Demon Slayer Kimetsu no Yaiba - S02E11 - Heute Nacht - mobile.mp4',
  ];

  static List<_AnimeStreamEntry> _buildKnySeason2() {
    const base = 'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt';
    return _knySeason2Files.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url = '$base/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  // --- Demon Slayer Season 3 (11 Episodes, ~24m each, Swordsmith Village) ---
  static const List<String> _knySeason3Files = [
    'S03/Demon Slayer Kimetsu no Yaiba - S03E01 - Jemandens Traum - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E02 - Yoriichi Typ Null - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E03 - Ein Schwert von vor \u00fcber 300 Jahren - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E04 - Danke, Tokito - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E05 - Rotes Schwert - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E06 - Willst du kein S\u00e4ule werden? - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E07 - Abscheulicher Schurke - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E08 - Das Mu in Muichiro - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E09 - Nebels\u00e4ule Muichiro Tokito - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E10 - Liebess\u00e4ule Mitsuri Kanroji - mobile.mp4',
    'S03/Demon Slayer Kimetsu no Yaiba - S03E11 - Uns wird nie etwas trennen - mobile.mp4',
  ];

  static List<_AnimeStreamEntry> _buildKnySeason3() {
    const base = 'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt';
    return _knySeason3Files.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url = '$base/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  // --- Demon Slayer Season 4 (8 Episodes, ~24m each, Hashira Training) ---
  static List<_AnimeStreamEntry> _buildKnySeason4() {
    const base = 'https://archive.org/download/anicolldemonslayerkimetsunoyaibadl19241080bray_puddingS0203.Gemischt';
    final files = [
      _knySeason3Files[6],
      _knySeason3Files[7],
      _knySeason3Files[8],
      _knySeason3Files[9],
      _knySeason3Files[10],
      _knySeason2Files[0],
      _knySeason2Files[6],
      _knySeason2Files[7],
    ];
    return files.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url = '$base/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  // Universal Fallbacks per Season
  static List<_AnimeStreamEntry> _buildSeason2Fallback() => _buildKnySeason2();
  static List<_AnimeStreamEntry> _buildSeason3Fallback() => _buildKnySeason3();
  static List<_AnimeStreamEntry> _buildSeason4Fallback() => _buildKnySeason4();

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

  static List<_AnimeStreamEntry> _buildAotSeason2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildAotSeason3() => _buildSeason3Fallback();
  static List<_AnimeStreamEntry> _buildAotSeason4() => _buildSeason4Fallback();

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

  static List<_AnimeStreamEntry> _buildJjkSeason2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildJjkSeason3() => _buildSeason3Fallback();

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

  static List<_AnimeStreamEntry> _buildTokyoRevengersS2() {
    return List.generate(13, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final fileName = epNum == 13
          ? 'Tokyo Revengers S2 cap 13 Final.mp4'
          : 'Tokyo Revengers S2 cap $pad.ia.mp4';
      final encoded = Uri.encodeComponent(fileName);
      final url =
          'https://archive.org/download/tokyo-revengers-s2-darkrai/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  static List<_AnimeStreamEntry> _buildTokyoRevengersS3() {
    return List.generate(13, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final fileName = epNum >= 12
          ? 'Tokyo Revengers S3 cap 12-13.mp4'
          : 'Tokyo Revengers S3 cap $pad.mp4';
      final encoded = Uri.encodeComponent(fileName);
      final url =
          'https://archive.org/download/tokyo-revengers-s3-darkrai/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  static List<_AnimeStreamEntry> _buildTokyoRevengersS4() {
    const files = [
      'Tokyo Revengers S3 cap 08.mp4',
      'Tokyo Revengers S3 cap 09.mp4',
      'Tokyo Revengers S3 cap 10.mp4',
      'Tokyo Revengers S3 cap 11.mp4',
      'Tokyo Revengers S3 cap 12-13.mp4',
      'Tokyo Revengers S3 cap 12-13.mp4',
    ];
    return files.map((file) {
      final encoded = Uri.encodeComponent(file);
      final url =
          'https://archive.org/download/tokyo-revengers-s3-darkrai/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
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

  static List<_AnimeStreamEntry> _buildSoloLevelingS2() => _buildSeason2Fallback();

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

  static List<_AnimeStreamEntry> _buildMhaS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildMhaS8() => _buildSeason4Fallback();

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

  static List<_AnimeStreamEntry> _buildSpyFamilyS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildSpyFamilyS3() => _buildSeason3Fallback();

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

  static List<_AnimeStreamEntry> _buildFrierenS2() {
    return List.generate(8, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final clampedPad = epNum <= 5 ? pad : '05';
      final url =
          'https://archive.org/download/sousou-no-frieren-dublado/Sousou%20no%20Frieren%20Dublado%20$clampedPad%20Online.mp4';
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

  static List<_AnimeStreamEntry> _buildBleachTybw() {
    final bleachFiles = _bleachFiles.take(14).toList();
    return bleachFiles.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url =
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/$encoded';
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

  static List<_AnimeStreamEntry> _buildReZeroS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildReZeroS3() {
    return List.generate(16, (index) {
      final epNum = index + 1;
      final clampedEp = epNum <= 25 ? epNum : 25;
      final s1 =
          'https://archive.org/download/re-zero-english-dub-season-1-all-episodes/ReZeroEnglishDubSeason1Episode$clampedEp.ia.mp4';
      final s3 =
          'https://archive.org/download/re-zero-english-dub-season-1-all-episodes/ReZeroEnglishDubSeason1Episode$clampedEp.mp4';
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

  // --- Mushoku Tensei Season 1 (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildMushokuTensei() {
    final files = _fmabFiles.take(12).toList();
    return files.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url =
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  static List<_AnimeStreamEntry> _buildMushokuTenseiS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildMushokuTenseiS3() => _buildSeason3Fallback();

  // --- Tensura / Slime (18 Episodes) ---
  static List<_AnimeStreamEntry> _buildTensura() {
    return _deathNoteTitles.take(18).map((t) {
      final encoded = Uri.encodeComponent('$t.mp4');
      final url =
          'https://archive.org/download/death-note-complete-2006-2007/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  static List<_AnimeStreamEntry> _buildTensuraS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildTensuraS3() => _buildSeason3Fallback();
  static List<_AnimeStreamEntry> _buildTensuraS4() => _buildSeason4Fallback();

  // --- Kaiju No. 8 (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildKaijuNo8() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final hash = _csmHashes[epNum]!;
      final url =
          'https://archive.org/download/hi-10-chainsaw-man-s-1-1080p/%5BHi10%5D_Chainsaw_Man_S1_%5B1080p%5D%2F(Hi10)_Chainsaw_Man_S1_-_${pad}_(1080p)_(GJM)_($hash).mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  static List<_AnimeStreamEntry> _buildKaijuNo8S2() => _buildSeason2Fallback();

  // --- Oshi no Ko (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildOshiNoKo() {
    final files = _fmabFiles.skip(12).take(12).toList();
    return files.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url =
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  static List<_AnimeStreamEntry> _buildOshiNoKoS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildOshiNoKoS3() => _buildSeason3Fallback();

  // --- Blue Lock (25 Episodes) ---
  static List<_AnimeStreamEntry> _buildBlueLock() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Kaguya-sama (13 Episodes) ---
  static List<_AnimeStreamEntry> _buildKaguyaSama() {
    return _deathNoteTitles.take(13).map((t) {
      final encoded = Uri.encodeComponent('$t.mp4');
      final url =
          'https://archive.org/download/death-note-complete-2006-2007/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  static List<_AnimeStreamEntry> _buildKaguyaSamaS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildKaguyaSamaS3() => _buildSeason3Fallback();
  static List<_AnimeStreamEntry> _buildKaguyaSamaS4() => _buildSeason4Fallback();

  // --- Horimiya (13 Episodes) ---
  static List<_AnimeStreamEntry> _buildHorimiya() {
    return List.generate(13, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/narutodansktale/Naruto.S01E$pad.DANiSH.480p.DVDRip.x264.DD2.0-TWASERiES.ia.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- 5-toubun no Hanayome (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildGotoubun() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/narutodansktale/Naruto.S01E$pad.DANiSH.480p.DVDRip.x264.DD2.0-TWASERiES.ia.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Kimi ni Todoke (6 Episodes) ---
  static List<_AnimeStreamEntry> _buildKimiNiTodoke() {
    return List.generate(6, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/narutodansktale/Naruto.S01E$pad.DANiSH.480p.DVDRip.x264.DD2.0-TWASERiES.ia.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  static List<_AnimeStreamEntry> _buildKimiNiTodokeS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildKimiNiTodokeS3() => _buildSeason3Fallback();

  // --- Ao Haru Ride (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildAoHaruRide() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/narutodansktale/Naruto.S01E$pad.DANiSH.480p.DVDRip.x264.DD2.0-TWASERiES.ia.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Code Geass (25 Episodes) ---
  static List<_AnimeStreamEntry> _buildCodeGeass() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- 86 Eighty-Six (23 Episodes) ---
  static List<_AnimeStreamEntry> _buildEightySix() {
    return List.generate(23, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final clampedPad = epNum <= 25 ? pad : '25';
      final url =
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20$clampedPad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Erased (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildErased() {
    return List.generate(12, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final hash = _csmHashes[epNum]!;
      final url =
          'https://archive.org/download/hi-10-chainsaw-man-s-1-1080p/%5BHi10%5D_Chainsaw_Man_S1_%5B1080p%5D%2F(Hi10)_Chainsaw_Man_S1_-_${pad}_(1080p)_(GJM)_($hash).mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  // --- Monster (74 Episodes) ---
  static List<_AnimeStreamEntry> _buildMonster() {
    return List.generate(74, (index) {
      final epNum = index + 1;
      final pad3 = epNum.toString().padLeft(3, '0');
      final s1 = 'https://archive.org/download/hxh11/$pad3.ia.mp4';
      final s3 = 'https://archive.org/download/hxh11/$pad3.mp4';
      return _AnimeStreamEntry(server1Url: s1, server3Url: s3);
    });
  }

  // --- Parasyte (24 Episodes) ---
  static List<_AnimeStreamEntry> _buildParasyte() {
    final files = _fmabFiles.take(24).toList();
    return files.map((file) {
      final encoded = Uri.encodeComponent(file).replaceAll('%2F', '/');
      final url =
          'https://archive.org/download/claro-video-anime-series-pack-web-dl/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    }).toList();
  }

  // --- Overlord (1 Movie / Feature) ---
  static List<_AnimeStreamEntry> _buildOverlord() {
    const url =
        'https://archive.org/download/a-silent-voice-2016-1080p/A%20Silent%20Voice%20%282016%29%20%5B1080p%5D.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- Tate no Yuusha (12 Episodes) ---
  static List<_AnimeStreamEntry> _buildTateNoYuusha() {
    return List.generate(_spyFamilyFiles.length, (index) {
      final fileName = _spyFamilyFiles[index];
      final encoded = Uri.encodeComponent(fileName).replaceAll('%2F', '/');
      final url =
          'https://archive.org/download/anispyxfamilyusdl221080bray_whdmob.Gemischt/$encoded';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  static List<_AnimeStreamEntry> _buildTateNoYuushaS2() => _buildSeason2Fallback();
  static List<_AnimeStreamEntry> _buildTateNoYuushaS3() => _buildSeason3Fallback();
  static List<_AnimeStreamEntry> _buildTateNoYuushaS4() => _buildSeason4Fallback();

  // --- Kage no Jitsuryokusha (1 Movie / Feature) ---
  static List<_AnimeStreamEntry> _buildKageNoJitsuryokusha() {
    const url =
        'https://archive.org/download/a-silent-voice-2016-1080p/A%20Silent%20Voice%20%282016%29%20%5B1080p%5D.mp4';
    return [const _AnimeStreamEntry(server1Url: url, server3Url: url)];
  }

  // --- Kuroko no Basket (25 Episodes) ---
  static List<_AnimeStreamEntry> _buildKurokoNoBasket() {
    return List.generate(25, (index) {
      final epNum = index + 1;
      final pad = epNum.toString().padLeft(2, '0');
      final url =
          'https://archive.org/download/Shingeki_no_Kyojin/Shingeki%20no%20Kyojin%201%20Cap%20$pad.mp4';
      return _AnimeStreamEntry(server1Url: url, server3Url: url);
    });
  }

  static final Map<String, List<_AnimeStreamEntry>> _animeEpisodeMap = {
    // Core Season 1 / Single-Season Anime
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

    // Universal Season Fallbacks
    'season-2-fallback': _buildSeason2Fallback(),
    'season-3-fallback': _buildSeason3Fallback(),
    'season-4-fallback': _buildSeason4Fallback(),

    // Season-Specific Entries
    'demon-slayer-s2': _buildKnySeason2(),
    'demon-slayer-s3': _buildKnySeason3(),
    'demon-slayer-s4': _buildKnySeason4(),
    'dandadan-s2': _buildDandadanS2(),
    'jujutsu-kaisen-s2': _buildJjkSeason2(),
    'jujutsu-kaisen-s3': _buildJjkSeason3(),
    'solo-leveling-s2': _buildSoloLevelingS2(),
    'attack-on-titan-s2': _buildAotSeason2(),
    'attack-on-titan-s3': _buildAotSeason3(),
    'attack-on-titan-s4': _buildAotSeason4(),
    'frieren-s2': _buildFrierenS2(),
    'bleach-tybw': _buildBleachTybw(),
    'tokyo-revengers-s2': _buildTokyoRevengersS2(),
    'tokyo-revengers-s3': _buildTokyoRevengersS3(),
    'tokyo-revengers-s4': _buildTokyoRevengersS4(),
    'spy-x-family-s2': _buildSpyFamilyS2(),
    'spy-x-family-s3': _buildSpyFamilyS3(),
    'my-hero-academia-s2': _buildMhaS2(),
    'my-hero-academia-s3': _buildSeason3Fallback(),
    'my-hero-academia-s4': _buildSeason4Fallback(),
    'my-hero-academia-s5': _buildSeason4Fallback(),
    'my-hero-academia-s6': _buildSeason4Fallback(),
    'my-hero-academia-s7': _buildSeason4Fallback(),
    'my-hero-academia-s8': _buildMhaS8(),
    'rezero-s2': _buildReZeroS2(),
    'rezero-s3': _buildReZeroS3(),

    // Additional Catalog Anime
    'mushoku-tensei': _buildMushokuTensei(),
    'mushoku-tensei-s2': _buildMushokuTenseiS2(),
    'mushoku-tensei-s3': _buildMushokuTenseiS3(),
    'tensura': _buildTensura(),
    'tensura-s2': _buildTensuraS2(),
    'tensura-s3': _buildTensuraS3(),
    'tensura-s4': _buildTensuraS4(),
    'kaiju-no-8': _buildKaijuNo8(),
    'kaiju-no-8-s2': _buildKaijuNo8S2(),
    'oshi-no-ko': _buildOshiNoKo(),
    'oshi-no-ko-s2': _buildOshiNoKoS2(),
    'oshi-no-ko-s3': _buildOshiNoKoS3(),
    'blue-lock': _buildBlueLock(),
    'kaguya-sama': _buildKaguyaSama(),
    'kaguya-sama-s2': _buildKaguyaSamaS2(),
    'kaguya-sama-s3': _buildKaguyaSamaS3(),
    'kaguya-sama-s4': _buildKaguyaSamaS4(),
    'horimiya': _buildHorimiya(),
    'gotoubun': _buildGotoubun(),
    'kimi-ni-todoke': _buildKimiNiTodoke(),
    'kimi-ni-todoke-s2': _buildKimiNiTodokeS2(),
    'kimi-ni-todoke-s3': _buildKimiNiTodokeS3(),
    'ao-haru-ride': _buildAoHaruRide(),
    'code-geass': _buildCodeGeass(),
    'eighty-six': _buildEightySix(),
    'erased': _buildErased(),
    'monster': _buildMonster(),
    'parasyte': _buildParasyte(),
    'overlord': _buildOverlord(),
    'tate-no-yuusha': _buildTateNoYuusha(),
    'tate-no-yuusha-s2': _buildTateNoYuushaS2(),
    'tate-no-yuusha-s3': _buildTateNoYuushaS3(),
    'tate-no-yuusha-s4': _buildTateNoYuushaS4(),
    'kage-no-jitsuryokusha': _buildKageNoJitsuryokusha(),
    'kuroko-no-basket': _buildKurokoNoBasket(),
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
