import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/presentation/widgets/anime_grid_card.dart';

void main() {
  const sampleAnime = AnimeItem(
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
              item: sampleAnime,
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

    await tester.tap(find.byType(AnimeGridCard));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
