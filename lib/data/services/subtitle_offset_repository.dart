/// Repository for persisting and retrieving user-defined subtitle sync offsets
/// (in seconds, with 0.1s precision) per anime video/episode.
class SubtitleOffsetRepository {
  SubtitleOffsetRepository._();
  static final SubtitleOffsetRepository instance = SubtitleOffsetRepository._();

  final Map<String, double> _offsets = <String, double>{};

  /// Build a consistent key for an anime episode.
  static String buildKey(String animeId, int episodeNumber) {
    return '${animeId.toLowerCase().trim()}_ep$episodeNumber';
  }

  /// Get stored subtitle offset for a specific video key in seconds.
  /// Defaults to 0.0s (no manual shift).
  double getOffset(String key) {
    return _offsets[key] ?? 0.0;
  }

  /// Store subtitle offset in seconds for a specific video key.
  void setOffset(String key, double offsetSeconds) {
    final rounded = double.parse(offsetSeconds.toStringAsFixed(1));
    _offsets[key] = rounded;
  }

  /// Adjust existing offset by a delta in seconds (e.g. +0.1 or -0.1).
  double adjustOffset(String key, double deltaSeconds) {
    final current = getOffset(key);
    final updated = double.parse((current + deltaSeconds).toStringAsFixed(1));
    _offsets[key] = updated;
    return updated;
  }

  /// Reset offset for a key back to 0.0s.
  void resetOffset(String key) {
    _offsets.remove(key);
  }

  /// Clear all stored offsets (useful for testing).
  void clear() {
    _offsets.clear();
  }
}

