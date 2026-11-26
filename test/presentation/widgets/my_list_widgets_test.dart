import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_theme.dart';
import 'package:nimeva/data/models/my_list_entry.dart';
import 'package:nimeva/presentation/widgets/continue_watching_strip.dart';
import 'package:nimeva/presentation/widgets/my_list_anime_card.dart';

void main() {
  Widget wrapWidget(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            child: child,
          ),
        ),
      ),
    );
  }

  MyListEntry makeEntry({
    String key = 'jujutsu-kaisen',
    String title = 'Jujutsu Kaisen',
    int total = 12,
    int watched = 8,
    MyListStatus status = MyListStatus.watching,
    bool playable = true,
  }) {
    return MyListEntry(
      canonicalKey: key,
      animeId: key,
      aniListId: 113415,
      title: title,
      japaneseTitle: '呪術廻戦',
      posterUrl: '',
      backdropUrl: '',
      rating: 8.7,
      releaseYear: 2020,
      genres: const ['Action'],
      description: 'Sorcerers fight curses.',
      totalEpisodes: total,
      watchedEpisode: watched,
      currentEpisodeTitle: watched > 0 ? 'Episode $watched' : null,
      status: status,
      hasVideoAvailable: playable,
      updatedAt: DateTime(2026, 11, 25, 13, 0),
    );
  }

  group('MyListAnimeCard & ContinueWatchingStrip', () {
    testWidgets('MyListAnimeCard displays episode progress, LinearProgressIndicator, percent & remaining, and >= 44dp Play button', (tester) async {
      bool tappedCard = false;
      bool tappedPlay = false;

      await tester.pumpWidget(
        wrapWidget(
          MyListAnimeCard(
            entry: makeEntry(),
            onTap: () => tappedCard = true,
            onPlayTap: () => tappedPlay = true,
            onStatusChanged: (_) {},
            onEditProgress: () {},
            onDelete: () {},
          ),
        ),
      );

      expect(find.text('Jujutsu Kaisen'), findsOneWidget);
      expect(find.text('8 dari 12 episode'), findsOneWidget);
      expect(find.text('67% selesai · Sisa 33%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final playBtn = find.byKey(const Key('my_list_play_button_jujutsu-kaisen'));
      expect(playBtn, findsOneWidget);
      final playSize = tester.getSize(playBtn);
      expect(playSize.width, greaterThanOrEqualTo(44.0));
      expect(playSize.height, greaterThanOrEqualTo(44.0));

      await tester.tap(playBtn);
      expect(tappedPlay, isTrue);
      expect(tappedCard, isFalse);

      await tester.tap(find.text('Jujutsu Kaisen'));
      expect(tappedCard, isTrue);
    });

    testWidgets('MyListAnimeCard shows external platform 0% label and detail icon when hasVideoAvailable is false', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          MyListAnimeCard(
            entry: makeEntry(
              key: 'dandadan',
              title: 'Dan Da Dan',
              watched: 0,
              status: MyListStatus.saved,
              playable: false,
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Platform resmi · Progres 0%'), findsOneWidget);
      expect(find.text('0% selesai · Sisa 100%'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('MyListAnimeCard renders cleanly without overflow on 320px width and triggers menu actions', (tester) async {
      MyListStatus? changedStatus;
      bool deleted = false;
      bool edited = false;

      await tester.pumpWidget(
        wrapWidget(
          MyListAnimeCard(
            entry: makeEntry(
              key: 'long-title',
              title: 'Kono Subarashii Sekai ni Shukufuku wo! Season 3 Very Long Title Edition',
            ),
            onTap: () {},
            onPlayTap: () {},
            onStatusChanged: (s) => changedStatus = s,
            onEditProgress: () => edited = true,
            onDelete: () => deleted = true,
          ),
          size: const Size(320, 800),
        ),
      );

      expect(tester.takeException(), isNull);

      final menuBtn = find.byKey(const Key('my_list_menu_button_long-title'));
      expect(menuBtn, findsOneWidget);
      expect(tester.getSize(menuBtn).width, greaterThanOrEqualTo(44.0));
      expect(tester.getSize(menuBtn).height, greaterThanOrEqualTo(44.0));

      await tester.tap(menuBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atur Episode'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);

      await tester.tap(menuBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tandai Selesai'));
      await tester.pumpAndSettle();
      expect(changedStatus, equals(MyListStatus.completed));

      await tester.tap(menuBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus dari Daftarku'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('ContinueWatchingStrip caps cards at 5 and handles See All and entry tap', (tester) async {
      bool seeAllTapped = false;
      MyListEntry? tappedEntry;

      final entries = List.generate(
        7,
        (i) => makeEntry(
          key: 'anime-$i',
          title: 'Anime Title $i',
          watched: i + 1,
        ),
      );

      await tester.pumpWidget(
        wrapWidget(
          ContinueWatchingStrip(
            entries: entries,
            onSeeAllTap: () => seeAllTapped = true,
            onEntryTap: (e) => tappedEntry = e,
          ),
          size: const Size(360, 800),
        ),
      );

      expect(find.text('Continue watching'), findsOneWidget);
      expect(find.text('Lihat semua'), findsOneWidget);
      expect(find.text('Anime Title 0'), findsOneWidget);

      await tester.tap(find.text('Lihat semua'));
      expect(seeAllTapped, isTrue);

      await tester.tap(find.text('Anime Title 0'));
      expect(tappedEntry?.canonicalKey, equals('anime-0'));

      await tester.dragUntilVisible(
        find.text('Anime Title 4'),
        find.byType(ListView),
        const Offset(-250, 0),
      );
      expect(find.text('Anime Title 4'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('Anime Title 5'), findsNothing);
    });
  });
}
