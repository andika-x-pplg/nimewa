import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/anime_detail.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/presentation/screens/anime_watch_screen.dart';
import '../../helpers/fake_video_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });
  final testEpisodes = [
    const EpisodeItem(
      id: 'solo-eps-1',
      episodeNumber: 1,
      title: 'Episode 1 - Aku Terbiasa',
      releaseDate: '2025-01-07',
      streamUrl: 'https://sample.com/1.mp4',
    ),
    const EpisodeItem(
      id: 'solo-eps-2',
      episodeNumber: 2,
      title: 'Episode 2 - Jika Punya Kesempatan Lain',
      releaseDate: '2025-01-14',
      streamUrl: 'https://sample.com/2.mp4',
    ),
    const EpisodeItem(
      id: 'solo-eps-3',
      episodeNumber: 3,
      title: 'Episode 3 - Seperti Game',
      releaseDate: '2025-01-21',
      streamUrl: 'https://sample.com/3.mp4',
    ),
  ];

  final testAnime = AnimeDetail(
    id: 'solo-leveling',
    title: 'Solo Leveling',
    japaneseTitle: '俺だけレベルアップな件',
    rating: 8.9,
    releaseYear: 2025,
    genres: const ['Action', 'Fantasy'],
    synopsis: 'Sung Jinwoo menjadi Hunter terkuat.',
    posterUrl: 'https://images.unsplash.com/poster.jpg',
    backdropUrl: 'https://images.unsplash.com/backdrop.jpg',
    status: 'Ongoing',
    studio: 'A-1 Pictures',
    totalEpisodes: 3,
    episodes: testEpisodes,
  );

  Widget createWatchScreen({EpisodeItem? initialEpisode}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: AnimeWatchScreen(
        anime: testAnime,
        initialEpisode: initialEpisode ?? testEpisodes.first,
      ),
    );
  }

  group('AnimeWatchScreen Tests', () {
    testWidgets('renders video player container, top bar, controls, and episode list', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Top bar info
      expect(find.textContaining('Solo Leveling · Ep 1'), findsOneWidget);
      expect(find.text('1080p'), findsOneWidget);
      expect(find.byKey(const Key('video_back_button')), findsOneWidget);

      // Playback controls
      expect(find.byKey(const Key('video_play_pause_button')), findsOneWidget);
      expect(find.byKey(const Key('video_replay_10')), findsOneWidget);
      expect(find.byKey(const Key('video_forward_10')), findsOneWidget);
      expect(find.byKey(const Key('video_progress_slider')), findsOneWidget);
      expect(find.textContaining('00:00 / 24:00'), findsOneWidget);

      // Server options
      expect(find.text('Pilih Server'), findsOneWidget);
      expect(find.text('Server 1 (Fast HD)'), findsOneWidget);
      expect(find.text('Server 2 (Backup)'), findsOneWidget);
      expect(find.text('Server 3 (Otaku)'), findsOneWidget);

      // Quick action buttons
      expect(find.byKey(const Key('btn_prev_episode')), findsOneWidget);
      expect(find.byKey(const Key('btn_next_episode')), findsOneWidget);
      expect(find.byKey(const Key('btn_download_episode')), findsOneWidget);
      expect(find.byKey(const Key('btn_rate_episode')), findsOneWidget);

      // Episode list section
      expect(find.text('Daftar Episode'), findsOneWidget);
      expect(find.text('3 Episode'), findsOneWidget);
      expect(find.byKey(const Key('episode_item_1')), findsOneWidget);
      expect(find.byKey(const Key('episode_item_2')), findsOneWidget);
      expect(find.byKey(const Key('episode_item_3')), findsOneWidget);
    });

    testWidgets('tapping play/pause toggles playing state', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Initially playing: pause icon visible
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Tap play/pause button to pause
      await tester.tap(find.byKey(const Key('video_play_pause_button')));
      await tester.pumpAndSettle();

      // Now paused: play icon visible and 'Dijeda' indicator displayed
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('Dijeda'), findsOneWidget);

      // Tap again to resume playing
      await tester.tap(find.byKey(const Key('video_play_pause_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.text('Dijeda'), findsNothing);
    });

    testWidgets('forward and replay 10s adjusts current video position', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('00:00 / 24:00'), findsOneWidget);

      // Forward 10 seconds
      await tester.tap(find.byKey(const Key('video_forward_10')));
      await tester.pumpAndSettle();

      expect(find.textContaining('00:10 / 24:00'), findsOneWidget);

      // Replay 10 seconds
      await tester.tap(find.byKey(const Key('video_replay_10')));
      await tester.pumpAndSettle();

      expect(find.textContaining('00:00 / 24:00'), findsOneWidget);
    });

    testWidgets('switching episode from episode list changes active episode', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Solo Leveling · Ep 1'), findsOneWidget);

      // Ensure visible and tap episode 2
      final ep2Finder = find.byKey(const Key('episode_item_2'));
      await tester.ensureVisible(ep2Finder);
      await tester.tap(ep2Finder);
      await tester.pumpAndSettle();

      // Top bar & episode title should now indicate Episode 2
      expect(find.textContaining('Solo Leveling · Ep 2'), findsOneWidget);
      expect(find.text('Episode 2: Episode 2 - Jika Punya Kesempatan Lain'), findsOneWidget);
    });

    testWidgets('navigating via next and previous buttons updates episode correctly', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Solo Leveling · Ep 1'), findsOneWidget);

      // Ensure visible and tap "Selanjutnya"
      final nextBtn = find.byKey(const Key('btn_next_episode'));
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Solo Leveling · Ep 2'), findsOneWidget);

      // Tapping "Sebelumnya"
      final prevBtn = find.byKey(const Key('btn_prev_episode'));
      await tester.ensureVisible(prevBtn);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Solo Leveling · Ep 1'), findsOneWidget);
    });

    testWidgets('switching server changes selected server and alerts if server is in maintenance', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Tap Server 2 (Backup) - in maintenance
      final server2 = find.text('Server 2 (Backup)');
      await tester.ensureVisible(server2);
      await tester.tap(server2);
      await tester.pumpAndSettle();

      // Verify in-player warning banner is visible
      expect(find.byKey(const Key('in_player_server_error_banner')), findsOneWidget);
      expect(find.textContaining('Server 2 sedang gangguan / maintenance'), findsOneWidget);

      // Tap "Ganti ke Server 1" from inside the player banner
      await tester.tap(find.byKey(const Key('btn_switch_to_active_server')));
      await tester.pumpAndSettle();

      // Warning banner is now dismissed
      expect(find.byKey(const Key('in_player_server_error_banner')), findsNothing);

      // Tap Server 3 (Otaku)
      final server3 = find.text('Server 3 (Otaku)');
      await tester.ensureVisible(server3);
      await tester.tap(server3);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('in_player_server_error_banner')), findsNothing);
    });

    testWidgets('tapping video surface toggles controls overlay visibility', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Tap on video player to hide controls
      await tester.tap(find.byKey(const Key('video_player_gesture_detector')));
      await tester.pumpAndSettle();

      // Tap again to show controls
      await tester.tap(find.byKey(const Key('video_player_gesture_detector')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_play_pause_button')), findsOneWidget);
    });

    testWidgets('fullscreen toggle button switches full screen mode', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Enter fullscreen
      await tester.tap(find.byKey(const Key('video_fullscreen_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);

      // Exit fullscreen
      await tester.tap(find.byKey(const Key('video_fullscreen_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
    });

    testWidgets('download button shows feedback snackbar', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Tap Download
      final downloadBtn = find.byKey(const Key('btn_download_episode'));
      await tester.ensureVisible(downloadBtn);
      await tester.tap(downloadBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Mengunduh Episode 1...'), findsOneWidget);
    });

    testWidgets('rate button shows feedback snackbar', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Tap Rate
      final rateBtn = find.byKey(const Key('btn_rate_episode'));
      await tester.ensureVisible(rateBtn);
      await tester.tap(rateBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Terima kasih atas penilaian Anda!'), findsOneWidget);
    });

    testWidgets('back button triggers navigator pop', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnimeWatchScreen(
                      anime: testAnime,
                      initialEpisode: testEpisodes.first,
                    ),
                  ),
                );
              },
              child: const Text('Open Watch Screen'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Watch Screen'));
      await tester.pumpAndSettle();

      expect(find.byType(AnimeWatchScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('video_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AnimeWatchScreen), findsNothing);
    });

    testWidgets('video player relies directly on native built-in video subtitles without custom overlay or SUB INDO button', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      // Custom in-player subtitle box and SUB INDO toggle button are removed
      expect(find.byKey(const Key('in_player_subtitle_box')), findsNothing);
      expect(find.byKey(const Key('btn_toggle_subtitles')), findsNothing);
      expect(find.text('SUB INDO'), findsNothing);
      expect(find.byKey(const Key('subtitle_sync_bar')), findsNothing);
      expect(find.byKey(const Key('in_player_live_translator_box')), findsNothing);
    });

    testWidgets('shows synopsis with Lihat banyak/sedikit toggle and Platform Resmi button next to Server 4', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final longSynopsisAnime = AnimeDetail(
        id: 'solo-leveling',
        title: 'Solo Leveling',
        japaneseTitle: '俺だけレベルアップな件',
        synopsis:
            'In a world where hunters must battle deadly monsters to protect humanity, Sung Jinwoo is known as the weakest hunter of all mankind until a mysterious System chooses him as its sole player.',
        rating: 8.7,
        releaseYear: 2024,
        status: 'Ongoing',
        genres: ['Action', 'Fantasy'],
        studio: 'A-1 Pictures',
        posterUrl: '',
        backdropUrl: '',
        totalEpisodes: 12,
        episodes: testEpisodes,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AnimeWatchScreen(
            anime: longSynopsisAnime,
            initialEpisode: testEpisodes.first,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platform Resmi'), findsOneWidget);
      expect(find.text('Sinopsis'), findsOneWidget);
      expect(find.text('Lihat banyak'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('btn_toggle_synopsis')));
      await tester.tap(find.byKey(const Key('btn_toggle_synopsis')));
      await tester.pumpAndSettle();
      expect(find.text('Lihat sedikit'), findsOneWidget);
    });

    testWidgets('fullscreen landscape mode exposes lock, brightness, volume, full layar, and episode nav controls', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWatchScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('video_fullscreen_button')));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 400);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_lock_button')), findsOneWidget);
      expect(find.byKey(const Key('video_brightness_slider')), findsOneWidget);
      expect(find.byKey(const Key('video_volume_slider')), findsOneWidget);
      expect(find.byKey(const Key('video_full_screen_fill_button')), findsOneWidget);
      expect(find.byKey(const Key('video_fullscreen_prev_ep')), findsOneWidget);
      expect(find.byKey(const Key('video_fullscreen_next_ep')), findsOneWidget);
      expect(find.text('Ep 2'), findsOneWidget);

      // Lock screen -> hides center & slider controls
      await tester.tap(find.byKey(const Key('video_lock_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('video_forward_10')), findsNothing);
      expect(find.byKey(const Key('video_volume_slider')), findsNothing);
      expect(find.byKey(const Key('video_lock_button')), findsOneWidget);

      // Unlock screen -> restores controls
      await tester.tap(find.byKey(const Key('video_lock_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('video_forward_10')), findsOneWidget);
    });
  });
}
