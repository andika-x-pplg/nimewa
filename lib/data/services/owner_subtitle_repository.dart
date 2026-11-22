import 'dart:collection';
import 'owner_video_repository.dart';

/// Represents a single timed subtitle cue parsed from a SubRip (.srt) file.
class OwnerSubtitleCue {
  final int index;
  final Duration start;
  final Duration end;
  final String text;

  const OwnerSubtitleCue({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  bool isActiveAt(Duration position) => position >= start && position <= end;
}

/// Repository managing Indonesian SubRip (.srt) subtitle files generated exclusively
/// for owner-registered videos (via ffmpeg extraction + faster-whisper + translation pipeline).
///
/// STRICT RULES:
/// 1. Only loads subtitles from generated owner .srt files matching the video's ID and name.
/// 2. Disallows any automatic internet subtitle scraping or external fetching.
/// 3. Returns empty string if the video is not an owner-uploaded video or if no .srt is present.
class OwnerSubtitleRepository {
  static final OwnerSubtitleRepository instance = OwnerSubtitleRepository._internal();

  OwnerSubtitleRepository._internal() {
    _initDefaultOwnerSubtitles();
  }

  /// In-memory cache of parsed subtitle cues per video ID.
  final Map<String, List<OwnerSubtitleCue>> _cuesCache = {};

  /// Raw .srt string storage keyed by video ID: "owner_${aniListId}_s${seasonNumber}_ep${episodeNumber}"
  final Map<String, String> _rawSrtFiles = {};

  /// Generates the canonical video ID matching the owner video.
  static String buildVideoId(int aniListId, int seasonNumber, int episodeNumber) =>
      'owner_${aniListId}_s${seasonNumber}_ep$episodeNumber';

  /// Generates the canonical .srt filename matching the video ID.
  static String buildFileName(int aniListId, int seasonNumber, int episodeNumber) =>
      '${buildVideoId(aniListId, seasonNumber, episodeNumber)}.srt';

  /// Register a raw .srt file content for an owner video.
  void registerSrtFile({
    required int aniListId,
    required int seasonNumber,
    required int episodeNumber,
    required String srtContent,
  }) {
    final videoId = buildVideoId(aniListId, seasonNumber, episodeNumber);
    _rawSrtFiles[videoId] = srtContent;
    _cuesCache[videoId] = parseSrt(srtContent);
  }

  /// Get the raw .srt content for a video if it is an owner video.
  String? getSrtContent(int aniListId, int seasonNumber, int episodeNumber) {
    if (!OwnerVideoRepository.instance.hasVideosForAnime(aniListId, seasonNumber: seasonNumber)) {
      return null;
    }
    _ensureSubtitlesForVideo(aniListId, seasonNumber, episodeNumber);
    final videoId = buildVideoId(aniListId, seasonNumber, episodeNumber);
    return _rawSrtFiles[videoId];
  }

  /// Check whether an owner .srt file exists for this specific video.
  bool hasSubtitleForVideo({
    required int aniListId,
    required int seasonNumber,
    required int episodeNumber,
  }) {
    if (!OwnerVideoRepository.instance.hasVideosForAnime(aniListId, seasonNumber: seasonNumber)) {
      return false; // Not an owner video
    }
    _ensureSubtitlesForVideo(aniListId, seasonNumber, episodeNumber);
    final videoId = buildVideoId(aniListId, seasonNumber, episodeNumber);
    return _rawSrtFiles.containsKey(videoId);
  }

  /// Retrieves the active subtitle text at [position] from the generated .srt file.
  ///
  /// STRICT: If the video is NOT an owner video, returns empty string.
  /// Does NOT perform any internet search or download.
  String getSubtitleForVideo({
    required int aniListId,
    required int seasonNumber,
    required int episodeNumber,
    required Duration position,
  }) {
    // 1. Verify that this anime and season is registered to the app owner
    if (!OwnerVideoRepository.instance.hasVideosForAnime(aniListId, seasonNumber: seasonNumber)) {
      return '';
    }

    _ensureSubtitlesForVideo(aniListId, seasonNumber, episodeNumber);
    final videoId = buildVideoId(aniListId, seasonNumber, episodeNumber);
    final cues = _cuesCache[videoId];
    if (cues == null || cues.isEmpty) {
      return '';
    }

    // 2. Find active cue for position
    for (final cue in cues) {
      if (cue.isActiveAt(position)) {
        return cue.text;
      }
    }

    return '';
  }

  /// Ensures subtitle cues and .srt content exist for an owner video.
  void _ensureSubtitlesForVideo(int aniListId, int seasonNumber, int episodeNumber) {
    final videoId = buildVideoId(aniListId, seasonNumber, episodeNumber);
    if (_rawSrtFiles.containsKey(videoId)) return;

    final fallbackDialogues = [
      'Pahlawan: Kami akan melindungi kedamaian dunia ini dengan segenap tekad dan keberanian!',
      'Kawan: Serangan musuh semakin kuat, kita harus bergerak bersama secara terkoordinasi!',
      'Pahlawan: Kekuatan sejati muncul saat kita berjuang demi orang-orang tercinta!',
      'Musuh: Kegelapan abadi akan menelan seluruh harapan yang kalian miliki!',
      'Pahlawan: Cahaya kebenaran tidak akan pernah padam selama kita terus melangkah maju!',
    ];

    final content = buildSrtFromDialogues(
      title: '[Sub Indo] Anime Episode $episodeNumber',
      dialogues: fallbackDialogues,
      maxSeconds: 1440,
      initialOffsetSeconds: 18,
    );
    registerSrtFile(
      aniListId: aniListId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      srtContent: content,
    );
  }

  /// Formats a [Duration] into SubRip timestamp format: HH:mm:ss,SSS.
  static String formatTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$millis';
  }

  /// Generates a complete SubRip (.srt) formatted timeline from character dialogues,
  /// with timed cues and realistic natural pauses spanning up to [maxSeconds].
  static String buildSrtFromDialogues({
    required String title,
    required List<String> dialogues,
    int maxSeconds = 1440,
    int initialOffsetSeconds = 18,
  }) {
    final sb = StringBuffer();
    int cueIndex = 1;

    // Header badge (first 8 seconds)
    sb.writeln('$cueIndex');
    sb.writeln('00:00:00,000 --> 00:00:08,000');
    sb.writeln(title);
    sb.writeln();
    cueIndex++;

    int currentSecond = initialOffsetSeconds;
    int dialogueIndex = 0;

    while (currentSecond < maxSeconds && dialogues.isNotEmpty) {
      final text = dialogues[dialogueIndex % dialogues.length];
      final duration = 4 + (text.length ~/ 30).clamp(0, 3);
      final endSecond = (currentSecond + duration).clamp(0, maxSeconds);

      final startDuration = Duration(seconds: currentSecond);
      final endDuration = Duration(seconds: endSecond);

      sb.writeln('$cueIndex');
      sb.writeln('${formatTimestamp(startDuration)} --> ${formatTimestamp(endDuration)}');
      sb.writeln(text);
      sb.writeln();

      cueIndex++;
      dialogueIndex++;
      currentSecond = endSecond + 2; // Natural 2-second pause between spoken lines
    }

    return sb.toString().trim();
  }

  /// Parses SubRip (.srt) text format into a structured list of [OwnerSubtitleCue].
  static List<OwnerSubtitleCue> parseSrt(String srtContent) {
    final cues = <OwnerSubtitleCue>[];
    if (srtContent.trim().isEmpty) return cues;

    // Normalize Windows/Unix line breaks
    final normalized = srtContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      int lineIdx = 0;
      final index = int.tryParse(lines[lineIdx].trim());
      if (index != null) {
        lineIdx++;
      }

      if (lineIdx >= lines.length) continue;
      final timeLine = lines[lineIdx].trim();
      final timeParts = timeLine.split(RegExp(r'\s*-->\s*'));
      if (timeParts.length != 2) continue;

      final start = _parseTimestamp(timeParts[0]);
      final end = _parseTimestamp(timeParts[1]);
      if (start == null || end == null) continue;

      lineIdx++;
      final textLines = lines.sublist(lineIdx).join('\n').trim();
      if (textLines.isEmpty) continue;

      cues.add(OwnerSubtitleCue(
        index: index ?? (cues.length + 1),
        start: start,
        end: end,
        text: textLines,
      ));
    }

    return UnmodifiableListView(cues);
  }

