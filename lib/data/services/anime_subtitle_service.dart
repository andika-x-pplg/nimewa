class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });
}

class AnimeSubtitleService {
  const AnimeSubtitleService();

  static String getSubtitleForPosition({
    required String animeKey,
    required int episodeNumber,
    required Duration position,
  }) {
    final list = _subtitles['$animeKey-ep$episodeNumber'] ??
        _getDefaultCuesForEpisode(animeKey, episodeNumber);

    for (final cue in list) {
      if (position >= cue.start && position <= cue.end) {
        return cue.text;
      }
    }
    return '';
  }

  static int _extractSeasonNumber(String animeKey) {
    final match = RegExp(r'-s(\d+)').firstMatch(animeKey);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    if (animeKey.contains('season-2') || animeKey.contains('-s2')) return 2;
    if (animeKey.contains('season-3') || animeKey.contains('-s3')) return 3;
    if (animeKey.contains('season-4') || animeKey.contains('-s4')) return 4;
    if (animeKey.contains('tybw')) return 2;
    return 1;
  }

  static List<SubtitleCue> _getDefaultCuesForEpisode(String animeKey, int episodeNumber) {
    final title = _getAnimeDisplayName(animeKey);
    final isMovie = animeKey.contains('movie') ||
        animeKey == 'jujutsu-kaisen-0' ||
        animeKey == 'your-name' ||
        animeKey == 'silent-voice' ||
        animeKey == 'tokyo-ghoul' ||
        animeKey == 'overlord' ||
        animeKey == 'kage-no-jitsuryokusha';
    final seasonNum = _extractSeasonNumber(animeKey);
    final headerText = isMovie
        ? '[Sub Indo] $title - Full Movie'
        : '[Sub Indo] $title Season $seasonNum - Episode $episodeNumber';
    return [
      SubtitleCue(
        start: const Duration(seconds: 0),
        end: const Duration(seconds: 6),
        text: headerText,
      ),
      SubtitleCue(
        start: const Duration(seconds: 6),
        end: const Duration(seconds: 14),
        text: 'Audio asli Jepang dengan takarir Bahasa Indonesia resmi.',
      ),
      SubtitleCue(
        start: const Duration(seconds: 14),
        end: const Duration(seconds: 24),
        text: 'Streaming lancar kualitas HD di Nimeva.',
      ),
    ];
  }

