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
        releaseYear: 2025,
        genres: ['Action', 'Fantasy'],
        description: 'Test description text.',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
      );

      expect(item.id, 'test-id');
      expect(item.title, 'Test Title');
      expect(item.japaneseTitle, 'テストタイトル');
      expect(item.rating, 8.5);
      expect(item.releaseYear, 2025);
      expect(item.genres, ['Action', 'Fantasy']);
      expect(item.description, 'Test description text.');
      expect(item.posterUrl, 'https://example.com/poster.jpg');
      expect(item.backdropUrl, 'https://example.com/backdrop.jpg');
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
        expect(anime.releaseYear, greaterThanOrEqualTo(2020));
        expect(anime.genres, isNotEmpty);
        expect(anime.description, isNotEmpty);
        expect(anime.posterUrl, startsWith('https://'));
        expect(anime.backdropUrl, startsWith('https://'));
      }
    });

    test('item 1 is Tokyo Revengers Season 4', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'tokyo-revengers-s4');
      expect(anime.title, 'Tokyo Revengers Season 4');
      expect(anime.japaneseTitle, '東京リベンジャーズ');
      expect(anime.rating, 7.8);
      expect(anime.releaseYear, 2025);
      expect(anime.genres, containsAll(['Action', 'Drama', 'Delinquents', 'Supernatural']));
    });

    test('item 2 is Black Clover Season 2', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'black-clover-s2');
      expect(anime.title, 'Black Clover Season 2');
      expect(anime.japaneseTitle, 'ブラッククローバー');
      expect(anime.rating, 8.0);
      expect(anime.releaseYear, 2025);
      expect(anime.genres, containsAll(['Action', 'Fantasy', 'Magic', 'Shounen']));
    });

    test('item 3 is Chii Fuyo', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'chii-fuyo');
      expect(anime.title, 'Chii Fuyo (Tsuihou Sareta Cheat Fuyo Majutsushi)');
      expect(anime.japaneseTitle, '追放されたチート付与魔術師は気ままなセカンドライフを謳歌する');
      expect(anime.rating, 7.6);
      expect(anime.releaseYear, 2025);
      expect(anime.genres, containsAll(['Fantasy', 'Action', 'Adventure', 'Comedy']));
    });

    test('item 4 is Hotaru no Yomeiri', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'hotaru-no-yomeiri');
      expect(anime.title, 'Hotaru no Yomeiri (Firefly Wedding)');
      expect(anime.japaneseTitle, 'ホタルの嫁入り');
      expect(anime.rating, 8.2);
      expect(anime.releaseYear, 2025);
      expect(anime.genres, containsAll(['Romance', 'Historical', 'Suspense', 'Drama']));
    });

    test('item 5 is Tsuihou sareta Tensei juukishi', () {
      final anime = mockPopularAnime.firstWhere((a) => a.id == 'tensei-juukishi');
      expect(anime.title, 'Tsuihou sareta Tensei juukishi wa game chishiki de musou suru');
      expect(anime.japaneseTitle, '追放された転生重騎士はゲーム知識で無双する');
      expect(anime.rating, 7.7);
      expect(anime.releaseYear, 2025);
      expect(anime.genres, containsAll(['Fantasy', 'Action', 'Isekai', 'Strategy']));
    });
  });
}
