/// Represents a related anime (prequel, sequel, side story, etc.) from AniList.
class AnimeRelationItem {
  final int id;
  final String title;
  final String relationType;
  final String posterUrl;
  final String format;

  const AnimeRelationItem({
    required this.id,
    required this.title,
    required this.relationType,
    required this.posterUrl,
    this.format = 'TV',
  });

  factory AnimeRelationItem.fromJson(Map<String, dynamic> json) {
    final relationType = json['relationType']?.toString() ?? 'SIDE_STORY';
    final node = json['node'] as Map<String, dynamic>? ?? {};
    final id = node['id'] is num ? (node['id'] as num).toInt() : int.tryParse(node['id']?.toString() ?? '0') ?? 0;
    
    final titles = node['title'] as Map<String, dynamic>? ?? {};
    final title = titles['romaji']?.toString() ??
        titles['english']?.toString() ??
        titles['native']?.toString() ??
        'Anime Relation';

    final cover = node['coverImage'] as Map<String, dynamic>? ?? {};
    final posterUrl = cover['large']?.toString() ??
        cover['medium']?.toString() ??
        '';

    final format = node['format']?.toString() ?? 'TV';

    return AnimeRelationItem(
      id: id,
      title: title,
      relationType: relationType,
      posterUrl: posterUrl,
      format: format,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeRelationItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          relationType == other.relationType;

  @override
  int get hashCode => Object.hash(id, relationType);

  @override
  String toString() => 'AnimeRelationItem(id: $id, title: $title, relationType: $relationType)';
}
