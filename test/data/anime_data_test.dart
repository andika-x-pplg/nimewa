import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/anime_item.dart';
import 'package:nimeva/data/mock/mock_anime_data.dart';

void main() {
  group('AnimeItem Model', () {
    test('instantiates correctly with required fields', () {
      const item = AnimeItem(
        id: 'test-id',
        title: 'Test Title',
        japaneseTitle: 'テストタイトル',
        rating: 8.5,
        releaseYear: 2024,
        genres: ['Action', 'Fantasy'],
        description: 'Test description text.',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
      );

      expect(item.id, 'test-id');
      expect(item.title, 'Test Title');
      expect(item.japaneseTitle, 'テストタイトル');
      expect(item.rating, 8.5);
      expect(item.releaseYear, 2024);
      expect(item.genres, ['Action', 'Fantasy']);
      expect(item.description, 'Test description text.');
      expect(item.posterUrl, 'https://example.com/poster.jpg');
      expect(item.backdropUrl, 'https://example.com/backdrop.jpg');
    });
  });

  group('AnimeItem matchesSearch', () {
    const tokyoRevengers = AnimeItem(
      id: 'tokyo-revengers',
      title: 'Tokyo Revengers: Tenjiku Arc',
      japaneseTitle: '東京リベンジャーズ 天竺編',
      rating: 8.3,
      releaseYear: 2023,
      genres: ['Action', 'Drama'],
      description: 'Takemichi fights.',
      posterUrl: 'https://example.com/tr.jpg',
      backdropUrl: 'https://example.com/tr.jpg',
    );

    const attackOnTitan = AnimeItem(
      id: 'attack-on-titan',
      title: 'Attack on Titan',
      japaneseTitle: '進撃の巨人',
      rating: 8.8,
      releaseYear: 2013,
      genres: ['Action', 'Fantasy'],
      description: 'Eren fights titans.',
      posterUrl: 'https://example.com/aot.jpg',
      backdropUrl: 'https://example.com/aot.jpg',
    );

    const yosugaNoSora = AnimeItem(
      id: '8861',
      title: 'Yosuga no Sora',
      japaneseTitle: 'ヨスガノソラ',
      rating: 7.2,
      releaseYear: 2010,
      genres: ['Romance', 'Drama'],
      description: 'Haruka and Sora.',
      posterUrl: 'https://example.com/yns.jpg',
      backdropUrl: 'https://example.com/yns.jpg',
    );

    test('matches by substring and word prefix', () {
      expect(tokyoRevengers.matchesSearch('tokyo'), isTrue);
      expect(tokyoRevengers.matchesSearch('rev'), isTrue);
      expect(tokyoRevengers.matchesSearch('tenjiku'), isTrue);
      expect(yosugaNoSora.matchesSearch('yosuga'), isTrue);
      expect(yosugaNoSora.matchesSearch('sora'), isTrue);
    });

    test('matches by initials and acronyms', () {
      expect(tokyoRevengers.matchesSearch('tr'), isTrue);
      expect(tokyoRevengers.matchesSearch('TR'), isTrue);
      expect(attackOnTitan.matchesSearch('aot'), isTrue);
      expect(attackOnTitan.matchesSearch('at'), isTrue);
      expect(attackOnTitan.matchesSearch('snk'), isTrue);
      expect(yosugaNoSora.matchesSearch('yns'), isTrue);
      expect(yosugaNoSora.matchesSearch('ys'), isTrue);
    });

    test('returns false for non-matching queries', () {
      expect(tokyoRevengers.matchesSearch('bleach'), isFalse);
      expect(attackOnTitan.matchesSearch('naruto'), isFalse);
      expect(yosugaNoSora.matchesSearch('goku'), isFalse);
    });

    test('returns true for empty or whitespace query', () {
      expect(tokyoRevengers.matchesSearch(''), isTrue);
      expect(tokyoRevengers.matchesSearch('   '), isTrue);
    });
  });

  group('mockPopularAnime Catalog', () {
    test('contains exactly 5 anime items', () {
      expect(mockPopularAnime.length, 5);
    });

    test('all items have valid non-empty fields and positive ratings', () {
      for (final anime in mockPopularAnime) {
        expect(anime.id, isNotEmpty);
        expect(anime.title, isNotEmpty);
        expect(anime.japaneseTitle, isNotEmpty);
        expect(anime.rating, greaterThan(0.0));
        expect(anime.rating, lessThanOrEqualTo(10.0));
        expect(anime.releaseYear, greaterThanOrEqualTo(2013));
        expect(anime.genres, isNotEmpty);
        expect(anime.description, isNotEmpty);
        expect(anime.posterUrl, startsWith('https://'));
        expect(anime.backdropUrl, startsWith('https://'));
        expect(anime.posterUrl, isNot(contains('avac.moe')));
      }
    });

    test('item 1 is Solo Leveling', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'solo-leveling');
      expect(anime.title, 'Solo Leveling');
      expect(anime.japaneseTitle, '俺だけレベルアップな件');
      expect(anime.rating, 8.8);
      expect(anime.releaseYear, 2024);
      expect(anime.genres, containsAll(['Action', 'Fantasy', 'Supernatural']));
    });

    test('item 2 is Demon Slayer', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'demon-slayer');
      expect(anime.title, contains('Demon Slayer'));
      expect(anime.japaneseTitle, '鬼滅の刃');
      expect(anime.rating, 8.9);
      expect(anime.genres, containsAll(['Action', 'Fantasy', 'Historical']));
    });

    test('item 3 is Attack on Titan', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'attack-on-titan');
      expect(anime.title, 'Attack on Titan');
      expect(anime.japaneseTitle, '進撃の巨人');
      expect(anime.rating, 8.8);
      expect(anime.genres, containsAll(['Action', 'Fantasy']));
    });

    test('item 4 is Jujutsu Kaisen', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'jujutsu-kaisen');
      expect(anime.title, 'Jujutsu Kaisen');
      expect(anime.japaneseTitle, '呪術廻戦');
      expect(anime.rating, 8.9);
      expect(anime.genres, containsAll(['Action', 'Supernatural']));
    });

    test('item 5 is Tokyo Revengers Season 3', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'tokyo-revengers-s3');
      expect(anime.title, 'Tokyo Revengers: Tenjiku Arc');
      expect(anime.japaneseTitle, contains('東京リベンジャーズ'));
      expect(anime.rating, 8.3);
      expect(anime.genres, containsAll(['Action', 'Drama', 'Delinquents']));
    });
  });
}
