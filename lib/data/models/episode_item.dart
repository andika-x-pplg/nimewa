/// Model representing an individual anime episode.
class EpisodeItem {
  final String id;
  final int episodeNumber;
  final String title;
  final String releaseDate;
  final String streamUrl;

  const EpisodeItem({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.releaseDate,
    required this.streamUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EpisodeItem(id: $id, ep: $episodeNumber, title: $title)';
}
