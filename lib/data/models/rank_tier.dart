import 'package:flutter/material.dart';

/// Represents one of the 16 progression ranks in Nimeva.
class RankTier {
  final int tier;
  final String name;
  final int minLevel;
  final int? maxLevel;
  final IconData icon;
  final Color color;
  final List<Color> borderColors;
  final int expPerSecond;

  const RankTier({
    required this.tier,
    required this.name,
    required this.minLevel,
    required this.maxLevel,
    required this.icon,
    required this.color,
    required this.borderColors,
    required this.expPerSecond,
  });

  /// Tiers 7 through 16 feature luxury multi-color flowing borders and glow.
  bool get isLuxury => tier >= 7;

  String get levelRangeLabel {
    final minStr = RankCatalog.formatNumber(minLevel);
    if (maxLevel == null) {
      return 'Lv. $minStr+++';
    }
    return 'Lv. $minStr - ${RankCatalog.formatNumber(maxLevel!)}';
  }
}

/// Catalog of all 16 ranks and EXP/Level conversion helpers.
abstract final class RankCatalog {
  static const int expPerLevel = 100;

  static const List<RankTier> tiers = [
    RankTier(
      tier: 1,
      name: 'Ayam',
      minLevel: 1,
      maxLevel: 49,
      icon: Icons.egg_alt_rounded,
      color: Color(0xFF9CA3AF),
      borderColors: [Color(0xFF4B5563), Color(0xFF9CA3AF), Color(0xFF4B5563)],
      expPerSecond: 10,
    ),
    RankTier(
      tier: 2,
      name: 'Genin',
      minLevel: 50,
      maxLevel: 149,
      icon: Icons.eco_rounded,
      color: Color(0xFF6EE7B7),
      borderColors: [Color(0xFF065F46), Color(0xFF6EE7B7), Color(0xFF065F46)],
      expPerSecond: 25,
    ),
    RankTier(
      tier: 3,
      name: 'Chuunin',
      minLevel: 150,
      maxLevel: 499,
      icon: Icons.shield_outlined,
      color: Color(0xFF34D399),
      borderColors: [Color(0xFF047857), Color(0xFF34D399), Color(0xFF047857)],
      expPerSecond: 60,
    ),
    RankTier(
      tier: 4,
      name: 'Jounin',
      minLevel: 500,
      maxLevel: 2499,
      icon: Icons.flash_on_rounded,
      color: Color(0xFF38BDF8),
      borderColors: [Color(0xFF0369A1), Color(0xFF38BDF8), Color(0xFF0369A1)],
      expPerSecond: 200,
    ),
    RankTier(
      tier: 5,
      name: 'Anbu',
      minLevel: 2500,
      maxLevel: 4999,
      icon: Icons.visibility_rounded,
      color: Color(0xFF60A5FA),
      borderColors: [Color(0xFF1D4ED8), Color(0xFF60A5FA), Color(0xFF1D4ED8)],
      expPerSecond: 400,
    ),
    RankTier(
      tier: 6,
      name: 'Hashira',
      minLevel: 6000,
      maxLevel: 9990,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFB923C),
      borderColors: [Color(0xFF9A3412), Color(0xFFFB923C), Color(0xFF9A3412)],
      expPerSecond: 800,
    ),
    RankTier(
      tier: 7,
      name: 'Kage',
      minLevel: 10000,
      maxLevel: 19999,
      icon: Icons.nights_stay_rounded,
      color: Color(0xFFFBBF24),
      borderColors: [
        Color(0xFFFBBF24),
        Color(0xFFFEF08A),
        Color(0xFFF59E0B),
        Color(0xFFFFFFFF),
        Color(0xFFFBBF24),
      ],
      expPerSecond: 1600,
    ),
    RankTier(
      tier: 8,
      name: 'Nakama',
      minLevel: 20000,
      maxLevel: 49000,
      icon: Icons.explore_rounded,
      color: Color(0xFFF472B6),
      borderColors: [
        Color(0xFFF472B6),
        Color(0xFFFBBF24),
        Color(0xFFEC4899),
        Color(0xFFFFFFFF),
        Color(0xFFF472B6),
      ],
      expPerSecond: 4000,
    ),
    RankTier(
      tier: 9,
      name: 'Yonkou',
      minLevel: 50000,
      maxLevel: 99999,
      icon: Icons.anchor_rounded,
      color: Color(0xFFC084FC),
      borderColors: [
        Color(0xFFC084FC),
        Color(0xFF38BDF8),
        Color(0xFFA855F7),
        Color(0xFFFDE047),
        Color(0xFFC084FC),
      ],
      expPerSecond: 9000,
    ),
    RankTier(
      tier: 10,
      name: 'Saiyajin',
      minLevel: 100000,
      maxLevel: 199000,
      icon: Icons.bolt_rounded,
      color: Color(0xFFFACC15),
      borderColors: [
        Color(0xFFFACC15),
        Color(0xFF38BDF8),
        Color(0xFFFFFFFF),
        Color(0xFFFB923C),
        Color(0xFFFACC15),
      ],
      expPerSecond: 18000,
    ),
    RankTier(
      tier: 11,
      name: 'Espada',
      minLevel: 200000,
      maxLevel: 999999,
      icon: Icons.dark_mode_rounded,
      color: Color(0xFF2DD4BF),
      borderColors: [
        Color(0xFF2DD4BF),
        Color(0xFF0066FF),
        Color(0xFF99F6E4),
        Color(0xFF14B8A6),
        Color(0xFF2DD4BF),
      ],
      expPerSecond: 80000,
    ),
    RankTier(
      tier: 12,
      name: 'Bankai',
      minLevel: 1000000,
      maxLevel: 2499999,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFA78BFA),
      borderColors: [
        Color(0xFFA78BFA),
        Color(0xFFF472B6),
        Color(0xFF38BDF8),
        Color(0xFFFFFFFF),
        Color(0xFFA78BFA),
      ],
      expPerSecond: 180000,
    ),
    RankTier(
      tier: 13,
      name: 'Titan',
      minLevel: 2500000,
      maxLevel: 4999999,
      icon: Icons.whatshot_rounded,
      color: Color(0xFFF87171),
      borderColors: [
        Color(0xFFF87171),
        Color(0xFFFBBF24),
        Color(0xFFDC2626),
        Color(0xFFFFFFFF),
        Color(0xFFF87171),
      ],
      expPerSecond: 350000,
    ),
    RankTier(
      tier: 14,
      name: 'Akatsuki',
      minLevel: 5000000,
      maxLevel: 9999999,
      icon: Icons.cloud_rounded,
      color: Color(0xFFEF4444),
      borderColors: [
        Color(0xFFEF4444),
        Color(0xFFC084FC),
        Color(0xFFFFFFFF),
        Color(0xFFB91C1C),
        Color(0xFFEF4444),
      ],
      expPerSecond: 700000,
    ),
    RankTier(
      tier: 15,
      name: 'Kami-Sama',
      minLevel: 10000000,
      maxLevel: 20999999,
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFF0066FF),
      borderColors: [
        Color(0xFF0066FF),
        Color(0xFF38BDF8),
        Color(0xFFFACC15),
        Color(0xFFFFFFFF),
        Color(0xFF0066FF),
      ],
      expPerSecond: 1400000,
    ),
    RankTier(
      tier: 16,
      name: 'Wibu',
      minLevel: 21000000,
      maxLevel: null,
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF38BDF8),
      borderColors: [
        Color(0xFF0066FF),
        Color(0xFF38BDF8),
        Color(0xFFF472B6),
        Color(0xFFFACC15),
        Color(0xFF34D399),
        Color(0xFFFFFFFF),
        Color(0xFF0066FF),
      ],
      expPerSecond: 2500000,
    ),
  ];

  /// Converts cumulative [totalExp] into current level (starting at 1).
  static int levelForTotalExp(int totalExp) {
    if (totalExp <= 0) return 1;
    return (totalExp ~/ expPerLevel) + 1;
  }

  /// Remaining EXP inside the current level bar (`0..expPerLevel - 1`).
  static int currentLevelExp(int totalExp) {
    if (totalExp <= 0) return 0;
    return totalExp % expPerLevel;
  }

  /// Finds the [RankTier] corresponding to [level].
  static RankTier tierForLevel(int level) {
    final safe = level < 1 ? 1 : level;
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (safe >= tiers[i].minLevel) {
        return tiers[i];
      }
    }
    return tiers.first;
  }

  /// Formats integer with dot thousand separators (e.g. `21000000` -> `21.000.000`).
  static String formatNumber(int value) {
    final raw = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(raw[i]);
    }
    return buf.toString();
  }
}

