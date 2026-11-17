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