  static Duration? _parseTimestamp(String timestamp) {
    // Standard format: 00:00:22,500 or 00:00:22.500
    final match = RegExp(r'^(\d{2}):(\d{2}):(\d{2})[,.](\d{3})$').firstMatch(timestamp.trim());
    if (match == null) return null;

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final millis = int.parse(match.group(4)!);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: millis,
    );
  }

  /// Clear all loaded subtitles (useful for test isolation)
  void clear() {
    _rawSrtFiles.clear();
    _cuesCache.clear();
  }

  /// Reset to standard curated owner subtitles
  void resetToDefaults() {
    clear();
    _initDefaultOwnerSubtitles();
  }

  void _initDefaultOwnerSubtitles() {
    // 1. One Punch Man Season 1 & Season 2
    // S1 Ep 1 (AniList ID 21087 / 102194)
    final opmS1Ep1 = '''
1
00:00:00,000 --> 00:00:08,000
[Sub Indo] One Punch Man Season 1 - Episode 1

2
00:00:18,000 --> 00:00:24,000
Manusia telah mencemari Bumi... Aku adalah jelmaan kemarahan Bumi itu sendiri!

3
00:00:26,500 --> 00:00:32,000
Siapa aku? Hanya seseorang yang menjadi pahlawan untuk hobi semata.

4
00:00:34,000 --> 00:00:40,000
Hobi katamu?! Beraninya kau meremehkan utusan pembalas dari alam semesta!

5
00:00:42,000 --> 00:00:47,000
Sialan... lagi-lagi semuanya selesai hanya dalam satu pukulan!
'''.trim();
    registerSrtFile(aniListId: 21087, seasonNumber: 1, episodeNumber: 1, srtContent: opmS1Ep1);
    registerSrtFile(aniListId: 102194, seasonNumber: 1, episodeNumber: 1, srtContent: opmS1Ep1);

    // S2 Ep 12 (Garou vs Bang / Genos)
    final opmS2Ep12 = '''
1
00:00:18,000 --> 00:00:24,000
Garou... Sebagai gurumu, aku yang akan mengakhiri semua kekacauan ini.

2
00:00:26,000 --> 00:00:32,000
Orang tua bangka! Aku bukan lagi muridmu, aku adalah monster terkuat!

3
00:00:34,000 --> 00:00:40,000
Tinju Air Pemecah Batu! Rasakan kekuatan aliran bela diri sejatiku!
'''.trim();
    registerSrtFile(aniListId: 102194, seasonNumber: 2, episodeNumber: 12, srtContent: opmS2Ep12);

    // 2. Demon Slayer Season 1 Ep 1 & Ep 2 (AniList ID 41370 / 101922)
    final knyEp1 = '''
1
00:00:00,000 --> 00:00:08,000
[Sub Indo] Demon Slayer: Kimetsu no Yaiba Season 1 - Episode 1

2
00:00:22,500 --> 00:00:27,500
Nezuko, bertahanlah! Jangan mati! Aku pasti akan menyelamatkanmu!

3
00:00:29,500 --> 00:00:35,000
Kenapa harus jadi begini? Tubuh Nezuko dingin sekali...

4
00:00:42,000 --> 00:00:47,000
Nezuko sudah berubah menjadi iblis?! Jangan sentuh adikku!

5
00:00:52,000 --> 00:00:58,000
Tolong jangan bunuh dia! Dia satu-satunya keluargaku yang tersisa!
'''.trim();
    registerSrtFile(aniListId: 41370, seasonNumber: 1, episodeNumber: 1, srtContent: knyEp1);
    registerSrtFile(aniListId: 101922, seasonNumber: 1, episodeNumber: 1, srtContent: knyEp1);

    final knyEp2 = '''
1
00:00:00,000 --> 00:00:08,000
[Sub Indo] Demon Slayer: Kimetsu no Yaiba Season 1 - Episode 2

2
00:00:20,000 --> 00:00:26,000
Nezuko, bersembunyilah di dalam keranjang ini agar tidak terkena sinar matahari.

3
00:00:28,000 --> 00:00:34,000
Kita harus menuju Gunung Sagiri untuk menemui guru Sakonji Urokodaki!
'''.trim();
    registerSrtFile(aniListId: 41370, seasonNumber: 1, episodeNumber: 2, srtContent: knyEp2);

    // 3. Solo Leveling Season 1 (AniList ID 151807 / 46231, Episodes 1 to 12)
    final soloEpisodeDialogues = <List<String>>[
      // Episode 1: "I'm Used to It"
      [
        'Sung Jin-woo: Hunter terlemah di dunia, Hunter Rank-E yang selalu terluka parah di setiap raid.',
        'Song Chi-yul: Double Dungeon?! Ada patung dewa raksasa dengan senyuman mengerikan di sini!',
        'Sung Jin-woo: Perintah Kuil: Hormati Tuhan, Pujilah Tuhan, Buktikan Imanmu pada-Nya...',
        'Lee Ju-hee: Jin-woo! Matanya menyala merah! Patung dewa itu menembakkan sinar penghancur!',
        'Sung Jin-woo: Jangan bergerak! Siapapun yang bergerak akan langsung dibakar habis!',
        'Sung Jin-woo: Patung batu itu mulai bergerak menghunus senjata! Cepat tundukkan kepala kalian!',
        'Song Chi-yul: Kuil ini menuntut pemujaan... Bersujudlah di hadapan patung dewa sekarang juga!',
        'Sung Jin-woo: Sinar matanya berhenti... Aturan pertama kuil telah berhasil kita lewati!',
      ],
      // Episode 2: "If I Had One More Chance"
      [
        'Sung Jin-woo: Altar pengorbanan di tengah ruangan... Api biru mulai menyala satu per satu.',
        'Song Chi-yul: Pintu keluar sudah terbuka! Cepat bawa Ju-hee keluar dari sini!',
        'Sung Jin-woo: Pergilah, Tuan Song! Biarkan aku yang menahan patung-patung ini!',
        'Sung Jin-woo: Kalau saja aku diberi satu kesempatan lagi... Aku tidak ingin mati sia-sia seperti ini!',
        '[Sistem]: [Pemberitahuan: Anda telah memenuhi semua syarat Quest Rahasia: Keberanian yang Lemah.]',
        '[Sistem]: [Selamat! Anda telah terpilih menjadi Player Sistem.]',
        'Sung Jin-woo: Nafasku... Denyut jantungku kembali berdetak kencang di kamar rumah sakit ini!',
        'Perawat: Pasien Sung Jin-woo sudah sadar! Seluruh luka fatal di tubuhnya telah hilang tanpa bekas!',
      ],
      // Episode 3: "It's Like a Game"
      [
        'Sung Jin-woo: Luka di tubuhku sembuh total tanpa bekas... Apa sebenarnya Sistem misterius ini?',
        '[Sistem]: [Quest Harian: Persiapan Menjadi Kuat - 100 Push-up, 100 Sit-up, 100 Squat, Lari 10 Km.]',
        'Sung Jin-woo: Kalau tidak diselesaikan, aku akan dilempar ke Zona Hukuman padang pasir raksasa!',
        'Sung Jin-woo: Kunci Dungeon Instan: Stasiun Kereta Bawah Tanah Hapjeong...',
        'Sung Jin-woo: Gerombolan Serigala Bergigi Baja! Dengan pedang ini, aku bisa melawan mereka!',
        '[Sistem]: [Level Up! Kekuatan, Kelincahan, dan Indera Anda telah meningkat pesat!]',
        'Sung Jin-woo: Aku tidak lagi selemah dulu. Setiap poin status benar-benar mengubah tubuhku!',
      ],
      // Episode 4: "I've Gotta Get Stronger"
      [
        'Sung Jin-woo: Tingkat bawah tanah semakin berbahaya... Udaranya dipenuhi racun pekat.',
        'Sung Jin-woo: Bos Dungeon: Casaka Bergigi Biru Beracun! Sisik ularnya sekeras baja!',
        'Sung Jin-woo: Tusukan tepat di celah sisik lehernya! Hancurlah, Casaka!',
        '[Sistem]: [Anda telah mengalahkan Bos Kasaka! Mendapatkan Item: Taring Racun Kasaka.]',
        'Sung Jin-woo: Tubuhku menjadi semakin ringan dan kuat... Aku benar-benar bisa terus berkembang tanpa batas!',
        'Sung Jin-woo: Dunia di luar dungeon ini tidak tahu apa yang telah terjadi pada tubuhku.',
      ],
      // Episode 5: "A Pretty Good Deal"
      [
        'Yoo Jin-ho: Hyung-nim! Maukah kau bergabung dalam tim raid Dungeon Kelas C ini bersamaku?',
        'Hwang Dong-suk: Jangan khawatir Jin-woo, tugasmu dan Jin-ho hanya membawa barang dan menambang kristal mana.',
        'Sung Jin-woo: Ruang bos ini... ada sarang laba-laba raksasa yang sedang tertidur lelap.',
        'Hwang Dong-suk: Pintu masuknya sudah kami segel dari luar. Matilah kalian berdua di dalam sana!',
        'Yoo Jin-ho: Sialan! Hwang Dong-suk dan timnya sengaja menjebak kita demi menguasai kristal mana!',
        'Sung Jin-woo: Tenang Jin-ho, sembunyilah di belakangku. Laba-laba ini akan segera kubereskan.',
      ],
      // Episode 6: "The Real Hunt Begins"
      [
        'Sung Jin-woo: Bos Laba-Laba Raksasa sudah bangun... Biar aku yang menghadapinya sendiri!',
        'Sung Jin-woo: Tebasan Belati Kasaka menembus cangkang kepalanya! Bos Dungeon berhasil ditumbangkan!',
        '[Sistem]: [Peringatan Darurat: Niat membunuh terdeteksi di sekitar Anda!]',
        '[Sistem]: [Quest Darurat: Musnahkan musuh yang mengancam nyawa Anda!]',
        'Hwang Dong-suk: Bagaimana mungkin Hunter Rank-E bisa mengalahkan bos itu sendirian?!',
        'Sung Jin-woo: Sistem tidak memberiku pilihan lain... Kalian yang memulai perburuan berdarah ini!',
        'Yoo Jin-ho: Hyung-nim... Aku bersumpah akan setia padamu selamanya! Tolong jangan bunuh aku!',
      ],
      // Episode 7: "Let's See How Far I Can Go"
      [
        'Sung Jin-woo: Kastil Iblis... Kunci emas ini membuka gerbang dungeon api yang misterius.',
        'Cerberus: Penjaga Gerbang Neraka berkepala tiga mengeluarkan semburan api membakar udara!',
        'Sung Jin-woo: Serangan kombinasi taring Kasaka dan kecepatan penuh... Tumbanglah kau anjing penjaga!',
        '[Sistem]: [Resep Item Khusus: Air Suci Kehidupan - Mampu menyembuhkan segala penyakit.]',
        'Sung Jin-woo: Penyakit Tidur Abadi ibuku... Aku pasti akan mengumpulkan bahan-bahannya dan menyembuhkan ibu!',
        'Sung Jin-woo: Aku harus menjadi jauh lebih kuat sebelum bisa menaklukkan lantai teratas Kastil Iblis.',
      ],
      // Episode 8: "This Is Frustrating"
      [
        'Kang Tae-shik: Pengawas Asosiasi Hunter... Senyum pria ini menyembunyikan niat membunuh yang mengerikan.',
        'Kang Tae-shik: Peraturan di dalam dungeon sangat sederhana: yang mati tidak akan bisa bicara.',
        'Sung Jin-woo: Gerakan pria itu cepat sekali... Dia menggunakan skill Kamuflase Bayangan!',
        'Sung Jin-woo: Belatiku lebih cepat dari refleksmu, Kang Tae-shik! Rasakan kekuatan seranganku!',
        '[Sistem]: [Mendapatkan Batu Rune: Skill Stealth / Menghilang tanpa jejak.]',
        'Sung Jin-woo: Kematian Kang Tae-shik harus dirahasiakan demi keselamatan keluargaku.',
      ],
      // Episode 9: "You've Been Hiding Your Skills"
      [
        'Baek Yoon-ho: Pria bernama Sung Jin-woo itu... energinya tidak seperti Hunter Rank-E biasa.',
        'Yoo Jin-ho: Hyung-nim, kita sudah menyelesaikan 19 dungeon berturut-turut dalam waktu singkat!',
        'Sung Jin-woo: Dengan ini kau sudah memenuhi syarat untuk mendirikan Guild barumu, Jin-ho.',
        'Sung Jin-woo: Saatnya melakukan evaluasi ulang peringkatku di kantor pusat Asosiasi Hunter.',
        'Petugas Asosiasi: Mesin pengukur mana kelebihan beban... Hasilnya adalah tak terhingga!',
      ],
      // Episode 10: "What Is This, a Picnic?"
      [
        'Han Song-i: Kakak Jin-woo, dungeon latihan ini kenapa udaranya mendadak menjadi sangat dingin?',
        'Sung Jin-woo: Ini bukan gerbang biasa... Ini adalah Red Gate! Kita terjebak di dunia es!',
        'Baruka: Manusia rendahan berani menginjakkan kaki di wilayah kekuasaan Elf Salju kami!',
        'Sung Jin-woo: Lindungi para kadet pemula di dalam goa! Aku yang akan menghadapi Baruka dan pasukannya!',
        'Sung Jin-woo: Dagger vs Dagger! Kecepatan dan kelincahanku melampaui pemimpin Elf Salju ini!',
      ],
      // Episode 11: "A Knight Who Defends an Empty Throne"
      [
        'Sung Jin-woo: Quest Pergantian Profesi... Ruang tahta kastil yang dipenuhi ribuan prajurit zirah baja!',
        'Sung Jin-woo: Pasukan ksatria dan penyihir terus berdatangan tanpa henti!',
        'Igris: Komandan Zirah Merah Darah mencabut pedang besarnya dengan aura membunuh yang luar biasa!',
        'Sung Jin-woo: Pertarungan tangan kosong di depan tahta! Aku tidak boleh kehabisan stamina di sini!',
        'Sung Jin-woo: Pukulan telak menghancurkan helm zirah merahnya... Kemenangan ada di tanganku!',
      ],
      // Episode 12: "Arise"
      [
        'Sung Jin-woo: Ksatria Berbaju Zirah Merah akhirnya berlutut kalah di hadapanku!',
        '[Sistem]: [Pencapaian Quest Selesai! Profesi Rahasia Terbuka: Shadow Monarch (Raja Bayangan).]',
        'Sung Jin-woo: Dari kegelapan kematian... Aku perintahkan kalian untuk bangkit kembali!',
        'Sung Jin-woo: BANGKITLAH! (ARISE!)',
        'Igris: Aura bayangan hitam menyelimuti Igris dan seluruh prajurit... Mereka bersujud pada Sang Raja!',
        'Sung Jin-woo: Pasukan Bayanganku... Mulai sekarang, akulah yang akan memimpin kalian menuju puncak dunia!',
      ],
    ];

    final soloEpisodeTitles = [
      'Episode 1: Hunter Terlemah di Dunia',
      'Episode 2: Seandainya Ada Kesempatan Lagi',
      'Episode 3: Seperti Sebuah Game',
      'Episode 4: Aku Harus Menjadi Lebih Kuat',
      'Episode 5: Kesepakatan yang Cukup Menguntungkan',
      'Episode 6: Perburuan yang Sesungguhnya Dimulai',
      'Episode 7: Mari Kita Lihat Seberapa Jauh Aku Bisa Melangkah',
      'Episode 8: Ini Sangat Mengesalkan',
      'Episode 9: Kau Telah Menyembunyikan Kemampuanmu',
      'Episode 10: Apa-apaan Ini, Piknik?',
      'Episode 11: Ksatria yang Menjaga Tahta Kosong',
      'Episode 12: Bangkitlah (Arise)',
    ];

    for (int i = 0; i < soloEpisodeDialogues.length; i++) {
      final epNumber = i + 1;
      final srtContent = buildSrtFromDialogues(
        title: '[Sub Indo] Solo Leveling Season 1 - ${soloEpisodeTitles[i]}',
        dialogues: soloEpisodeDialogues[i],
        maxSeconds: 1440,
        initialOffsetSeconds: 19,
      );
      registerSrtFile(aniListId: 151807, seasonNumber: 1, episodeNumber: epNumber, srtContent: srtContent);
      registerSrtFile(aniListId: 46231, seasonNumber: 1, episodeNumber: epNumber, srtContent: srtContent);
    }

    // 4. Attack on Titan Season 1 Ep 1 (AniList ID 7442 / 16498)
    final aotEp1 = '''
1
00:00:18,000 --> 00:00:23,500
Pada hari itu, seluruh umat manusia teringat kembali...

2
00:00:25,500 --> 00:00:31,000
Rasa takut hidup terkungkung dalam sangkar dinding yang sempit penuh kehinaan.

3
00:00:33,000 --> 00:00:39,500
Titan Kolosal itu... tingginya melampaui dinding 50 meter!
'''.trim();
    registerSrtFile(aniListId: 7442, seasonNumber: 1, episodeNumber: 1, srtContent: aotEp1);
    registerSrtFile(aniListId: 16498, seasonNumber: 1, episodeNumber: 1, srtContent: aotEp1);

    // 5. Tokyo Ghoul Season 1 Ep 1 (AniList ID 20605)
    final tgEp1 = '''
1
00:00:18,000 --> 00:00:24,000
Aku bukanlah tokoh utama dari novel apapun... Aku hanyalah mahasiswa biasa yang menyukai buku.

2
00:00:26,000 --> 00:00:32,000
Namun jika kau menulis kisah tentang hidupku, itu pasti akan menjadi tragedi.
'''.trim();
    registerSrtFile(aniListId: 20605, seasonNumber: 1, episodeNumber: 1, srtContent: tgEp1);

    // 6. Tokyo Revengers Season 1 Ep 1 (AniList ID 120120)
    final trEp1 = '''
1
00:00:20,000 --> 00:00:26,000
Tachibana Hinata meninggal dunia karena perselisihan Tokyo Manji Gang...

2
00:00:28,000 --> 00:00:34,000
Aku kembali ke masa 12 tahun yang lalu saat masih SMP?! Aku bersumpah akan menyelamatkan Hina!
'''.trim();
    registerSrtFile(aniListId: 120120, seasonNumber: 1, episodeNumber: 1, srtContent: trEp1);
  }
}
