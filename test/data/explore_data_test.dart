import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/mock/mock_explore_data.dart';

void main() {
  group('Mock Explore Anime Data', () {
    test('provides exactly 6 anime for popular filter', () {
      final popularList = getExploreAnime(filter: 'popular');
      expect(popularList.length, equals(6));
      expect(popularList.first.episodeInfo, isNotEmpty);
      expect(popularList.first.rating, greaterThan(0));
    });

    test('provides exactly 6 anime for latest filter', () {
      final latestList = getExploreAnime(filter: 'latest');
      expect(latestList.length, equals(6));
      expect(latestList.first.title, isNot(equals(getExploreAnime(filter: 'popular').first.title)));
    });

    test('provides exactly 6 anime for top_rated filter', () {
      final topRatedList = getExploreAnime(filter: 'top_rated');
      expect(topRatedList.length, equals(6));
      expect(topRatedList.every((a) => a.rating >= 8.5), isTrue);
    });

    test('provides 6 anime for genre filtering', () {
      final actionList = getExploreAnime(filter: 'popular', genre: 'Action');
      expect(actionList.length, equals(6));

      final romanceList = getExploreAnime(filter: 'popular', genre: 'Romance');
      expect(romanceList.length, equals(6));
      expect(romanceList.first.title, isNot(equals(actionList.first.title)));
    });
  });
}
