import 'episode_item.dart';

/// Full detail model for an anime including synopsis and episode list.
class AnimeDetail {
  final String id;
  final String title;
  final String japaneseTitle;
  final double rating;
  final int releaseYear;
  final List<String> genres;
  final String synopsis;
  final String posterUrl;
  final String backdropUrl;
  final String status;
  final String studio;
  final int totalEpisodes;
  final List<EpisodeItem> episodes;

  const AnimeDetail({
    required this.id,
    required this.title,
    required this.japaneseTitle,
    required this.rating,
    required this.releaseYear,
    required this.genres,
    required this.synopsis,
    required this.posterUrl,
    required this.backdropUrl,
    required this.status,
    required this.studio,
    required this.totalEpisodes,
    required this.episodes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeDetail &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AnimeDetail(id: $id, title: $title, episodes: ${episodes.length})';
}

