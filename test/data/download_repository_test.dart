import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/download_item.dart';
import 'package:nimeva/data/services/download_repository.dart';
import 'package:nimeva/presentation/screens/downloads_screen.dart';

void main() {
  group('DownloadRepository & DownloadsScreen', () {
    test('supports pause, resume, and removeDownload', () async {
      final repo = DownloadRepository(disablePersistence: true);
      await repo.init();

      await repo.restoreItem(
        DownloadItem(
          id: 'frieren_ep_1',
          animeId: '154587',
          title: 'Frieren',
          episodeNumber: 1,
          streamUrl: 'https://example.com/ep1.mp4',
          filePath: '/tmp/frieren_ep1.mp4',
          receivedBytes: 500,
          totalBytes: 1000,
          status: DownloadStatus.downloading,
          updatedAt: DateTime(2026, 11, 26),
        ),
      );

      await repo.pauseDownload('frieren_ep_1');
      expect(repo.items.first.status, equals(DownloadStatus.paused));

      await repo.removeDownload('frieren_ep_1');
      expect(repo.items, isEmpty);
    });

    testWidgets('DownloadsScreen toggles pause/resume and deletes on long press', (tester) async {
      final repo = DownloadRepository(disablePersistence: true);
      await repo.init();
      await repo.restoreItem(
        DownloadItem(
          id: 'frieren_ep_1',
          animeId: '154587',
          title: 'Frieren',
          episodeNumber: 1,
          streamUrl: 'https://example.com/ep1.mp4',
          filePath: '/tmp/frieren_ep1.mp4',
          receivedBytes: 500,
          totalBytes: 1000,
          status: DownloadStatus.downloading,
          updatedAt: DateTime(2026, 11, 26),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: DownloadsScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frieren · Ep 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('download_toggle_frieren_ep_1')));
      await tester.pumpAndSettle();
      expect(repo.items.first.status, equals(DownloadStatus.paused));

      await tester.longPress(find.text('Frieren · Ep 1'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Download'), findsOneWidget);
      await tester.tap(find.text('Hapus Download'));
      await tester.pumpAndSettle();
      expect(repo.items, isEmpty);
    });
  });
}

