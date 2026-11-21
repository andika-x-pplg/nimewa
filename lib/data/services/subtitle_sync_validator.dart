import 'anime_subtitle_service.dart';

/// Data structure holding the verification report of subtitle synchronization
/// comparing audio dialogue speech onset with subtitle timestamps.
class SubtitleSyncAuditReport {
  final String animeKey;
  final int episodeNumber;
  final String firstDialogue;
  final Duration videoAudioSpeechOnset;
  final Duration unalignedSubtitleTimestamp;
  final double deltaBeforeCorrectionSeconds;
  final double autoAlignmentShiftSeconds;
  final double manualOffsetSeconds;
  final Duration alignedSubtitleTimestamp;
  final double deltaAfterCorrectionSeconds;
  final bool isSynchronized;
  final String logOutput;

  const SubtitleSyncAuditReport({
    required this.animeKey,
    required this.episodeNumber,
    required this.firstDialogue,
    required this.videoAudioSpeechOnset,
    required this.unalignedSubtitleTimestamp,
    required this.deltaBeforeCorrectionSeconds,
    required this.autoAlignmentShiftSeconds,
    required this.manualOffsetSeconds,
    required this.alignedSubtitleTimestamp,
    required this.deltaAfterCorrectionSeconds,
    required this.isSynchronized,
    required this.logOutput,
  });

  @override
  String toString() => logOutput;
}

/// Diagnostic and validation tool that compares video audio speech onsets
/// against subtitle timestamps, logging time deltas before and after correction.
class SubtitleSyncValidator {
  const SubtitleSyncValidator();

  /// Compares the first spoken dialogue in the authentic video audio against the
  /// unaligned and aligned subtitle cues, reporting the time difference before
  /// and after correction.
  static SubtitleSyncAuditReport verifySync({
    required String animeKey,
    required int episodeNumber,
    double manualOffsetSeconds = 0.0,
    bool printToConsole = true,
  }) {
    final audioSpeechOnset = AnimeSubtitleService.getAudioSpeechOnset(animeKey, episodeNumber);
    final unalignedCues = AnimeSubtitleService.getUnalignedEpisodeCues(animeKey, episodeNumber);
    final alignedCues = AnimeSubtitleService.getAlignedEpisodeCues(animeKey, episodeNumber);

    // Find the first actual character dialogue cue (excluding the intro title banner)
    final unalignedFirstSpeech = _findFirstDialogueCue(unalignedCues);
    final alignedFirstSpeech = _findFirstDialogueCue(alignedCues);

    final unalignedStart = unalignedFirstSpeech?.start ?? Duration.zero;
    final alignedStart = alignedFirstSpeech?.start ?? Duration.zero;
    final dialogueText = unalignedFirstSpeech?.text ?? 'No dialogue';

    // Delta before: audioSpeechOnset - unalignedStart
    // If negative, subtitle appears before the character speaks (too early)
    final deltaBeforeSec = (unalignedStart.inMilliseconds - audioSpeechOnset.inMilliseconds) / 1000.0;
    final alignmentShiftSec = (alignedStart.inMilliseconds - unalignedStart.inMilliseconds) / 1000.0;

    // After correction (aligned cue + manual offset)
    final effectivePostStart = alignedStart + Duration(milliseconds: (manualOffsetSeconds * 1000).round());
    final deltaAfterSec = (effectivePostStart.inMilliseconds - audioSpeechOnset.inMilliseconds) / 1000.0;
    final isSynchronized = deltaAfterSec.abs() < 0.05;

    final buffer = StringBuffer();
    buffer.writeln('[SUB_SYNC_AUDIT] ========================================================');
    buffer.writeln('[SUB_SYNC_AUDIT] ANIME: $animeKey (Episode $episodeNumber)');
    buffer.writeln('[SUB_SYNC_AUDIT] Dialog Pertama: "$dialogueText"');
    buffer.writeln(
        '[SUB_SYNC_AUDIT] Audio Dialog Video (Onset): ${_formatDuration(audioSpeechOnset)} (${(audioSpeechOnset.inMilliseconds / 1000.0).toStringAsFixed(3)}s)');
    buffer.writeln(
        '[SUB_SYNC_AUDIT] Subtitle SEBELUM Koreksi : ${_formatDuration(unalignedStart)} (${(unalignedStart.inMilliseconds / 1000.0).toStringAsFixed(3)}s)');
    buffer.writeln(
        '[SUB_SYNC_AUDIT] Selisih Sebelum Koreksi   : ${deltaBeforeSec >= 0 ? "+" : ""}${deltaBeforeSec.toStringAsFixed(3)}s ${deltaBeforeSec < 0 ? "(Subtitle muncul terlalu cepat/lebih awal!)" : ""}');
    buffer.writeln(
        '[SUB_SYNC_AUDIT] Auto-Alignment Applied   : +${alignmentShiftSec.toStringAsFixed(3)}s (Penyelarasan audio ffsubsync/alass)');
    buffer.writeln(
        '[SUB_SYNC_AUDIT] Offset Manual Pengguna    : ${manualOffsetSeconds >= 0 ? "+" : ""}${manualOffsetSeconds.toStringAsFixed(1)}s');
    buffer.writeln(
        '[SUB_SYNC_AUDIT] Subtitle SESUDAH Koreksi  : ${_formatDuration(effectivePostStart)} (${(effectivePostStart.inMilliseconds / 1000.0).toStringAsFixed(3)}s)');
    buffer.writeln(
        '[SUB_SYNC_AUDIT] Selisih Akhir Sesudah     : ${deltaAfterSec >= 0 ? "+" : ""}${deltaAfterSec.toStringAsFixed(3)}s ${isSynchronized ? "(SINKRON SEMPURNA 0.0s)" : ""}');
    buffer.writeln('[SUB_SYNC_AUDIT] ========================================================');

    final logText = buffer.toString();
    if (printToConsole) {
      // ignore: avoid_print
      print(logText);
    }

    return SubtitleSyncAuditReport(
      animeKey: animeKey,
      episodeNumber: episodeNumber,
      firstDialogue: dialogueText,
      videoAudioSpeechOnset: audioSpeechOnset,
      unalignedSubtitleTimestamp: unalignedStart,
      deltaBeforeCorrectionSeconds: deltaBeforeSec,
      autoAlignmentShiftSeconds: alignmentShiftSec,
      manualOffsetSeconds: manualOffsetSeconds,
      alignedSubtitleTimestamp: effectivePostStart,
      deltaAfterCorrectionSeconds: deltaAfterSec,
      isSynchronized: isSynchronized,
      logOutput: logText,
    );
  }

  static SubtitleCue? _findFirstDialogueCue(List<SubtitleCue> cues) {
    for (final cue in cues) {
      // Skip title banners
      if (!cue.text.startsWith('[Sub Indo]')) {
        return cue;
      }
    }
    // If all start with [Sub Indo] or only 1 cue, return second cue or first cue
    return cues.length > 1 ? cues[1] : cues.firstOrNull;
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

