import 'anime_relation_item.dart';
import 'episode_item.dart';

/// Full detail model for an anime including synopsis, relations, and episode list.
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
  final int aniListId;
  final List<AnimeRelationItem> relations;
  final bool hasVideoAvailable;
  final String? bannerUrl;

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
    this.aniListId = 0,
    this.relations = const [],
    this.hasVideoAvailable = true,
    this.bannerUrl,
  });

  AnimeDetail copyWith({
    String? id,
    String? title,
    String? japaneseTitle,
    double? rating,
    int? releaseYear,
    List<String>? genres,
    String? synopsis,
    String? posterUrl,
    String? backdropUrl,
    String? status,
    String? studio,
    int? totalEpisodes,
    List<EpisodeItem>? episodes,
    int? aniListId,
    List<AnimeRelationItem>? relations,
    bool? hasVideoAvailable,
    String? bannerUrl,
  }) {
    return AnimeDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      japaneseTitle: japaneseTitle ?? this.japaneseTitle,
      rating: rating ?? this.rating,
      releaseYear: releaseYear ?? this.releaseYear,
      genres: genres ?? this.genres,
      synopsis: synopsis ?? this.synopsis,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      status: status ?? this.status,
      studio: studio ?? this.studio,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      episodes: episodes ?? this.episodes,
      aniListId: aniListId ?? this.aniListId,
      relations: relations ?? this.relations,
      hasVideoAvailable: hasVideoAvailable ?? this.hasVideoAvailable,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

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

