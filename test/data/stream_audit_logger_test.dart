import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/stream_audit_logger.dart';

void main() {
  group('StreamAuditLogger Tests', () {
    setUp(() {
      StreamAuditLogger.instance.clear();
    });

    test('logs accepted stream resolution with details', () {
      StreamAuditLogger.instance.log(
        searchedTitle: 'Tokyo Revengers Season 1',
        candidateTitle: 'Tokyo Revengers Episode 1 Sub Indo',
        candidateSource: 'https://archive.org/download/tokyo-revengers/ep1.mp4',
        isAccepted: true,
        reason: 'Episode resmi terverifikasi',
        aniListId: 120120,
      );

      final logs = StreamAuditLogger.instance.recentLogs;
      expect(logs.length, equals(1));
      expect(logs.first.searchedTitle, equals('Tokyo Revengers Season 1'));
      expect(logs.first.candidateTitle, equals('Tokyo Revengers Episode 1 Sub Indo'));
      expect(logs.first.isAccepted, isTrue);
      expect(logs.first.reason, equals('Episode resmi terverifikasi'));
      expect(logs.first.aniListId, equals(120120));
      expect(logs.first.timestamp, isNotNull);
    });

    test('logs rejected stream resolution with specific rejection reason', () {
      StreamAuditLogger.instance.log(
        searchedTitle: 'Demon Slayer',
        candidateTitle: 'Demon Slayer Ep 1 Reaction Video',
        candidateSource: 'https://archive.org/download/reaction.mp4',
        isAccepted: false,
        reason: 'Judul mengandung kata terlarang: reaction',
        aniListId: 101922,
      );

      final logs = StreamAuditLogger.instance.recentLogs;
      expect(logs.length, equals(1));
      expect(logs.first.isAccepted, isFalse);
      expect(logs.first.reason, contains('reaction'));
    });

    test('maintains maximum history limit without memory leak', () {
      for (int i = 0; i < 250; i++) {
        StreamAuditLogger.instance.log(
          searchedTitle: 'Anime $i',
          candidateTitle: 'Candidate $i',
          candidateSource: 'https://archive.org/$i.mp4',
          isAccepted: true,
          reason: 'OK',
        );
      }

      final logs = StreamAuditLogger.instance.recentLogs;
      expect(logs.length, lessThanOrEqualTo(200));
      expect(logs.last.searchedTitle, equals('Anime 249'));
    });
  });
}
