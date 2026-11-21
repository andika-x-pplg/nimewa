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

    // 3. Solo Leveling Season 1 Ep 1 (AniList ID 151807 / 46231)
    final soloEp1 = '''
1
00:00:00,000 --> 00:00:08,000
[Sub Indo] Solo Leveling Season 1 - Episode 1

2
00:00:19,500 --> 00:00:25,500
Hunter terlemah di dunia... Hunter Rank-E yang selalu terluka parah di setiap raid.

3
00:00:28,000 --> 00:00:34,500
Double Dungeon?! Ada patung dewa raksasa dengan senyuman mengerikan di sini!

4
00:00:37,000 --> 00:00:43,000
Jangan bergerak! Patung dewa itu menembakkan sinar penghancur mematikan!

5
00:00:45,500 --> 00:00:51,500
Ini adalah... Jendela Sistem? Apakah hanya aku satu-satunya yang bisa naik level?!
'''.trim();
    registerSrtFile(aniListId: 151807, seasonNumber: 1, episodeNumber: 1, srtContent: soloEp1);
    registerSrtFile(aniListId: 46231, seasonNumber: 1, episodeNumber: 1, srtContent: soloEp1);

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
