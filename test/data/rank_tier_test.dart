import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/models/rank_tier.dart';

void main() {
  group('RankCatalog', () {
    test('defines exactly 16 distinct ranks from Ayam (Lv. 1) to Wibu (Lv. 21.000.000+++)', () {
      expect(RankCatalog.tiers.length, equals(16));
      expect(RankCatalog.tiers.first.name, equals('Ayam'));
      expect(RankCatalog.tiers.first.minLevel, equals(1));
      expect(RankCatalog.tiers.first.maxLevel, equals(49));
      expect(RankCatalog.tiers.first.isLuxury, isFalse);

      expect(RankCatalog.tiers[5].isLuxury, isFalse);
      expect(RankCatalog.tiers[6].isLuxury, isTrue);

      expect(RankCatalog.tiers.last.name, equals('Wibu'));
      expect(RankCatalog.tiers.last.minLevel, equals(21000000));
      expect(RankCatalog.tiers.last.maxLevel, isNull);
      expect(RankCatalog.tiers.last.isLuxury, isTrue);

      final names = RankCatalog.tiers.map((t) => t.name).toSet();
      expect(names.length, equals(16));

      final colors = RankCatalog.tiers.map((t) => t.color).toSet();
      expect(colors.length, greaterThanOrEqualTo(15));
    });

    test('computes level, resetting level EXP bar, and tierForLevel accurately', () {
      expect(RankCatalog.levelForTotalExp(0), equals(1));
      expect(RankCatalog.currentLevelExp(0), equals(0));

      expect(RankCatalog.levelForTotalExp(99), equals(1));
      expect(RankCatalog.currentLevelExp(99), equals(99));

      expect(RankCatalog.levelForTotalExp(100), equals(2));
      expect(RankCatalog.currentLevelExp(100), equals(0));

      expect(RankCatalog.tierForLevel(49).name, equals('Ayam'));
      expect(RankCatalog.tierForLevel(50).tier, equals(2));
      expect(RankCatalog.tierForLevel(10000).tier, equals(7));
      expect(RankCatalog.tierForLevel(21000000).name, equals('Wibu'));
      expect(RankCatalog.formatNumber(21000000), equals('21.000.000'));
    });
  });
}

