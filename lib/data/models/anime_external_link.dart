/// Represents an external official or streaming platform link from AniList.
class AnimeExternalLink {
  final int id;
  final String url;
  final String site;
  final String type;
  final String? icon;
  final String? color;

  const AnimeExternalLink({
    required this.id,
    required this.url,
    required this.site,
    required this.type,
    this.icon,
    this.color,
  });

  /// Returns true if this link represents an official streaming platform (e.g. Crunchyroll, Netflix).
  bool get isStreaming => type.toUpperCase() == 'STREAMING';

  factory AnimeExternalLink.fromJson(Map<String, dynamic> json) {
    return AnimeExternalLink(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      url: json['url']?.toString() ?? '',
      site: json['site']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'site': site,
        'type': type,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      };
}

