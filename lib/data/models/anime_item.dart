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

  /// Checks whether this anime item matches the user's search query.
  /// Matches against:
  /// 1. Direct case-insensitive substring in [title] or [japaneseTitle]
  /// 2. Any word prefix (e.g. "sol" -> "Solo Leveling", "rev" -> "Tokyo Revengers")
  /// 3. Acronyms & Initials (e.g. "tr" -> "Tokyo Revengers", "aot" -> "Attack on Titan", "jjk" -> "Jujutsu Kaisen", "ds" -> "Demon Slayer", "sl" -> "Solo Leveling", "yns" -> "Yosuga no Sora")
  /// 4. Subsequence of words/characters
  bool matchesSearch(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final lowerTitle = title.toLowerCase();
    final lowerJp = japaneseTitle.toLowerCase();

    // 1. Direct contains in title or japanese title
    if (lowerTitle.contains(query) || lowerJp.contains(query)) {
      return true;
    }

    // 2. Word prefix match
    final words = lowerTitle
        .split(RegExp(r'[\s\-_:;,()]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.any((w) => w.startsWith(query))) {
      return true;
    }

    // 3. Known acronyms & shortcuts
    const acronyms = {
      'jjk': ['jujutsu kaisen'],
      'aot': ['attack on titan', 'shingeki no kyojin'],
      'snk': ['shingeki no kyojin', 'attack on titan'],
      'ds': ['demon slayer', 'kimetsu no yaiba'],
      'kny': ['kimetsu no yaiba', 'demon slayer'],
      'tr': ['tokyo revengers'],
      'sl': ['solo leveling'],
      'csm': ['chainsaw man'],
      'dn': ['death note'],
      'op': ['one piece'],
      'mha': ['boku no hero academia', 'my hero academia'],
      'bnha': ['boku no hero academia', 'my hero academia'],
      'sao': ['sword art online'],
      'fma': ['fullmetal alchemist'],
      'fmab': ['fullmetal alchemist'],
      'hxh': ['hunter x hunter'],
      'yns': ['yosuga no sora'],
      'sg': ['steins;gate', 'steins gate'],
      'tg': ['tokyo ghoul'],
      'ddd': ['dan da dan', 'dandadan'],
      'dd': ['dan da dan', 'dandadan'],
      'knw': ['kimi no na wa'],
      'knnw': ['kimi no na wa'],
      'your name': ['kimi no na wa'],
      'frieren': ['sousou no frieren'],
    };

    final expansions = acronyms[query];
    if (expansions != null) {
      if (expansions.any((exp) => lowerTitle.contains(exp) || lowerJp.contains(exp))) {
        return true;
      }
    }

    // 4. Initials match (e.g. words = ["Tokyo", "Revengers"] -> initials = "tr")
    if (words.length > 1) {
      final allInitials = words.map((w) => w[0]).join();
      if (allInitials.startsWith(query) || allInitials.contains(query)) {
        return true;
      }

      // Significant words (excluding articles/prepositions like 'no', 'on', 'wa', 'x', 'the', 'of', 'a')
      final significantWords = words
          .where((w) => !['no', 'on', 'wa', 'x', 'the', 'of', 'a', 'in', 'and'].contains(w))
          .toList();
      if (significantWords.length > 1) {
        final sigInitials = significantWords.map((w) => w[0]).join();
        if (sigInitials.startsWith(query) || sigInitials.contains(query)) {
          return true;
        }
      }

      // Subsequence match across initials
      int qi = 0;
      for (final word in words) {
        if (qi < query.length && word.startsWith(query[qi])) {
          qi++;
        }
      }
      if (qi == query.length) {
        return true;
      }
    }

    return false;
  }
}
