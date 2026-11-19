import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/mock/mock_explore_data.dart';

void main() {
  group('Mock Explore Anime Data', () {
    test('provides anime for popular filter with customizable limit', () {
      final popularList = getExploreAnime(filter: 'popular', limit: 6);
      expect(popularList.length, equals(6));
      expect(popularList.first.episodeInfo, isNotEmpty);
      expect(popularList.first.rating, greaterThan(0));

      final allPopular = getExploreAnime(filter: 'popular', limit: 20);
      expect(allPopular.length, greaterThan(6));
    });

    test('provides anime for latest filter', () {
      final latestList = getExploreAnime(filter: 'latest', limit: 6);
      expect(latestList.length, equals(6));
      expect(latestList.first.title, isNot(equals(getExploreAnime(filter: 'popular', limit: 6).first.title)));
    });

    test('provides anime for top_rated filter', () {
      final topRatedList = getExploreAnime(filter: 'top_rated', limit: 6);
      expect(topRatedList.length, equals(6));
      expect(topRatedList.every((a) => a.rating >= 8.5), isTrue);
    });

    test('provides anime for genre filtering', () {
      final actionList = getExploreAnime(filter: 'popular', genre: 'Action', limit: 6);
      expect(actionList.length, equals(6));

      final romanceList = getExploreAnime(filter: 'popular', genre: 'Romance', limit: 6);
      expect(romanceList, isNotEmpty);
      expect(romanceList.first.title, isNot(equals(actionList.first.title)));
    });
  });
}

