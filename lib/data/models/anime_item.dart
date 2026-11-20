/// Represents an anime title in the catalog.
class AnimeItem {
  final String id;
  final String title;
  final String japaneseTitle;
  final double rating;
  final int releaseYear;
  final List<String> genres;
  final String description;
  final String posterUrl;
  final String backdropUrl;
  final String episodeInfo;
  final String statusLabel;
  final int aniListId;
  final bool hasVideoAvailable;
  final String? bannerUrl;

  const AnimeItem({
    required this.id,
    required this.title,
    required this.japaneseTitle,
    required this.rating,
    required this.releaseYear,
    required this.genres,
    required this.description,
    required this.posterUrl,
    required this.backdropUrl,
    this.episodeInfo = 'SUB · EP 12',
    this.statusLabel = 'Ongoing',
    this.aniListId = 0,
    this.hasVideoAvailable = true,
    this.bannerUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AnimeItem(id: $id, title: $title, rating: $rating)';
}
