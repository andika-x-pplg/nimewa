import '../models/anime_item.dart';

/// Curated mock list of the 5 hottest popular anime releases available in the app.
const List<AnimeItem> mockPopularAnime = [
  AnimeItem(
    id: 'solo-leveling',
    title: 'Solo Leveling',
    japaneseTitle: '俺だけレベルアップな件',
    rating: 8.8,
    releaseYear: 2024,
    genres: ['Action', 'Fantasy', 'Supernatural'],
    description:
        'Sung Jinwoo bangkit dari Hunter terlemah menjadi satu-satunya yang dapat naik level tanpa batas dalam membela dunia.',
    posterUrl: 'https://media.kitsu.app/anime/poster_images/46231/large.jpg',
    backdropUrl: 'https://media.kitsu.app/anime/poster_images/46231/large.jpg',
    episodeInfo: 'SUB · 12 EPS (Tamat)',
    statusLabel: 'Tamat',
  ),
  AnimeItem(
    id: 'demon-slayer',
    title: 'Demon Slayer: Kimetsu no Yaiba',
    japaneseTitle: '鬼滅の刃',
    rating: 8.9,
    releaseYear: 2019,
    genres: ['Action', 'Fantasy', 'Historical'],
    description:
        'Tanjiro Kamado berjuang membasmi iblis demi mengembalikan adiknya, Nezuko, menjadi manusia kembali.',
    posterUrl: 'https://media.kitsu.app/anime/poster_images/41370/large.jpg',
    backdropUrl: 'https://media.kitsu.app/anime/poster_images/41370/large.jpg',
    episodeInfo: 'SUB · 26 EPS (Tamat)',
    statusLabel: 'Tamat',
  ),
  AnimeItem(
    id: 'attack-on-titan',
    title: 'Attack on Titan',
    japaneseTitle: '進撃の巨人',
    rating: 8.8,
    releaseYear: 2013,
    genres: ['Action', 'Fantasy', 'Mystery', 'Drama'],
    description:
        'Pertarungan sengit umat manusia melawan para Titan raksasa yang mengancam kepunahan peradaban.',
    posterUrl: 'https://media.kitsu.app/anime/poster_images/7442/large.jpg',
    backdropUrl: 'https://media.kitsu.app/anime/poster_images/7442/large.jpg',
    episodeInfo: 'SUB · 25 EPS (Tamat)',
    statusLabel: 'Tamat',
  ),
  AnimeItem(
    id: 'jujutsu-kaisen',
    title: 'Jujutsu Kaisen',
    japaneseTitle: '呪術廻戦',
    rating: 8.9,
    releaseYear: 2020,
    genres: ['Action', 'Supernatural', 'Fantasy'],
    description:
        'Yuji Itadori menelan jari kutukan Sukuna dan memasuki dunia pertempuran penyihir Jujutsu.',
    posterUrl: 'https://media.kitsu.app/anime/poster_images/43806/large.jpg',
    backdropUrl: 'https://media.kitsu.app/anime/poster_images/43806/large.jpg',
    episodeInfo: 'SUB · 24 EPS (Tamat)',
    statusLabel: 'Tamat',
  ),
  AnimeItem(
    id: 'tokyo-revengers-s3',
    title: 'Tokyo Revengers: Tenjiku Arc',
    japaneseTitle: '東京リベンジャーズ 天竺編',
    rating: 8.3,
    releaseYear: 2023,
    genres: ['Action', 'Drama', 'Delinquents'],
    description:
        'Pertarungan besar antara Tokyo Manji Gang dan geng Tenjiku pimpinan Izana Kurokawa.',
    posterUrl: 'https://media.kitsu.app/anime/poster_images/47537/large.jpg',
    backdropUrl: 'https://media.kitsu.app/anime/poster_images/47537/large.jpg',
    episodeInfo: 'SUB · 13 EPS (Tamat)',
    statusLabel: 'Tamat',
  ),
];