  static String _getAnimeDisplayName(String rawKey) {
    if (rawKey.contains('fallback')) {
      return 'Anime Series';
    }
    // Strip season suffix like -s2, -s3, -s4 for display title lookup
    final key = rawKey.replaceAll(RegExp(r'-s\d+$'), '');

    switch (key) {
      case 'demon-slayer':
        return 'Demon Slayer: Kimetsu no Yaiba';
      case 'attack-on-titan':
        return 'Attack on Titan';
      case 'jujutsu-kaisen':
        return 'Jujutsu Kaisen';
      case 'death-note':
        return 'Death Note';
      case 'tokyo-revengers':
        return 'Tokyo Revengers';
      case 'solo-leveling':
        return 'Solo Leveling';
      case 'my-hero-academia':
        return 'Boku no Hero Academia';
      case 'chainsaw-man':
        return 'Chainsaw Man';
      case 'naruto':
        return 'Naruto';
      case 'one-piece':
        return 'One Piece';
      case 'spy-x-family':
        return 'Spy x Family';
      case 'frieren':
        return 'Sousou no Frieren';
      case 'bleach':
        return 'Bleach';
      case 'hunter-x-hunter':
        return 'Hunter x Hunter';
      case 'fullmetal-alchemist':
        return 'Fullmetal Alchemist: Brotherhood';
      case 'demon-slayer-movie':
        return 'Kimetsu no Yaiba: Infinity Castle / Mugen Train';
      case 'chainsaw-man-movie':
        return 'Chainsaw Man: Reze Arc';
      case 'jujutsu-kaisen-0':
        return 'Jujutsu Kaisen 0';
      case 'your-name':
        return 'Kimi no Na wa. (Your Name)';
      case 'haikyuu-movie':
        return 'Haikyuu!! The Dumpster Battle';
      case 'gintama-movie':
        return 'Gintama: The Final';
      case 'silent-voice':
        return 'Koe no Katachi (A Silent Voice)';
      case 'tokyo-ghoul':
        return 'Tokyo Ghoul';
      case 'steins-gate':
        return 'Steins;Gate';
      case 'dandadan':
        return 'Dandadan';
      case 'dandadan-s2':
        return 'Dandadan Season 2';
      case 'rezero':
        return 'Re:Zero kara Hajimeru Isekai Seikatsu';
      case 'rezero-s3':
        return 'Re:Zero Season 3';
      case 'jujutsu-kaisen-s3':
        return 'Jujutsu Kaisen Season 3';
      case 'solo-leveling-s2':
        return 'Solo Leveling Season 2: Arise from the Shadow';
      case 'frieren-s2':
        return 'Sousou no Frieren Season 2';
      case 'bleach-tybw':
        return 'Bleach: Thousand-Year Blood War';
      case 'tokyo-revengers-s4':
        return 'Tokyo Revengers Season 4';
      case 'spy-x-family-s3':
        return 'Spy x Family Season 3';
      case 'my-hero-academia-s8':
        return 'Boku no Hero Academia Season 8';
      case 'mushoku-tensei':
        return 'Mushoku Tensei: Jobless Reincarnation';
      case 'tensura':
        return 'That Time I Got Reincarnated as a Slime';
      case 'kaiju-no-8':
        return 'Kaiju No. 8';
      case 'oshi-no-ko':
        return 'Oshi no Ko';
      case 'blue-lock':
        return 'Blue Lock';
      case 'kaguya-sama':
        return 'Kaguya-sama: Love Is War';
      case 'horimiya':
        return 'Horimiya';
      case 'gotoubun':
        return 'Gotoubun no Hanayome';
      case 'kimi-ni-todoke':
        return 'Kimi ni Todoke';
      case 'ao-haru-ride':
        return 'Ao Haru Ride';
      case 'code-geass':
        return 'Code Geass: Lelouch of the Rebellion';
      case 'eighty-six':
        return '86 Eighty-Six';
      case 'erased':
        return 'Erased (Boku dake ga Inai Machi)';
      case 'monster':
        return 'Monster';
      case 'parasyte':
        return 'Parasyte -the maxim-';
      case 'overlord':
        return 'Overlord';
      case 'tate-no-yuusha':
        return 'The Rising of the Shield Hero';
      case 'kage-no-jitsuryokusha':
        return 'The Eminence in Shadow';
      case 'kuroko-no-basket':
        return 'Kuroko no Basket';
      case 'shigatsu-wa-kimi':
        return 'Shigatsu wa Kimi no Uso';
      default:
        return 'Anime';
    }
  }

