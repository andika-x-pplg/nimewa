import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/episode_item.dart';
import 'package:nimeva/presentation/screens/anime_detail_screen.dart';

void main() {
  testWidgets('AnimeDetailScreen renders header, metadata, synopsis, and episode list', (tester) async {
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
}
