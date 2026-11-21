import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/anilist_api_client.dart';

void main() {
  group('AniListApiClient Tests', () {
    late AniListApiClient client;

    setUp(() {
      client = const AniListApiClient();
    });

    test('parses AniList media JSON correctly into AnimeItem', () {
      final sampleJson = {
        'id': 120120,
        'title': {
          'romaji': 'Tokyo Revengers',
          'english': 'Tokyo Revengers',
          'native': '東京リベンジャーズ',
        },
        'coverImage': {
          'extraLarge': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx120120-wZcR6mHh4Xl6.png',
          'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx120120-wZcR6mHh4Xl6.png',
          'color': '#e45c43',
        },
        'bannerImage': 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/120120-5m1LpL93W1Fk.jpg',
        'episodes': 24,
        'season': 'SPRING',
        'seasonYear': 2021,
        'status': 'FINISHED',
        'averageScore': 78,
        'description': 'Takemichi Hanagaki returns 12 years to his middle school days.',
        'genres': ['Action', 'Drama', 'Supernatural'],
      };

      final item = client.parseMediaItem(sampleJson);

      expect(item.aniListId, equals(120120));
      expect(item.id, equals('120120'));
      expect(item.title, equals('Tokyo Revengers'));
      expect(item.japaneseTitle, equals('東京リベンジャーズ'));
      expect(item.rating, equals(7.8));
      expect(item.releaseYear, equals(2021));
      expect(item.genres, contains('Action'));
      expect(item.posterUrl, contains('bx120120'));
      expect(item.bannerUrl, contains('120120-5m1LpL93W1Fk.jpg'));
      expect(item.statusLabel, equals('Tamat'));
      expect(item.hasVideoAvailable, isTrue);
    });

    test('parses AniList media detail with prequel and sequel relations', () {
      final sampleDetailJson = {
        'id': 142853,
        'title': {
          'romaji': 'Tokyo Revengers: Seiya Kessen-hen',
          'english': 'Tokyo Revengers: Christmas Showdown',
          'native': '東京リベンジャーズ 聖夜決戦編',
        },
        'coverImage': {
          'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx142853.png',
        },
        'bannerImage': 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/142853.jpg',
        'episodes': 13,
        'status': 'FINISHED',
        'averageScore': 76,
        'description': 'Takemichi fights the Black Dragon.',
        'genres': ['Action', 'Drama'],
        'relations': {
          'edges': [
            {
              'relationType': 'PREQUEL',
              'node': {
                'id': 120120,
                'title': {
                  'romaji': 'Tokyo Revengers',
                  'english': 'Tokyo Revengers',
                },
                'format': 'TV',
                'coverImage': {
                  'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx120120.png',
                },
              },
            },
            {
              'relationType': 'SEQUEL',
              'node': {
                'id': 163539,
                'title': {
                  'romaji': 'Tokyo Revengers: Tenjiku-hen',
                  'english': 'Tokyo Revengers: Tenjiku Arc',
                },
                'format': 'TV',
                'coverImage': {
                  'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx163539.png',
                },
              },
            },
          ],
        },
      };

      final detail = client.parseMediaDetail(sampleDetailJson);

      expect(detail.aniListId, equals(142853));
      expect(detail.title, equals('Tokyo Revengers: Christmas Showdown'));
      expect(detail.relations.length, equals(2));
      expect(detail.relations[0].relationType, equals('PREQUEL'));
      expect(detail.relations[0].id, equals(120120));
      expect(detail.relations[1].relationType, equals('SEQUEL'));
      expect(detail.relations[1].id, equals(163539));
    });

    test('marks hasVideoAvailable correctly without hiding anime with 0 or missing videos', () {
      final incompleteAnimeJson = {
        'id': 999998, // Unreleased anime / no video uploaded
        'title': {
          'romaji': 'Unreleased Anime Project',
          'english': 'Unreleased Anime Project',
        },
        'coverImage': {
          'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx999998.png',
        },
        'episodes': 0,
        'status': 'NOT_YET_RELEASED',
        'averageScore': 0,
        'description': 'Upcoming unreleased anime.',
        'genres': ['Action'],
      };

      final item = client.parseMediaItem(incompleteAnimeJson);
      expect(item.aniListId, equals(999998));
      expect(item.hasVideoAvailable, isFalse);
    });

    test('offline fallback cachedTrendingAnime provides authentic AniList-structured data', () {
      final trending = AniListApiClient.cachedTrendingAnime;
      expect(trending, isNotEmpty);
      expect(trending.length, greaterThanOrEqualTo(5));
      expect(trending.first.aniListId, greaterThan(0));
      expect(trending.first.posterUrl, contains('anilistcdn'));
    });
  });
}