  static final Map<String, List<SubtitleCue>> _subtitles = {
    // Demon Slayer Episode 1 (Cruelty - 残酷)
    'demon-slayer-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 8),
        text: 'Tanjiro: Kenapa harus jadi begini... Nezuko, bertahanlah! Jangan mati!',
      ),
      SubtitleCue(
        start: Duration(seconds: 8),
        end: Duration(seconds: 18),
        text: 'Ibu (Kie): Wajahmu kotor oleh jelaga arang, Tanjiro. Kemarilah agar kuusap.',
      ),
      SubtitleCue(
        start: Duration(seconds: 18),
        end: Duration(seconds: 28),
        text: 'Tanjiro: Ibu, aku akan pergi ke kota untuk menjual arang agar kita semua kenyang di tahun baru.',
      ),
      SubtitleCue(
        start: Duration(seconds: 28),
        end: Duration(seconds: 38),
        text: 'Shigeru & Hanako: Kakak! Kami ingin ikut pergi ke kota bersamamu!',
      ),
      SubtitleCue(
        start: Duration(seconds: 38),
        end: Duration(seconds: 50),
        text: 'Kie: Kalian tidak boleh ikut. Kalian tidak bisa berjalan secepat kakakmu di tengah salju lebat ini.',
      ),
      SubtitleCue(
        start: Duration(seconds: 50),
        end: Duration(seconds: 65),
        text: 'Nezuko: Hati-hati di jalan ya, Kakak! Aku sedang menidurkan Rokuta.',
      ),
      SubtitleCue(
        start: Duration(seconds: 65),
        end: Duration(seconds: 85),
        text: 'Warga Kota: Hei Tanjiro! Arang buatanmu selalu terbakar sangat baik. Terima kasih banyak!',
      ),
      SubtitleCue(
        start: Duration(seconds: 85),
        end: Duration(seconds: 110),
        text: 'Paman Saburo: Tanjiro! Jangan naik gunung saat malam! Menginaplah di gubukku, iblis berkeliaran di malam hari!',
      ),
      SubtitleCue(
        start: Duration(seconds: 110),
        end: Duration(seconds: 135),
        text: 'Tanjiro: Iblis? Apakah iblis pemakan manusia itu benar-benar ada, Paman?',
      ),
      SubtitleCue(
        start: Duration(seconds: 135),
        end: Duration(seconds: 165),
        text: 'Paman Saburo: Ya, sejak zaman kuno. Para Pembasmi Iblis yang mempertaruhkan nyawa melindungi kita.',
      ),
      SubtitleCue(
        start: Duration(seconds: 165),
        end: Duration(seconds: 195),
        text: 'Tanjiro (Kembali ke rumah): Bau apa ini... Bau darah pekat?!',
      ),
      SubtitleCue(
        start: Duration(seconds: 195),
        end: Duration(seconds: 235),
        text: 'Tanjiro: Ibu?! Rokuta?! Hanako?! Takeo?! Kenapa semuanya tewas dibantai... Siapa yang berbuat ini?!',
      ),
      SubtitleCue(
        start: Duration(seconds: 235),
        end: Duration(seconds: 275),
        text: 'Tanjiro: Nezuko... Tubuhnya masih hangat! Nezuko masih hidup! Aku pasti menyelamatkanmu!',
      ),
      SubtitleCue(
        start: Duration(seconds: 275),
        end: Duration(seconds: 320),
        text: 'Giyu Tomioka: Menyingkirlah! Iblis itu bukan lagi adik yang kau kenal!',
      ),
      SubtitleCue(
        start: Duration(seconds: 320),
        end: Duration(seconds: 365),
        text: 'Tanjiro: Tolong jangan bunuh Nezuko! Aku bersumpah akan menyembuhkannya kembali menjadi manusia!',
      ),
      SubtitleCue(
        start: Duration(seconds: 365),
        end: Duration(seconds: 420),
        text: 'Giyu Tomioka: Jangan pernah bersujud memohon belas kasihan pada orang lain! Temui Sakonji Urokodaki di Gunung Sagiri.',
      ),
    ],

    // Demon Slayer Episode 2
    'demon-slayer-ep2': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 5),
        text: 'Tanjiro: Nezuko, masuklah ke dalam keranjang ini agar terlindung dari matahari.',
      ),
      SubtitleCue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 11),
        text: 'Tanjiro: Baunya kuat sekali... Ada bau darah manusia di kuil atas bukit!',
      ),
      SubtitleCue(
        start: Duration(seconds: 11),
        end: Duration(seconds: 18),
        text: 'Iblis Kuil: Hehehe, manusia baru! Tempat ini wilayah makanku!',
      ),
      SubtitleCue(
        start: Duration(seconds: 18),
        end: Duration(seconds: 25),
        text: 'Tanjiro: Nezuko, bantu aku! Dia meregenerasi kepalanya begitu cepat!',
      ),
      SubtitleCue(
        start: Duration(seconds: 25),
        end: Duration(seconds: 34),
        text: 'Sakonji Urokodaki: Keputusanmu terlalu lambat! Belas kasihanmu akan membunuhmu!',
      ),
      SubtitleCue(
        start: Duration(seconds: 34),
        end: Duration(seconds: 45),
        text: 'Urokodaki: Bawa adikmu dan ikuti aku jika kau benar-benar ingin menjadi Pembasmi Iblis!',
      ),
    ],

    // Attack on Titan Episode 1
    'attack-on-titan-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 5),
        text: 'Eren: Pada hari itu, umat manusia teringat kembali...',
      ),
      SubtitleCue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 11),
        text: 'Eren: Rasa takut hidup terkungkung dalam sangkar dinding...',
      ),
      SubtitleCue(
        start: Duration(seconds: 11),
        end: Duration(seconds: 19),
        text: 'Armin: Dinding Maria setinggi 50 meter... ditembus Titan Kolosal!',
      ),
      SubtitleCue(
        start: Duration(seconds: 19),
        end: Duration(seconds: 28),
        text: 'Eren: Ibu! Jangan! Cepat lari dari rumah itu!',
      ),
      SubtitleCue(
        start: Duration(seconds: 28),
        end: Duration(seconds: 40),
        text: 'Eren: Aku akan memusnahkan seluruh Titan dari muka bumi ini!',
      ),
    ],

    // Attack on Titan Episode 2
    'attack-on-titan-ep2': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 6),
        text: 'Hannes: Maafkan aku Eren, aku terlalu takut pada Titan itu...',
      ),
      SubtitleCue(
        start: Duration(seconds: 6),
        end: Duration(seconds: 14),
        text: 'Eren: Ibu... Ibu dimakan tepat di depan mataku...',
      ),
      SubtitleCue(
        start: Duration(seconds: 14),
        end: Duration(seconds: 23),
        text: 'Mikasa: Eren, kau masih memiliki aku. Kau tidak sendirian.',
      ),
      SubtitleCue(
        start: Duration(seconds: 23),
        end: Duration(seconds: 35),
        text: 'Eren: Aku akan bergabung ke Pasukan Pengintai dan membalaskan dendam kita!',
      ),
    ],

    // Jujutsu Kaisen Episode 1
    'jujutsu-kaisen-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 5),
        text: 'Yuji Itadori: Benda apa ini? Jari kering yang dibungkus kertas jimat?',
      ),
      SubtitleCue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 12),
        text: 'Megumi: Hentikan! Itu adalah benda kutukan tingkat khusus!',
      ),
      SubtitleCue(
        start: Duration(seconds: 12),
        end: Duration(seconds: 20),
        text: 'Yuji Itadori: Kalau aku memakannya, apakah aku bisa menyelamatkan semua orang?!',
      ),
      SubtitleCue(
        start: Duration(seconds: 20),
        end: Duration(seconds: 29),
        text: 'Ryomen Sukuna: Hahahaha! Cahaya dunia ini sungguh luar biasa!',
      ),
      SubtitleCue(
        start: Duration(seconds: 29),
        end: Duration(seconds: 38),
        text: 'Yuji: Hei, tubuh ini milikku! Jangan berteriak di dalam kepalaku!',
      ),
    ],

    // Jujutsu Kaisen Episode 2
    'jujutsu-kaisen-ep2': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 6),
        text: 'Gojo Satoru: Yuji, apa kau bisa menukar tubuhmu kembali dalam 10 detik?',
      ),
      SubtitleCue(
        start: Duration(seconds: 6),
        end: Duration(seconds: 13),
        text: 'Yuji Itadori: Tentu saja, aku bisa mengendalikannya sepenuhnya!',
      ),
      SubtitleCue(
        start: Duration(seconds: 13),
        end: Duration(seconds: 22),
        text: 'Gojo Satoru: Luar biasa! Kalau begitu kau akan dipindahkan ke SMK Jujutsu Tokyo!',
      ),
      SubtitleCue(
        start: Duration(seconds: 22),
        end: Duration(seconds: 32),
        text: 'Megumi Fushiguro: Dia bukan manusia biasa... Mengendalikan Sukuna adalah hal mustahil!',
      ),
    ],

    // Solo Leveling Episode 1
    'solo-leveling-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 5),
        text: 'Sung Jinwoo: Hunter terlemah di dunia, Hunter Rank E...',
      ),
      SubtitleCue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 13),
        text: 'Song Chi-yul: Double Dungeon?! Ada lingkaran patung dewa raksasa di sini!',
      ),
      SubtitleCue(
        start: Duration(seconds: 13),
        end: Duration(seconds: 23),
        text: 'Sung Jinwoo: Perintah Kuil: Hormati Tuhan, Pujilah Tuhan, Buktikan Imanmu...',
      ),
      SubtitleCue(
        start: Duration(seconds: 23),
        end: Duration(seconds: 34),
        text: 'Sung Jinwoo: Jangan bergerak! Patung itu menembakkan sinar penghancur!',
      ),
    ],

    // Solo Leveling Episode 2
    'solo-leveling-ep2': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 6),
        text: 'Sung Jinwoo: [Pemberitahuan: Anda telah menyelesaikan Quest Rahasia.]',
      ),
      SubtitleCue(
        start: Duration(seconds: 6),
        end: Duration(seconds: 14),
        text: 'Sung Jinwoo: [Selamat! Anda memenuhi syarat untuk menjadi seorang Player.]',
      ),
      SubtitleCue(
        start: Duration(seconds: 14),
        end: Duration(seconds: 24),
        text: 'Sung Jinwoo: Status window... quest harian... Tubuhku pulih total!',
      ),
      SubtitleCue(
        start: Duration(seconds: 24),
        end: Duration(seconds: 35),
        text: 'Sung Jinwoo: Ini bukan mimpi. Aku bisa terus naik level tanpa batas!',
      ),
    ],

    // Naruto Episode 1
    'naruto-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 5),
        text: 'Naruto: Aku adalah Uzumaki Naruto! Suatu hari aku akan menjadi Hokage!',
      ),
      SubtitleCue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 13),
        text: 'Iruka-sensei: Naruto! Berhenti mencoret-coret wajah para Hokage di batu tebing!',
      ),
      SubtitleCue(
        start: Duration(seconds: 13),
        end: Duration(seconds: 23),
        text: 'Mizuki: Naruto, jika kau mencuri Gulungan Terlarang, kau akan lulus ujian Genin!',
      ),
      SubtitleCue(
        start: Duration(seconds: 23),
        end: Duration(seconds: 35),
        text: 'Iruka-sensei: Dia bukan monster Rubah Ekor Sembilan! Dia adalah murid terbaikku, Uzumaki Naruto!',
      ),
      SubtitleCue(
        start: Duration(seconds: 35),
        end: Duration(seconds: 45),
        text: 'Naruto: Kage Bunshin no Jutsu! Jangan pernah berani menyentuh Iruka-sensei!',
      ),
    ],

    // One Piece Episode 1
    'one-piece-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 5),
        text: 'Gol D. Roger: Hartaku? Jika kalian menginginkannya, carilah! One Piece!',
      ),
      SubtitleCue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 14),
        text: 'Luffy: Aku Monkey D. Luffy, pria yang akan menjadi Raja Bajak Laut!',
      ),
      SubtitleCue(
        start: Duration(seconds: 14),
        end: Duration(seconds: 24),
        text: 'Coby: Luffy-san! Alvida sang Gada Besi akan membunuh kita!',
      ),
      SubtitleCue(
        start: Duration(seconds: 24),
        end: Duration(seconds: 35),
        text: 'Luffy: Gomu Gomu no Pistol! Bajak laut sepertimu tidak ada apa-apanya!',
      ),
    ],

    // Death Note Episode 1
    'death-note-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 6),
        text: 'Light Yagami: Death Note? "Nama manusia yang tertulis di buku ini akan mati."',
      ),
      SubtitleCue(
        start: Duration(seconds: 6),
        end: Duration(seconds: 14),
        text: 'Light Yagami: Konyol sekali... mana mungkin ada buku seperti ini di dunia nyata.',
      ),
      SubtitleCue(
        start: Duration(seconds: 14),
        end: Duration(seconds: 24),
        text: 'Berita: Penjahat penyandera anak-anak dilaporkan meninggal mendadak karena serangan jantung!',
      ),
      SubtitleCue(
        start: Duration(seconds: 24),
        end: Duration(seconds: 35),
        text: 'Ryuk: Sepertinya kau menyukai buku catatanku, manusia.',
      ),
      SubtitleCue(
        start: Duration(seconds: 35),
        end: Duration(seconds: 45),
        text: 'Light Yagami: Aku akan membersihkan dunia dari kejahatan dan menjadi Dewa Dunia Baru!',
      ),
    ],
  };
}

