import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/presentation/screens/anime_detail_screen.dart';
import 'package:nimeva/presentation/screens/anime_watch_screen.dart';
import '../../helpers/fake_video_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });
  group('AnimeDetailScreen Tests', () {
    testWidgets('renders header, metadata, synopsis, and episode list', (tester) async {
      EpisodeItem? selectedEpisode;

      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AnimeDetailScreen(
            animeId: 'solo-leveling-s2',
            onEpisodeTap: (ep) => selectedEpisode = ep,
          ),
        ),
      );

      // Initial pump & settle for async service
      await tester.pumpAndSettle();

      // Verify title and metadata
      expect(find.textContaining('Solo Leveling'), findsWidgets);
      expect(find.text('Mulai Nonton'), findsOneWidget);
      expect(find.text('Sinopsis'), findsOneWidget);
      expect(find.text('Daftar Episode'), findsOneWidget);

      // Tap "Mulai Nonton" button which triggers first episode
      await tester.tap(find.text('Mulai Nonton'));
      await tester.pumpAndSettle();

      expect(selectedEpisode, isNotNull);
      expect(selectedEpisode?.episodeNumber, equals(1));
    });

    testWidgets('tapping Mulai Nonton pushes AnimeWatchScreen with episode 1', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailScreen(
            animeId: 'solo-leveling-s2',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mulai Nonton'), findsOneWidget);
      await tester.tap(find.text('Mulai Nonton'));
      await tester.pumpAndSettle();

      // Verify AnimeWatchScreen is pushed and displaying Ep 1
      expect(find.byType(AnimeWatchScreen), findsOneWidget);
      expect(find.textContaining('Ep 1'), findsWidgets);
    });

    testWidgets('tapping an episode item in list pushes AnimeWatchScreen with selected episode', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailScreen(
            animeId: 'solo-leveling-s2',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to find episode 2
      final ep2Finder = find.textContaining('Episode 2');
      await tester.ensureVisible(ep2Finder);
      await tester.tap(ep2Finder);
      await tester.pumpAndSettle();

      // Verify AnimeWatchScreen is pushed and displaying Ep 2
      expect(find.byType(AnimeWatchScreen), findsOneWidget);
      expect(find.textContaining('Ep 2'), findsWidgets);
    });

    testWidgets('renders franchise relations carousel when relations are present', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailScreen(
            animeId: 'tokyo-revengers-s3',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Relasi Franchise'), findsOneWidget);
      expect(find.text('Prequel / Sequel'), findsOneWidget);
      expect(find.text('PREQUEL'), findsWidgets);
      expect(find.text('SEQUEL'), findsWidgets);
    });

    testWidgets('displays Video Belum Tersedia and hides unplayable episodes when hasVideoAvailable is false', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailScreen(
            animeId: 'tokyo-revengers-s4',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Video Belum Tersedia'), findsOneWidget);
      expect(find.text('Episode video belum tersedia untuk judul ini.'), findsOneWidget);
      expect(find.text('Tidak Tersedia'), findsOneWidget);
    });
  });
}
