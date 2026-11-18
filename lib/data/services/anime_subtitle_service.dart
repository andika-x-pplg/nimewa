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
        _subtitles['$animeKey-ep1'] ??
        _defaultCues;

    for (final cue in list) {
      if (position >= cue.start && position <= cue.end) {
        return cue.text;
      }
    }
    return '';
  }

  static const List<SubtitleCue> _defaultCues = [
    SubtitleCue(
      start: Duration(seconds: 0),
      end: Duration(seconds: 5),
      text: '[Sub Indo] Memutar anime dengan takarir bahasa Indonesia.',
    ),
    SubtitleCue(
      start: Duration(seconds: 5),
      end: Duration(seconds: 12),
      text: 'Audio asli Jepang dengan kualitas visual HD Subtitle Indonesia.',
    ),
    SubtitleCue(
      start: Duration(seconds: 12),
      end: Duration(seconds: 22),
      text: 'Selamat menonton streaming anime subtitle Indonesia di Nimeva.',
    ),
  ];

  static final Map<String, List<SubtitleCue>> _subtitles = {
    // Demon Slayer Episode 1
    'demon-slayer-ep1': const [
      SubtitleCue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 4),
        text: 'Tanjiro: Nezuko, bertahanlah! Jangan menyerah!',
      ),
      SubtitleCue(
        start: Duration(seconds: 4),
        end: Duration(seconds: 9),
        text: 'Tanjiro: Kenapa keluargaku dibantai... Siapa yang melakukan ini?!',
      ),
      SubtitleCue(
        start: Duration(seconds: 9),
        end: Duration(seconds: 15),
        text: 'Tanjiro: Tubuh Nezuko hangat... Dia masih hidup! Aku pasti menyelamatkanmu!',
      ),
      SubtitleCue(
        start: Duration(seconds: 15),
        end: Duration(seconds: 22),
        text: 'Giyu Tomioka: Menyingkirlah! Iblis itu bukan lagi adik yang kau kenal!',
      ),
      SubtitleCue(
        start: Duration(seconds: 22),
        end: Duration(seconds: 29),
        text: 'Tanjiro: Jangan bunuh dia! Nezuko tidak memangsa siapapun!',
      ),
      SubtitleCue(
        start: Duration(seconds: 29),
        end: Duration(seconds: 37),
        text: 'Giyu Tomioka: Jangan pernah tundukkan kepalamu di hadapan orang lain!',
      ),
      SubtitleCue(
        start: Duration(seconds: 37),
        end: Duration(seconds: 46),
        text: 'Giyu Tomioka: Pergilah ke Gunung Sagiri. Temui pria bernama Sakonji Urokodaki.',
      ),
      SubtitleCue(
        start: Duration(seconds: 46),
        end: Duration(seconds: 56),
        text: 'Tanjiro: Aku bersumpah akan menemukan obat untuk mengubah Nezuko kembali!',
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
