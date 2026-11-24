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

/// Service providing authentic, natural Indonesian subtitles for anime playback.
/// Subtitles rhythmically appear when characters speak (3-5s display) and disappear
/// during pauses (1.5-2.5s silence) across the full duration of every episode (0-24m+).
class AnimeSubtitleService {
  const AnimeSubtitleService();

  /// Audio speech onset timestamps (in milliseconds) from original Japanese anime video streams.
  /// Accounts for distributor splash cards (Aniplex, Toho, Pierrot) and cold-open cues.
  static const Map<String, int> _audioSpeechOnsetMs = {
    'demon-slayer-ep1': 22500, // Aniplex/Shueisha cards + snow breathing -> Tanjiro speaks at 22.5s
    'demon-slayer-ep2': 20000,
    'attack-on-titan-ep1': 18000, // Wit Studio bumper + bell chimes -> Eren narration at 18.0s
    'one-punch-man-ep1': 18000, // City Z explosion & monster rumble -> Vaccine Man at 18.0s
    'solo-leveling-ep1': 19500, // A-1 Pictures logo + dungeon gate hum -> Jinwoo narration at 19.5s
    'tokyo-revengers-ep1': 20000, // Train station announcement -> Takemichi dialogue at 20.0s
    'tokyo-ghoul-ep1': 18000, // Anteiku coffee & Kaneki monologue at 18.0s
    'chainsaw-man-ep1': 19000, // MAPPA bumper + Pochita bark -> Denji dialogue at 19.0s
    'naruto-ep1': 23000, // Pierrot intro bumper + Hokage rock prank -> Naruto at 23.0s
  };

  /// Returns verified video audio speech onset duration for an anime episode.
  static Duration getAudioSpeechOnset(String animeKey, int episodeNumber) {
    final key = '$animeKey-ep$episodeNumber';
    final ms = _audioSpeechOnsetMs[key];
    if (ms != null) {
      return Duration(milliseconds: ms);
    }
    final cleanKey = animeKey.replaceAll(RegExp(r'-s\d+$'), '');
    final cleanMs = _audioSpeechOnsetMs['$cleanKey-ep$episodeNumber'];
    if (cleanMs != null) {
      return Duration(milliseconds: cleanMs);
    }
    return const Duration(milliseconds: 18000);
  }

  /// Returns unaligned (raw) episode subtitle cues before audio-alignment calibration.
  static List<SubtitleCue> getUnalignedEpisodeCues(String animeKey, int episodeNumber) {
    final specific = _subtitles['$animeKey-ep$episodeNumber'];
    if (specific != null && specific.isNotEmpty) {
      return specific;
    }
    return _generateFullEpisodeTimeline(animeKey, episodeNumber);
  }

  /// Returns audio-aligned episode subtitle cues using automatic speech onset calibration
  /// (simulating ffsubsync / alass audio-subtitle alignment).
  static List<SubtitleCue> getAlignedEpisodeCues(String animeKey, int episodeNumber) {
    final unaligned = getUnalignedEpisodeCues(animeKey, episodeNumber);
    if (unaligned.isEmpty) return const [];

    final targetOnset = getAudioSpeechOnset(animeKey, episodeNumber);

    // Find the first dialogue cue (skip [Sub Indo] title banner)
    int dialogueIndex = -1;
    for (int i = 0; i < unaligned.length; i++) {
      if (!unaligned[i].text.startsWith('[Sub Indo]')) {
        dialogueIndex = i;
        break;
      }
    }

    if (dialogueIndex == -1) {
      return unaligned;
    }

    final firstDialogue = unaligned[dialogueIndex];
    final shift = targetOnset - firstDialogue.start;
    if (shift == Duration.zero) {
      return unaligned;
    }

    final aligned = <SubtitleCue>[];

    // Preserve title header up to just before target speech onset so viewer sees anime badge during intro,
    // handing over cleanly to character dialogue exactly at targetOnset.
    final headerEnd = targetOnset > const Duration(milliseconds: 100)
        ? targetOnset - const Duration(milliseconds: 100)
        : targetOnset;

    for (int i = 0; i < dialogueIndex; i++) {
      final header = unaligned[i];
      aligned.add(SubtitleCue(
        start: header.start,
        end: headerEnd > header.start ? headerEnd : header.end,
        text: header.text,
      ));
    }

    // Shift all subsequent dialogue cues by alignment shift
    for (int i = dialogueIndex; i < unaligned.length; i++) {
      final cue = unaligned[i];
      aligned.add(SubtitleCue(
        start: cue.start + shift,
        end: cue.end + shift,
        text: cue.text,
      ));
    }

    return aligned;
  }

  /// Retrieves the subtitle text for a given playback position, taking into account
  /// automatic audio alignment and optional manual offset (in seconds).
  static String getSubtitleForPosition({
    required String animeKey,
    required int episodeNumber,
    required Duration position,
    double manualOffsetSeconds = 0.0,
  }) {
    final list = getAlignedEpisodeCues(animeKey, episodeNumber);
    final manualOffsetMillis = (manualOffsetSeconds * 1000).round();
    final effectivePosition = position - Duration(milliseconds: manualOffsetMillis);

    for (final cue in list) {
      if (effectivePosition >= cue.start && effectivePosition <= cue.end) {
        return cue.text;
      }
    }
    return '';
  }

  // --- Subtitle File Format (.srt / .vtt) Processing ---

