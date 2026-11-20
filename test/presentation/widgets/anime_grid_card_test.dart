import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/presentation/widgets/anime_grid_card.dart';
import 'package:nimeva/presentation/widgets/anime_image_placeholder.dart';

void main() {
  const sampleAnimeWithVideo = AnimeItem(
    id: 'solo-leveling',
    title: 'Solo Leveling: Arise',
    japaneseTitle: '俺だけレベルアップな件',
    rating: 8.8,
    releaseYear: 2025,
    genres: ['Action', 'Fantasy'],
    description: 'Sung Jinwoo hunter.',
    posterUrl: 'https://example.com/poster.jpg',
    backdropUrl: 'https://example.com/backdrop.jpg',
    episodeInfo: 'SUB · EP 8',
    statusLabel: 'Ongoing',
    hasVideoAvailable: true,
  );

  const sampleAnimeNoVideo = AnimeItem(
    id: 'tokyo-revengers-s4',
    title: 'Tokyo Revengers: Santen Sensou',
    japaneseTitle: '東京リベンジャーズ 三天戦争編',
    rating: 8.2,
    releaseYear: 2026,
    genres: ['Action', 'Drama'],
    description: 'Tokyo Revengers continuation.',
    posterUrl: '',
    backdropUrl: '',
    episodeInfo: 'Upcoming',
    statusLabel: 'Upcoming',
    hasVideoAvailable: false,
  );

  testWidgets('AnimeGridCard renders title, rating, episode info and handles tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: AnimeGridCard(
              item: sampleAnimeWithVideo,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Solo Leveling: Arise'), findsOneWidget);
    expect(find.text('8.8'), findsOneWidget);
    expect(find.text('SUB · EP 8'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('Tersedia Video'), findsOneWidget);

    await tester.tap(find.byType(AnimeGridCard));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('AnimeGridCard displays Belum Tersedia badge and placeholder when poster is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 180,
            child: AnimeGridCard(
              item: sampleAnimeNoVideo,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tokyo Revengers: Santen Sensou'), findsWidgets);
    expect(find.text('Belum Tersedia'), findsOneWidget);
    expect(find.byType(AnimeImagePlaceholder), findsOneWidget);
  });
}
