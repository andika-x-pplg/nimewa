import 'package:flutter/foundation.dart';

/// Represents a single audit record of video stream matching.
class StreamAuditLogEntry {
  final DateTime timestamp;
  final int? aniListId;
  final String searchedTitle;
  final String candidateTitle;
  final String candidateSource;
  final bool isAccepted;
  final String reason;

  const StreamAuditLogEntry({
    required this.timestamp,
    this.aniListId,
    required this.searchedTitle,
    required this.candidateTitle,
    required this.candidateSource,
    required this.isAccepted,
    required this.reason,
  });

  @override
  String toString() =>
      '[STREAM_AUDIT] ${timestamp.toIso8601String()} aniListId=$aniListId '
      'searched="$searchedTitle" candidate="$candidateTitle" '
      'status=${isAccepted ? "ACCEPTED" : "REJECTED"} reason="$reason"';
}

/// In-memory structured logger that records all video stream candidate checks.
/// Allows debugging why a candidate was accepted or rejected.
class StreamAuditLogger {
  static final StreamAuditLogger instance = StreamAuditLogger._();

  StreamAuditLogger._();

  static const int maxLogs = 200;
  final List<StreamAuditLogEntry> _logs = [];

  List<StreamAuditLogEntry> get recentLogs => List.unmodifiable(_logs);

  void log({
    required String searchedTitle,
    required String candidateTitle,
    required String candidateSource,
    required bool isAccepted,
    required String reason,
    int? aniListId,
  }) {
    final entry = StreamAuditLogEntry(
      timestamp: DateTime.now(),
      aniListId: aniListId,
      searchedTitle: searchedTitle,
      candidateTitle: candidateTitle,
      candidateSource: candidateSource,
      isAccepted: isAccepted,
      reason: reason,
    );

    if (_logs.length >= maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(entry);

    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  void clear() {
    _logs.clear();
  }
}

