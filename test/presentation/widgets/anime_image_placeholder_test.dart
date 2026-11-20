import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/presentation/widgets/anime_image_placeholder.dart';

void main() {
  testWidgets('AnimeImagePlaceholder renders title and movie icon cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 150,
            height: 220,
            child: AnimeImagePlaceholder(
              title: 'Tokyo Revengers: Santen Sensou',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tokyo Revengers: Santen Sensou'), findsOneWidget);
    expect(find.byIcon(Icons.movie_creation_outlined), findsOneWidget);
  });

  testWidgets('AnimeImagePlaceholder falls back to default app title if title is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 150,
            height: 220,
            child: AnimeImagePlaceholder(
              title: '',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nimeva'), findsOneWidget);
  });
}