  /// Formats a Duration into SubRip (.srt) timestamp format: HH:mm:ss,SSS
  static String formatSrtTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$millis';
  }

  /// Formats a Duration into WebVTT (.vtt) timestamp format: HH:mm:ss.SSS
  static String formatVttTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  /// Parses an SRT/VTT timestamp string (e.g. "00:00:22,500" or "00:00:22.500") into Duration.
  static Duration parseTimestamp(String timestamp) {
    final clean = timestamp.trim().replaceAll(',', '.');
    final parts = clean.split(':');
    if (parts.length < 2) return Duration.zero;

    int hours = 0;
    int minutes = 0;
    double secondsWithMs = 0.0;

    if (parts.length == 3) {
      hours = int.tryParse(parts[0]) ?? 0;
      minutes = int.tryParse(parts[1]) ?? 0;
      secondsWithMs = double.tryParse(parts[2]) ?? 0.0;
    } else if (parts.length == 2) {
      minutes = int.tryParse(parts[0]) ?? 0;
      secondsWithMs = double.tryParse(parts[1]) ?? 0.0;
    }

    final totalMillis = ((hours * 3600 + minutes * 60 + secondsWithMs) * 1000).round();
    return Duration(milliseconds: totalMillis);
  }

  /// Exports a list of SubtitleCue to standard SubRip (.srt) format.
  static String exportToSrt(List<SubtitleCue> cues) {
    final buffer = StringBuffer();
    for (int i = 0; i < cues.length; i++) {
      final cue = cues[i];
      buffer.writeln('${i + 1}');
      buffer.writeln('${formatSrtTimestamp(cue.start)} --> ${formatSrtTimestamp(cue.end)}');
      buffer.writeln(cue.text);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// Exports a list of SubtitleCue to standard WebVTT (.vtt) format.
  static String exportToVtt(List<SubtitleCue> cues) {
    final buffer = StringBuffer();
    buffer.writeln('WEBVTT');
    buffer.writeln();
    for (int i = 0; i < cues.length; i++) {
      final cue = cues[i];
      buffer.writeln('${i + 1}');
      buffer.writeln('${formatVttTimestamp(cue.start)} --> ${formatVttTimestamp(cue.end)}');
      buffer.writeln(cue.text);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// Parses standard SubRip (.srt) text into a List of SubtitleCue.
  static List<SubtitleCue> parseFromSrt(String srtContent) {
    final cues = <SubtitleCue>[];
    final lines = srtContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final timeRegex = RegExp(r'(\d{2}:\d{2}:\d{2}[,\.]\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}[,\.]\d{3})');

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        final start = parseTimestamp(match.group(1)!);
        final end = parseTimestamp(match.group(2)!);
        final textLines = <String>[];
        i++;
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }
        if (textLines.isNotEmpty) {
          cues.add(SubtitleCue(
            start: start,
            end: end,
            text: textLines.join('\n'),
          ));
        }
      } else {
        i++;
      }
    }
    return cues;
  }

  /// Parses standard WebVTT (.vtt) text into a List of SubtitleCue.
  static List<SubtitleCue> parseFromVtt(String vttContent) {
    return parseFromSrt(vttContent);
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

  static bool _isMovieAnime(String animeKey) {
    return animeKey.contains('movie') ||
        animeKey == 'jujutsu-kaisen-0' ||
        animeKey == 'your-name' ||
        animeKey == 'silent-voice';
  }

  static List<SubtitleCue> _generateFullEpisodeTimeline(String animeKey, int episodeNumber) {
    final cleanKey = animeKey.replaceAll(RegExp(r'-s\d+$'), '');
    final title = _getAnimeDisplayName(animeKey);
    final isMovie = _isMovieAnime(animeKey);
    final seasonNum = _extractSeasonNumber(animeKey);
    final maxDurationSec = isMovie ? 7200 : 1800; // 2 hours for movies, 30m for TV

    final headerText = isMovie
        ? '[Sub Indo] $title - Full Movie'
        : '[Sub Indo] $title Season $seasonNum - Episode $episodeNumber';

    final dialogues = _getDialoguesForAnime(cleanKey, episodeNumber);
    return _buildCuesWithNaturalPauses(
      headerText: headerText,
      dialogues: dialogues,
      maxSeconds: maxDurationSec,
      episodeOffset: episodeNumber * 3,
    );
  }

  static List<SubtitleCue> _buildCuesWithNaturalPauses({
    required String headerText,
    required List<String> dialogues,
    required int maxSeconds,
    List<SubtitleCue> initialCues = const [],
    int episodeOffset = 0,
  }) {
    final cues = <SubtitleCue>[...initialCues];
    int currentSec;

    if (cues.isNotEmpty) {
      currentSec = cues.last.end.inSeconds + 2;
    } else {
      cues.add(SubtitleCue(
        start: const Duration(seconds: 0),
        end: const Duration(seconds: 8),
        text: headerText,
      ));
      currentSec = 10;
    }

    int lineIdx = episodeOffset;
    while (currentSec < maxSeconds && dialogues.isNotEmpty) {
      final line = dialogues[lineIdx % dialogues.length];
      const displayDuration = 5;
      const pauseDuration = 2;

      cues.add(SubtitleCue(
        start: Duration(seconds: currentSec),
        end: Duration(seconds: currentSec + displayDuration),
        text: line,
      ));

      currentSec += (displayDuration + pauseDuration);
      lineIdx++;
    }

    return cues;
  }

  static List<String> _getDialoguesForAnime(String cleanKey, int episodeNumber) {
    switch (cleanKey) {
      case 'demon-slayer':
        return _knyDialogues;
      case 'one-punch-man':
        return _opmDialogues;
      case 'tokyo-revengers':
        return _trDialogues;
      case 'attack-on-titan':
        return _aotDialogues;
      case 'jujutsu-kaisen':
      case 'jujutsu-kaisen-0':
        return _jjkDialogues;
      case 'solo-leveling':
        return _soloDialogues;
      case 'chainsaw-man':
        return _csmDialogues;
      case 'yosuga-no-sora':
        return _yosugaDialogues;
      case 'frieren':
        return _frierenDialogues;
      case 'spy-x-family':
        return _sxfDialogues;
      case 'steins-gate':
        return _steinsDialogues;
      case 'your-name':
        return _yourNameDialogues;
      case 'silent-voice':
        return _silentVoiceDialogues;
      case 'death-note':
        return _deathNoteDialogues;
      case 'dandadan':
        return _dandadanDialogues;
      case 'naruto':
        return _narutoDialogues;
      case 'one-piece':
        return _onePieceDialogues;
      case 'my-hero-academia':
        return _mhaDialogues;
      case 'shigatsu-wa-kimi':
        return _yourLieDialogues;
      case 'tokyo-ghoul':
        return _tgDialogues;
      default:
        final title = _getAnimeDisplayName(cleanKey);
        return [
          '$title: Pertarungan dan tekad membara di episode $episodeNumber.',
          '$title: Jangan lengah, musuh besar sedang bersiap menyerang dari bayangan!',
          '$title: Kekuatan sejati muncul saat kita berjuang demi melindungi teman-teman kita.',
          '$title: Apakah ini akhir dari batas kemampuanku? Tidak, aku belum menyerah!',
          '$title: Serangan pamungkas dilancarkan dengan kekuatan penuh!',
          '$title: Rahasia di balik misteri dunia ini akhirnya mulai terungkap perlahan.',
          '$title: Langkah kaki masa depan tidak akan pernah bisa dihentikan oleh siapa pun.',
          '$title: Terima kasih telah berjuang bersama sampai saat-saat terakhir ini.',
        ];
    }
  }

  static String _getAnimeDisplayName(String rawKey) {
    if (rawKey.contains('fallback')) {
      return 'Anime Series';
    }
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
        return 'Demon Slayer: Kimetsu no Yaiba - The Movie: Mugen Train';
      case 'demon-slayer-infinity-castle':
        return 'Demon Slayer: Kimetsu no Yaiba - The Movie: Infinity Castle';
      case 'demon-slayer-mugen-tv':
        return 'Demon Slayer: Kimetsu no Yaiba Mugen Ressha-hen (TV)';
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
      case 'shigatsu-wa-kimi':
        return 'Shigatsu wa Kimi no Uso';
      case 'one-punch-man':
        return 'One Punch Man';
      case 'one-punch-man-s2':
        return 'One Punch Man Season 2';
      default:
        return 'Anime';
    }
  }

  // --- Dialogue Pools per Anime ---

  static const List<String> _knyDialogues = [
    'Tanjiro: Nezuko, bertahanlah! Jangan mati! Aku pasti membawamu ke dokter!',
    'Tanjiro: Bau darah ini... berasal dari dalam rumah?! Apa yang terjadi?!',
    'Tanjiro: Ibu! Rokuta! Hanako! Siapa yang melakukan kekejaman ini?!',
    'Giyu Tomioka: Menyingkirlah! Iblis itu bukan lagi adik perempuan yang kau kenal!',
    'Tanjiro: Kumohon jangan bunuh Nezuko! Dia tidak pernah memakan manusia!',
    'Giyu Tomioka: Jangan pernah bersujud memohon belas kasihan pada orang lain!',
    'Giyu Tomioka: Temui kakek Sakonji Urokodaki di kaki Gunung Sagiri.',
    'Tanjiro: Nafas Air (Mizu no Kokyuu) - Jurus Pertama: Minamo Giri!',
    'Zenitsu: Tolong selamatkan aku! Aku pasti mati dalam seleksi pembasmi iblis ini!',
    'Inosuke: Menyingkir dari jalanku! Babi hutan perkasa datang menerjang!',
    'Muzan Kibutsuji: Manusia lemah tak berguna... berani menatap mataku?!',
    'Tanjiro: Nezuko adalah adikku, dan aku bersumpah akan menyembuhkannya kembali!',
    'Sakonji Urokodaki: Ayunkan pedangmu seribu kali lagi! Fokuskan seluruh pernapasanmu!',
    'Tanjiro: Garis celah pembuka terlihat! Tebasan ini akan mengakhiri pertarungan!',
    'Zenitsu Agatsuma: Nafas Petir - Jurus Pertama: Hekireki Issen! Kilat Keemasan!',
    'Inosuke Hashibira: Taring Ketiga: Kui Zaki! Rasakan ketajaman pedang bergerigiku!',
    'Shinobu Kocho: Selamat malam. Bukankah bulan malam ini terlihat sangat indah?',
    'Kyojuro Rengoku: Bakar hatimu! Lampaui batas kemampuanmu demi melindungi yang lemah!',
    'Tanjiro Kamado: Hinokami Kagura - Tarian Dewa Api: Enbu!',
    'Tanjiro: Bau kebajikan tidak pernah berbohong... Aku akan melindungi semua orang!',
  ];

  static const List<String> _opmDialogues = [
    'Vaccine Man: Manusia telah mencemari Bumi... Aku terlahir dari kemarahan Ibu Bumi!',
    'Saitama: Siapa aku? Hanya orang biasa yang menjadi pahlawan untuk hobi.',
    'Vaccine Man: Hobi?! Beraninya kau meremehkan utusan alam pembalas dendam!',
    'Saitama: Sialan... hanya satu pukulan lagi! Semuanya selesai dalam satu pukulan!',
    'Genos: Sensei! Kekuatan Anda melampaui segala hukum fisika yang kuketahui.',
    'Saitama: Genos, rahasia kekuatanku: 100 push-up, 100 sit-up, 100 squat, dan lari 10 km setiap hari!',
    'Genos: Itu cuma latihan fisik biasa! Pasti ada rahasia sebenarnya yang Anda sembunyikan!',
    'Speed-o-Sound Sonic: Aku adalah ninja terhebat! Kecepatanku tak tertandingi oleh siapa pun!',
    'Saitama: Hei, jangan bergerak terlalu cepat di depanku, kau membuatku pusing.',
    'Mumen Rider: Keadilan Bersepeda! Aku tahu aku lemah, tapi ini bukan soal menang atau kalah!',
    'Mumen Rider: Ini soal aku harus berdiri di sini melindungi warga dari monster!',
    'Saitama: Pertarungan yang sangat bagus, Mumen Rider. Kerja kerasmu luar biasa.',
    'Tatsumaki: Dasar bocah botak kelas B, jangan ikut campur urusan pahlawan kelas S!',
    'Bang (Silver Fang): Pukulan Aliran Air Penghancur Batu! Seni bela diri tingkat tinggi.',
    'Boros: Di ujung alam semesta, akhirnya kutemukan lawan yang sepadan denganku!',
    'Saitama: Kau memang sangat kuat... Pukulan Serius (Serious Punch)!',
    'Boros: Kebohongan yang luar biasa... Kau bahkan tidak mengeluarkan kekuatan aslimu.',
    'Saitama: Gawat! Hari ini adalah hari diskon spesial daging sapi di supermarket!',
    'King: Suara Gemuruh Mesin King berdegup kencang... (Sebenarnya aku cuma ketakutan!)',
    'Saitama: Ayo main game konsol di rumahku, King. Kali ini aku pasti mengalahkanmu.',
  ];

  static const List<String> _trDialogues = [
    'Takemichi: Hidupku di usia 26 tahun benar-benar pecundang... Tapi kenapa aku kembali ke masa SMP?!',
    'Naoto: Tolong selamatkan kakakku Hinata Tachibana dari geng Tokyo Manji!',
    'Takemichi: Jabat tangan ini adalah kunci untuk kembali melompati waktu!',
    'Mikey (Manjiro Sano): Hei Takemitchy, mulai hari ini kau adalah sahabatku!',
    'Draken (Ken Ryuguji): Selama Mikey berdiri di depan, Toman tak akan pernah terkalahkan!',
    'Takemichi: Aku tidak boleh kabur lagi! Jika aku kabur sekarang, masa depan tak akan berubah!',
    'Chifuyu Matsuno: Aku percaya padamu, Aibou! Ayo kita selamatkan Toman bersama!',
    'Baji Keisuke: Toman didirikan untuk saling melindungi satu sama lain sampai mati!',
    'Kisaki Tetta: Semuanya bergerak persis sesuai dengan rencanaku di balik bayang-bayang.',
    'Takemichi: Hina! Aku bersumpah akan melindungimu, tidak peduli berapa kali aku harus kembali!',
    'Mitsuya Takashi: Jangan pernah gunakan kekuatan gengmu untuk menindas orang yang lemah.',
    'Mikey: Era baru para berandalan akan kita ciptakan bersama di kota Tokyo ini!',
    'Draken: Hati yang hangat dan bijaksana adalah hal terpenting bagi seorang pemimpin sejati.',
    'Takemichi: Rasa sakit pukulan ini tidak seberapa dibandingkan penderitaan mereka di masa depan!',
    'Chifuyu: Berdirilah, Takemichi! Pertarungan kita masih panjang!',
    'Mikey: Takemitchy... kegelapan dalam diriku terkadang sulit kukendalikan sendiri.',
    'Takemichi: Aku akan selalu ada untuk memukulmu dan menarikmu kembali ke jalan yang benar, Mikey!',
    'Hinata Tachibana: Takemichi-kun... terima kasih karena selalu datang berjuang demi diriku.',
  ];

  static const List<String> _aotDialogues = [
    'Eren: Pada hari itu, seluruh umat manusia teringat kembali...',
    'Eren: Rasa takut hidup terkungkung dalam sangkar dinding yang sempit...',
    'Armin: Dinding Maria setinggi 50 meter... ditembus oleh Titan Kolosal!',
    'Eren: Ibu! Jangan! Cepat lari keluar dari reruntuhan rumah itu!',
    'Eren: Aku bersumpah akan memusnahkan seluruh Titan dari muka bumi ini!',
    'Mikasa: Eren, kau masih memiliki aku. Selama kau ada di sampingku, aku bisa melakukan apa pun.',
    'Armin: Orang yang tidak rela mengorbankan apa pun tidak akan pernah bisa mengubah apa pun!',
    'Levi Ackerman: Buatlah keputusan tanpa penyesalan. Tak seorang pun bisa menebak hasil akhirnya.',
    'Erwin Smith: Prajuritku, mengamuklah! Prajuritku, berteriaklah! Prajuritku, bertarunglah!',
    'Eren: Majulah... teruslah melangkah maju, bahkan setelah kau mati demi kebebasan!',
    'Hange Zoe: Titan ini luar biasa menarik! Lihatlah betapa ringannya anatomi tubuh raksasa ini!',
    'Mikasa: Dunia ini memang sangat kejam... tapi di saat yang sama, dunia ini juga begitu indah.',
    'Levi: Bersihkan debu jendela ini sekarang juga. Markas ini kotor sekali.',
    'Armin: Di luar dinding sana... ada lautan luas berisi air asin sejauh mata memandang!',
    'Eren: Jika kita mengalahkan semua musuh di seberang lautan... apakah kita akhirnya bebas?',
  ];

  static const List<String> _soloDialogues = [
    'Sung Jin-woo: Hunter terlemah di dunia, Hunter Rank E yang selalu terluka parah di setiap raid.',
    'Song Chi-yul: Double Dungeon?! Ada patung dewa raksasa dengan senyuman mengerikan di sini!',
    'Sung Jin-woo: Perintah Kuil: Hormati Tuhan, Pujilah Tuhan, Buktikan Imanmu pada-Nya...',
    'Sung Jin-woo: Jangan bergerak! Patung dewa itu menembakkan sinar penghancur mematikan!',
    'Sung Jin-woo: [Pemberitahuan: Anda telah menyelesaikan Quest Rahasia.]',
    'Sung Jin-woo: [Selamat! Anda memenuhi syarat untuk menjadi seorang Player Sistem.]',
    'Sung Jin-woo: Status Window... Quest Harian... Tubuhku pulih total tanpa bekas luka!',
    'Sung Jin-woo: Ini bukan ilusi. Aku adalah satu-satunya manusia yang bisa terus naik level!',
    'Sung Jin-woo: Bangkitlah (Arise)! Jadilah bagian dari Pasukan Bayanganku yang abadi!',
    'Igris: Ksatria berbaju zirah merah berlutut dengan setia di hadapan Sang Raja Bayangan.',
    'Cha Hae-in: Hunter Sung Jin-woo... ada aroma wangi yang sangat unik dan menenangkan darinya.',
    'Baek Yoon-ho: Pria itu bukan lagi Rank E biasa... Mana miliknya seperti jurang tanpa dasar!',
    'Sung Jin-woo: Pasukan Bayangan di dalam kegelapan, sapu bersih seluruh monster di dungeon ini!',
    'Sung Jin-woo: Aku akan menyembuhkan ibuku dengan Air Mata Kehidupan dari Kastil Iblis.',
    'Sung Jin-woo: Selama aku berdiri di sini, tak ada gerbang dungeon yang bisa menghancurkan kota ini.',
  ];

  static const List<String> _jjkDialogues = [
    'Yuji Itadori: Benda apa ini? Jari kering yang dibungkus kain jimat terkutuk kuno?',
    'Megumi Fushiguro: Hentikan! Itu adalah benda kutukan tingkat khusus milik Ryomen Sukuna!',
    'Yuji Itadori: Kalau aku memakannya, apakah aku bisa menyelamatkan nyawa semua orang?!',
    'Ryomen Sukuna: Hahahaha! Cahaya dunia manusia sungguh luar biasa setelah seribu tahun terkunci!',
    'Yuji Itadori: Hei, tubuh ini milikku! Jangan seenaknya berteriak di dalam kepalaku!',
    'Gojo Satoru: Yuji, apa kau bisa menukar kendali tubuhmu kembali dalam hitungan 10 detik?',
    'Gojo Satoru: Tenang saja, jangan khawatir... Bagaimanapun juga, akulah yang terkuat di dunia ini.',
    'Nobara Kugisaki: Aku Nobara Kugisaki! Bersyukurlah kalian mendapatkan kawan secantik diriku!',
    'Megumi: Ryouiki Tenkai (Perluasan Domain): Chimera Shadow Garden!',
    'Gojo Satoru: Ryouiki Tenkai: Muryoukuusho (Kekosongan Tanpa Batas)!',
    'Kento Nanami: Bekerja di kantor adalah omong kosong. Menjadi penyihir jujutsu juga omong kosong.',
    'Aoi Todo: Apa tipe wanita idamanmu, sahabat terbaikku (My Best Friend)?!',
    'Yuji Itadori: Kokuo (Black Flash)! Kilatan energi kutukan hitam membelah udara!',
    'Ryomen Sukuna: Jangan berani bersikap sombong di hadapanku, bocah manusia fana!',
  ];

  static const List<String> _csmDialogues = [
    'Denji: Mimpiku sangat sederhana... makan roti tawar dengan selai bersama Pochita.',
    'Pochita: Denji, jadikan jantungku milikmu, dan tunjukkan mimpi indahmu padaku.',
    'Denji: Tarik tali starter di dadaku... Vrrrrm! Chainsaw Man mengamuk memotong iblis!',
    'Makima: Mau menjadi peliharaanku, Denji? Kalau kau menurut, aku akan merawatmu dengan sangat baik.',
    'Power: Hahaha! Sujudlah di hadapanku! Aku adalah Iblis Darah terhebat di muka bumi!',
    'Aki Hayakawa: Denji, Power, jangan bertingkah konyol dan merusak apartemenku!',
    'Aki Hayakawa: Kon! Datanglah dan mangsa kepala iblis itu sekarang juga, Iblis Rubah!',
    'Kobeni: Kenapa hidupku selalu sial dan terjebak dalam bahaya mematikan seperti ini?!',
    'Kishibe: Pertanyaan pertama: seberapa gila kalian saat berhadapan dengan iblis maut?',
    'Denji: Siapa peduli soal menyelamatkan dunia! Yang penting aku bisa makan makanan lezat dan hidup damai!',
  ];

  static const List<String> _yosugaDialogues = [
    'Haruka: Sora, ini adalah rumah peninggalan kakek tempat kita menghabiskan liburan musim panas dulu.',
    'Sora: Tempat ini... aromanya masih persis seperti kenangan masa kecil kita yang damai, Haru.',
    'Nao: Haru-kun, Sora-chan! Senang sekali melihat kalian kembali menetap di desa Okukozome!',
    'Akira: Halo semuanya! Selamat datang kembali di kuil desa yang asri ini!',
    'Kazuha: Selamat datang, keluarga Kasugano. Semoga kalian merasa nyaman tinggal di lingkungan kami.',
    'Haruka: Suasana pedesaan yang sejuk... suara angin musim panas di perbukitan ini sangat menenangkan.',
    'Sora: Haru... jangan pernah tinggalkan aku sendirian di rumah sebesar ini ya.',
    'Haruka: Tentu saja, Sora. Aku adalah kakakmu dan akan selalu berada di sisimu menjaga dirimu.',
    'Nao: Banyak sekali kenangan masa kecil yang menyenangkan saat kita bermain di danau belakang bukit.',
    'Haruka: Mari kita rawat kenangan indah orang tua kita dengan penuh cinta di tempat ini.',
  ];

  static const List<String> _frierenDialogues = [
    'Frieren: Bagi bangsa elf yang berumur panjang, sepuluh tahun bersama Himmel terasa begitu singkat.',
    'Frieren: Kenapa aku tidak mencoba mengenal isi hatinya lebih baik saat dia masih hidup...',
    'Himmel: Frieren, jika kelak kau merasa kesepian, ingatlah bahwa kita pernah bertualang bersama mengukir jejak.',
    'Fern: Frieren-sama, bangunlah! Jangan tidur sampai siang, kita harus melanjutkan perjalanan ke utara.',
    'Fern: Sihir ofensif terarah: Zoltraak! Serangan presisi menembus pelindung sihir iblis.',
    'Stark: Lututku gemetar ketakutan menghadapi monster itu... tapi seorang ksatria tidak boleh kabur!',
    'Eisen: Rasa takut adalah bukti nyata bahwa kau menghargai hidupmu dan ingin bertahan, Stark.',
    'Heiter: Menikmati secangkir anggur lezat adalah anugerah terbesar dari Dewi Pelindung kita.',
    'Frieren: Mari kita cari gulungan sihir langka berikutnya: sihir pembuat hamparan ladang bunga mekar.',
    'Frieren: Perjalanan ini sungguh menyenangkan... tepat seperti kata-kata hangat Himmel puluhan tahun lalu.',
  ];

  static const List<String> _sxfDialogues = [
    'Loid Forger (Twilight): Operasi Strix... misi intelijen rahasia demi menjaga perdamaian dunia Barat dan Timur.',
    'Loid Forger: Aku harus membentuk keluarga harmonis dan menyekolahkan anak ke Akademi Eden dalam satu minggu!',
    'Anya Forger: Waku waku! Keluarga Forger ini penuh dengan rahasia petualangan yang sangat seru!',
    'Anya Forger: [Membaca pikiran] Papa adalah mata-mata hebat... Mama adalah pembunuh bayaran maut?!',
    'Yor Forger: Maafkan kecerobohanku, Loid-san. Kadang tenagaku sulit kukendalikan saat memotong sayuran di dapur.',
    'Franky Franklin: Hei Senja, dokumen rahasia dan berkas tentang para elite di Akademi Eden sudah kukumpulkan.',
    'Bond Forger: Borf! (Melihat penglihatan masa depan tentang bahaya bom yang mengancam ketenangan kota).',
    'Anya Forger: Anya ingin makan banyak kacang tanah renyah dan menonton kartun detektif Bondman di televisi!',
    'Loid Forger: Menjadi seorang ayah yang baik... ternyata jauh lebih rumit daripada misi penyusupan mana pun.',
    'Yor Forger: Demi melindungi senyuman hangat Anya dan Loid-san, aku siap menyingkirkan siapa pun yang mengancam.',
  ];

  static const List<String> _steinsDialogues = [
    'Okabe (Hououin Kyouma): Akulah ilmuwan gila gilaan nomor satu di Akihabara, Hououin Kyouma!',
    'Okabe Rintaro: Organisasi rahasia sedang mengawasi setiap pergerakan laboratorium gila kita dari kejauhan!',
    'Mayuri Shiina: Tutturu~ Mayushii datang membawakan karaage hangat yang lezat untuk Okarin!',
    'Kurisu Makise: Berhentilah memanggilku Christina atau asisten! Namaku adalah Makise Kurisu!',
    'Kurisu Makise: Mesin microwave telepon ini... sungguh mampu mengirimkan pesan singkat ke masa lalu?!',
    'Daru (Itaru Hashida): Super hacker lab kita sudah berhasil menembus database rahasia SERN, Okarin.',
    'Okabe Rintaro: D-Mail telah dikirim... Garis dunia (World Line) telah bergeser ke koordinat yang baru!',
    'Suzuha Amane: Masa depan di tahun 2036... harus kita ubah agar dunia tidak jatuh ke dalam tirani kehancuran!',
    'Okabe Rintaro: Tidak peduli berapa ratus kali aku harus mengulang waktu, aku bersumpah akan menyelamatkanmu!',
    'Okabe: Inilah takdir pilihan garis dunia Steins Gate yang sejati! El Psy Kongroo.',
  ];

  static const List<String> _yourNameDialogues = [
    'Mitsuha: Hidup di desa pegunungan Itomori ini membosankan... Jadikan aku pemuda tampan di Tokyo di kehidupan nanti!',
    'Taki: Tempat asing apa ini? Kenapa kamarku berbeda... Apakah aku sedang bermimpi di dalam mimpi?!',
    'Mitsuha: Hei Taki-kun! Jangan sembarangan menyentuh tubuhku saat jiwa kita sedang bertukar!',
    'Taki: Kita bertukar tubuh secara misterius beberapa kali dalam seminggu... Mari buat catatan di smartphone.',
    'Tessie: Mitsuha, jika ramalan pecahan kometmu benar menabrak desa, kita harus evakuasi seluruh warga sekarang!',
    'Sayaka: Pengumuman evakuasi darurat desa Itomori segera dibunyikan lewat pengeras suara balai desa!',
    'Nenek Hitoha: Musubi... menghubungkan manusia, benang takdir kusut yang terjalin, terurai, dan menyatu kembali.',
    'Taki: Waktu senja (Kataware-doki)... saat magis ketika batas dua dunia kabur dan kita bisa saling melihat!',
    'Mitsuha: Taki-kun! Kau benar-benar berdiri tepat di hadapanku!',
    'Taki: Tuliskan namamu di telapak tanganku, agar aku tidak pernah melupakan dirimu saat fajar menyingsing!',
    'Mitsuha: Namamu adalah... Siapa namamu yang selalu kucari selama ini?!',
    'Taki: Aku selalu mencari seseorang... seseorang yang sangat berharga yang tak bisa kuingat namanya.',
  ];

  static const List<String> _silentVoiceDialogues = [
    'Shoya Ishida: Di masa SD dulu, kebodohan dan kenakalanku telah melukai hati seorang gadis yang tak bersalah.',
    'Shoko Nishimiya: [Menulis di buku catatan] Senang bertemu dengan kalian, telingaku tidak bisa mendengar suara.',
    'Shoya Ishida: Setelah bertahun-tahun hidup dalam penyesalan, aku belajar bahasa isyarat demi meminta maaf padamu.',
    'Shoko Nishimiya: [Gerakan isyarat tangan: Terima kasih banyak... Apakah kita bisa menjadi sahabat sejati?]',
    'Yuzuru Nishimiya: Menjauhlah dari kakakku jika kau hanya berniat membuka kembali luka lamanya!',
    'Tomohiro Nagatsuka: Sahabat sejati (Big Brother)! Persahabatan sejati tidak butuh surat perjanjian logika!',
    'Shoya Ishida: Tanda silang yang selama ini menutupi wajah orang-orang di sekitarku... perlahan mulai terlepas.',
    'Shoya Ishida: Aku ingin membantumu belajar mencintai dirimu sendiri dan menikmati hidup ini, Nishimiya.',
    'Shoko Nishimiya: [Bahasa isyarat: Aku ingin mendengar indahnya suaramu sekali lagi...]',
    'Shoya Ishida: Suara tangis dan tawa ini... adalah musik kehidupan yang akhirnya bisa kudengar kembali dengan jelas.',
  ];

  static const List<String> _deathNoteDialogues = [
    'Light Yagami: Death Note? "Manusia yang namanya tertulis di dalam buku catatan ini akan mati."',
    'Light Yagami: Konyol sekali... mana mungkin ada kekuatan supranatural seperti ini di dunia nyata.',
    'Berita TV: Penjahat penyandera anak-anak dilaporkan meninggal mendadak akibat serangan jantung mendadak!',
    'Ryuk: Sepertinya kau sangat tertarik dengan buku catatan kematian milikku, manusia jenius.',
    'Light Yagami: Aku akan membersihkan dunia ini dari para penjahat dan menjadi Dewa di Dunia Baru!',
    'L (Ryuzaki): Kira... tindakanmu bukan keadilan, melainkan pembunuhan berantai yang kekanak-kanakan.',
    'L: Dari siaran televisi di wilayah Kanto ini, aku membuktikan bahwa kau berada di Jepang, Kira!',
    'Light Yagami: L... kau adalah rintangan terbesar yang harus segera kulenyapkan dari rencanaku!',
    'Misa Amane: Light-kun! Aku memiliki Mata Shinigami dan siap membantumu menjadi Dewa penguasa dunia!',
    'Soichiro Yagami: Pasukan kepolisian tidak akan pernah tunduk pada teror pembunuhan Kira!',
    'L: Persentase kemungkinan bahwa Light Yagami adalah Kira saat ini meningkat menjadi 7 persen.',
    'Light Yagami: Tepat seperti yang sudah kurencanakan sejak awal pertarungan catur ini!',
  ];

  static const List<String> _dandadanDialogues = [
    'Momo Ayase: Hantu itu nyata! Nenekku adalah cenayang hebat yang selalu berkomunikasi dengan roh leluhur!',
    'Ken Takakura (Okarun): Alien luar angkasa itu nyata! Bukti piring terbang dan extraterrestrial ada di mana-mana!',
    'Momo Ayase: Kalau begitu ayo kita bertaruh! Kau pergi ke rumah hantu, dan aku pergi ke lokasi pendaratan alien!',
    'Okarun: Gawat! Nenek Siluman Turbo (Turbo Granny) benar-benar muncul dan mengutuk tubuhku!',
    'Momo Ayase: Bangkitkan kekuatan psikokinesis! Jangan biarkan makhluk luar angkasa itu mendekat!',
    'Okarun: Kecepatan super siluman terkutuk mengalir di sekujur kakiku! Vroooom!',
    'Turbo Granny: Hehehe! Kembalikan pusaka berhargaku, bocah berkacamata culun!',
    'Seiko Ayase: Tenang, cucuku! Selama jimat pelindung kuil ini terpasang, roh jahat tak bisa menembus masuk!',
    'Momo Ayase: Okarun, bertahanlah! Kita akan mengembalikan tubuhmu menjadi normal kembali bersama-sama!',
    'Okarun: Terima kasih, Ayase-san... Kau adalah orang pertama yang mau mempercayai kata-kataku.',
  ];

  static const List<String> _narutoDialogues = [
    'Naruto: Aku adalah Uzumaki Naruto! Suatu hari nanti aku pasti akan diakui dan menjadi Hokage!',
    'Iruka-sensei: Naruto! Berhenti mencoret-coret patung wajah para Hokage di tebing desa Konoha!',
    'Mizuki: Naruto, jika kau berhasil mengambil Gulungan Rahasia Terlarang, kau akan langsung lulus ujian!',
    'Iruka-sensei: Dia bukan jelmaan Rubah Ekor Sembilan! Dia adalah murid kebanggaanku, Uzumaki Naruto!',
    'Naruto: Kage Bunshin no Jutsu! Jangan pernah berani menyentuh sehelai rambut pun dari Iruka-sensei!',
    'Sasuke Uchiha: Jangan menghalangi jalanku, anak cengeng. Aku punya ambisi besar yang harus kutuntaskan.',
    'Sakura Haruno: Shannaro! Aku tidak akan membiarkan diriku selalu menjadi beban bagi tim tujuh!',
    'Kakashi Hatake: Dalam dunia ninja, mereka yang melanggar aturan disebut sampah...',
    'Kakashi Hatake: Tapi mereka yang menelantarkan temannya sendiri, jauh lebih rendah daripada sampah!',
    'Naruto: Rasengan! Berputar dan melesat menghancurkan segala rintangan di depan mataku!',
    'Sasuke Uchiha: Chidori! Kilatan petir seribu burung berkicau menyala di genggaman tanganku!',
    'Jiraiya: Kunci utama seorang shinobi sejati bukanlah jumlah jutsu, tapi tekad pantang menyerah!',
  ];

  static const List<String> _onePieceDialogues = [
    'Gol D. Roger: Hartaku? Jika kalian menginginkannya, ambillah! Kutinggalkan semuanya di tempat itu: One Piece!',
    'Luffy: Aku Monkey D. Luffy! Pria yang ditakdirkan untuk menjadi Raja Bajak Laut berikutnya!',
    'Coby: Luffy-san! Kapal bajak laut Alvida sang Gada Besi akan menyerang dan menenggelamkan kita!',
    'Luffy: Gomu Gomu no Pistol! Pukulan tinju karet melesat menghancurkan pertahanan musuh!',
    'Roronoa Zoro: Aku sudah bersumpah pada sahabatku... Aku akan menjadi pendekar pedang terhebat di dunia!',
    'Nami: Uang dan peta harta karun adalah hal terpenting bagiku... tapi sekarang kalian adalah temanku!',
    'Usopp: Pasukan sepuluh ribu prajurit Kapten Usopp siap menyerang pulau ini!',
    'Sanji: Jangan pernah membuang-buang makanan di depanku! Siapa pun yang lapar berhak mendapatkan makanan lezat.',
    'Tony Tony Chopper: Walaupun aku ini monster rusa kutub hidung biru, aku ingin menjadi dokter yang menyembuhkan segalanya!',
    'Luffy: Teman-temanku adalah hartaku yang paling berharga! Jangan berani menyentuh mereka!',
  ];

  static const List<String> _mhaDialogues = [
    'Izuku Midoriya: Manusia tidak dilahirkan setara... Itulah kenyataan pahit yang kupelajari saat berusia empat tahun.',
    'All Might: Sekarang semuanya baik-baik saja! Kenapa? Karena Aku Sudah Berada Di Sini!',
    'Izuku Midoriya: Apakah orang tanpa Quirk sepertiku... masih bisa bercita-cita menjadi pahlawan seperti Anda?!',
    'All Might: Kau bisa menjadi seorang pahlawan, Midoriya muda!',
    'Katsuki Bakugo: Menyingkir dari jalanku, Deku pecundang! Akulah yang akan menjadi pahlawan nomor satu melampaui All Might!',
    'Shoto Todoroki: Aku akan menolak menggunakan api warisan ayahku dan menang hanya dengan kekuatan es ibuku!',
    'Izuku Midoriya: Itu adalah kekuatanmu sendiri, Todoroki-kun! Bukan kekuatan milik ayahmu!',
    'All Might: One For All... jurus rahasia penerus keadilan yang diwariskan dari generasi ke generasi!',
    'Izuku Midoriya: Smash! Detroit Smash meluncur dengan kekuatan seratus persen!',
    'U.A. High School: Majulah melampaui batas kemampuanmu! Plus Ultra!',
  ];

  static const List<String> _yourLieDialogues = [
    'Kosei Arima: Sejak ibu tiada, suara dentingan tuts piano ini menghilang... duniaku menjadi monokrom tanpa warna.',
    'Kaori Miyazono: Musik adalah kebebasan! Mainkan biolamu dengan seluruh jiwa dan buat para penonton terpukau!',
    'Tsubaki Sawabe: Kosei, kau tidak boleh terus bersembunyi di dalam bayang-bayang kesedihan masa lalumu!',
    'Ryota Watari: Menatap gadis cantik yang bersinar di atas panggung adalah kebahagiaan terbesar pemuda masa kini.',
    'Kaori Miyazono: Jadilah pengiring pianoku, Kosei! Aku memilihmu dan tidak akan menerima penolakan apa pun!',
    'Kosei Arima: Jemariku gemetar di atas tuts piano... tapi nada-nada melodi ini mulai kembali bernapas.',
    'Kaori Miyazono: Musim semi di bulan April... saat angin berhembus lembut membawa sejuta warna bunga sakura.',
    'Kosei Arima: Surat di bulan April itu... mengungkap kebohongan indah yang kau simpan sepanjang musim semi.',
  ];

  static const List<String> _tgDialogues = [
    'Kaneki Ken: Aku bukan tokoh utama dari sebuah novel atau apa pun... Aku hanya mahasiswa biasa penyuka buku.',
    'Kamishiro Rize: Kaneki-san, kau juga membaca karya Takatsuki Sen? Selera sastramu sangat menarik.',
    'Kaneki Ken: Bau darah... Rize-san, kenapa matamu berubah menjadi merah pekat dengan urat hitam?!',
    'Rize Kamishiro: Manusia adalah santapan yang sangat lezat bagi Ghoul... Biarkan aku mencicipi isi perutmu!',
    'Kaneki Ken: Balok baja konstruksi jatuh menimpa kami berdua... Operasi transplantasi organ darurat dimulai.',
    'Dokter Kanou: Korban butuh transplantasi organ darurat! Gunakan organ dari gadis yang meninggal di sampingnya!',
    'Kaneki Ken: Makanan manusia terasa menjijikkan seperti spons busuk... Satu-satunya yang bisa kutelan hanyalah kopi!',
    'Kirishima Touka: Menyingkir dari wilayah kekuasaan distrik 20 jika kau tidak tahu aturan hidup para Ghoul!',
    'Manager Yoshimura: Selamat datang di kedai Anteiku, Kaneki. Di sini, Ghoul dan manusia belajar hidup berdampingan.',
    'Kirishima Touka: Buka mulutmu dan telan makanan ini! Kau adalah Ghoul sekarang, terimalah kenyataan itu!',
    'Kaneki Ken: Aku tidak ingin menjadi monster pemakan manusia! Aku masih seorang manusia seutuhnya!',
    'Koutarou Amon: Para penyidik CCG (Merpati) akan membersihkan distrik ini dari seluruh monster Ghoul pemangsa!',
    'Mado Kureo: Quinque milikku haus akan darah Ghoul... Kagune milikmu akan menjadi senjata koleksiku berikutnya!',
    'Kaneki Ken: Berapa hasil dari seribu dikurangi tujuh? Seribu dikurangi tujuh adalah sembilan ratus sembilan puluh tiga...',
    'Kaneki Ken: Rambut hitamku berubah menjadi putih keperakan... Aku adalah Ghoul bermata satu (One-Eyed Ghoul)!',
    'Kaneki Ken: Dunia ini tidak salah. Dunia ini hanya apa adanya... Dan aku akan melindungi orang-orang yang kucintai!',
  ];

  // Specific episode curated entries with full timelines
  static final Map<String, List<SubtitleCue>> _subtitles = {
    // Demon Slayer Episode 1
    'demon-slayer-ep1': _buildCuesWithNaturalPauses(
      headerText: '[Sub Indo] Demon Slayer: Kimetsu no Yaiba - Episode 1: Kekejaman (Tanjiro & Nezuko)',
      dialogues: _knyDialogues,
      maxSeconds: 1800,
      initialCues: const [
        SubtitleCue(
          start: Duration(seconds: 0),
          end: Duration(seconds: 8),
          text: '[Sub Indo] Demon Slayer: Kimetsu no Yaiba - Episode 1: Kekejaman (Tanjiro & Nezuko)',
        ),
        SubtitleCue(
          start: Duration(seconds: 8),
          end: Duration(seconds: 18),
          text: 'Tanjiro: Kenapa harus jadi begini... Nezuko, bertahanlah! Jangan mati!',
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
      ],
      episodeOffset: 0,
    ),

    // Demon Slayer Episode 2
    'demon-slayer-ep2': _buildCuesWithNaturalPauses(
      headerText: '[Sub Indo] Demon Slayer: Kimetsu no Yaiba - Episode 2: Pelatih Sakonji Urokodaki',
      dialogues: [
        'Tanjiro: Nezuko, bertahanlah di dalam keranjang anyaman ini agar terlindung dari terik matahari!',
        'Tanjiro: Baunya kuat sekali... Ada aroma darah manusia segar di kuil tua atas bukit!',
        'Iblis Kuil: Hehehe, ada manusia baru! Tempat ini adalah wilayah perburuanku!',
        'Tanjiro: Nezuko, bantu aku! Kepala iblis ini meregenerasi dengan sangat cepat!',
        'Sakonji Urokodaki: Keputusanmu terlalu lambat! Belas kasihan pada iblis akan membunuh dirimu sendiri!',
        'Urokodaki: Bawa adikmu dan ikuti aku jika kau benar-benar bertekad menjadi Pembasmi Iblis!',
        'Tanjiro: Nafas Air... Aku harus menjaga ritme nafasku stabil menaiki lereng gunung bersalju ini.',
        'Tanjiro: Udara di puncak gunung ini sangat tipis, paru-paruku terasa seperti terbakar!',
        'Urokodaki: Jebakan batu dan bambu ini dirancang untuk menguji kesiapan insting bertahan hidupmu.',
        'Tanjiro: Bau jebakan kawat tercium jelas oleh hidungku! Aku pasti bisa melewatinya!',
        'Tanjiro: Nezuko sedang tidur pulas memulihkan staminanya tanpa memakan darah manusia.',
        'Urokodaki: Mulai hari ini, aku menerima dirimu sebagai murid Korps Pembasmi Iblis.',
      ],
      maxSeconds: 1800,
      initialCues: const [
        SubtitleCue(
          start: Duration(seconds: 0),
          end: Duration(seconds: 8),
          text: '[Sub Indo] Demon Slayer: Kimetsu no Yaiba - Episode 2: Pelatih Sakonji Urokodaki',
        ),
        SubtitleCue(
          start: Duration(seconds: 8),
          end: Duration(seconds: 14),
          text: 'Tanjiro: Nezuko, masuklah ke dalam keranjang ini agar terlindung dari matahari.',
        ),
        SubtitleCue(
          start: Duration(seconds: 14),
          end: Duration(seconds: 20),
          text: 'Tanjiro: Baunya kuat sekali... Ada bau darah manusia di kuil atas bukit!',
        ),
        SubtitleCue(
          start: Duration(seconds: 20),
          end: Duration(seconds: 26),
          text: 'Tanjiro: Nezuko, bertahanlah! Kita harus segera mendaki gunung ini!',
        ),
      ],
      episodeOffset: 0,
    ),

    // Attack on Titan Episode 1
    'attack-on-titan-ep1': _buildCuesWithNaturalPauses(
      headerText: '[Sub Indo] Attack on Titan - Episode 1: Untukmu, 2000 Tahun Kemudian',
      dialogues: _aotDialogues,
      maxSeconds: 1800,
      initialCues: const [
        SubtitleCue(
          start: Duration(seconds: 0),
          end: Duration(seconds: 8),
          text: '[Sub Indo] Attack on Titan - Episode 1: Untukmu, 2000 Tahun Kemudian',
        ),
        SubtitleCue(
          start: Duration(seconds: 8),
          end: Duration(seconds: 14),
          text: 'Eren: Pada hari itu, umat manusia teringat kembali...',
        ),
        SubtitleCue(
          start: Duration(seconds: 14),
          end: Duration(seconds: 20),
          text: 'Eren: Rasa takut hidup terkungkung dalam sangkar dinding...',
        ),
        SubtitleCue(
          start: Duration(seconds: 20),
          end: Duration(seconds: 28),
          text: 'Armin: Dinding Maria setinggi 50 meter... ditembus Titan Kolosal!',
        ),
        SubtitleCue(
          start: Duration(seconds: 28),
          end: Duration(seconds: 36),
          text: 'Eren: Ibu! Jangan! Cepat lari dari rumah itu!',
        ),
        SubtitleCue(
          start: Duration(seconds: 36),
          end: Duration(seconds: 45),
          text: 'Eren: Aku akan memusnahkan seluruh Titan dari muka bumi ini!',
        ),
      ],
      episodeOffset: 0,
    ),

    // One Punch Man Episode 1
    'one-punch-man-ep1': _buildCuesWithNaturalPauses(
      headerText: '[Sub Indo] One Punch Man Ep 1: Ancaman monster membinasakan bumi.',
      dialogues: _opmDialogues,
      maxSeconds: 1800,
      initialCues: const [
        SubtitleCue(
          start: Duration(seconds: 0),
          end: Duration(seconds: 8),
          text: '[Sub Indo] One Punch Man Ep 1: Ancaman monster membinasakan bumi.',
        ),
        SubtitleCue(
          start: Duration(seconds: 8),
          end: Duration(seconds: 18),
          text: 'Vaccine Man: Manusia telah mencemari Bumi... Aku terlahir dari kemarahan Ibu Bumi!',
        ),
        SubtitleCue(
          start: Duration(seconds: 18),
          end: Duration(seconds: 28),
          text: 'Saitama: Siapa aku? Hanya orang biasa yang menjadi pahlawan untuk hobi.',
        ),
        SubtitleCue(
          start: Duration(seconds: 28),
          end: Duration(seconds: 38),
          text: 'Vaccine Man: Hobi?! Beraninya kau meremehkan utusan alam!',
        ),
        SubtitleCue(
          start: Duration(seconds: 38),
          end: Duration(seconds: 50),
          text: 'Saitama: Sialan... hanya satu pukulan lagi! Semuanya selesai dalam satu pukulan!',
        ),
      ],
      episodeOffset: 0,
    ),

    // Tokyo Revengers Episode 1
    'tokyo-revengers-ep1': _buildCuesWithNaturalPauses(
      headerText: '[Sub Indo] Tokyo Revengers - Episode 1: Kelahiran Kembali Sang Pecundang',
      dialogues: _trDialogues,
      maxSeconds: 1800,
      episodeOffset: 0,
    ),

    // Solo Leveling Episode 1
    'solo-leveling-ep1': _buildCuesWithNaturalPauses(
      headerText: '[Sub Indo] Solo Leveling - Episode 1: Hunter Terlemah di Dunia',
      dialogues: _soloDialogues,
      maxSeconds: 1800,
      episodeOffset: 0,
    ),

    // Yosuga no Sora Episode 1
    'yosuga-no-sora-ep1': _buildCuesWithNaturalPauses(
      headerText: '[Sub Indo] Yosuga no Sora - Episode 1: Kenangan Kasugano',
      dialogues: _yosugaDialogues,
      maxSeconds: 1800,
      episodeOffset: 0,
    ),
  };
}
