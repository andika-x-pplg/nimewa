import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_colors.dart';
import 'package:nimeva/core/theme/app_typography.dart';
import 'package:nimeva/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('defines correct Obsidian & Crimson design tokens', () {
      expect(AppColors.bgPrimary, const Color(0xFF0B0D13));
      expect(AppColors.surfaceCard, const Color(0xFF141824));
      expect(AppColors.surfaceElevated, const Color(0xFF1D2333));
      expect(AppColors.borderSubtle, const Color(0xFF252D40));
      expect(AppColors.accentCrimson, const Color(0xFFE50914));
      expect(AppColors.accentAmber, const Color(0xFFFFB703));
      expect(AppColors.textPrimary, const Color(0xFFF8FAFC));
      expect(AppColors.textSecondary, const Color(0xFF94A3B8));
      expect(AppColors.textMuted, const Color(0xFF64748B));
    });
  });

  group('AppTypography', () {
    test('defines standard typography styles with high contrast', () {
      expect(AppTypography.headlineMedium.color, AppColors.textPrimary);
      expect(AppTypography.headlineMedium.fontWeight, FontWeight.bold);

      expect(AppTypography.titleLarge.color, AppColors.textPrimary);
      expect(AppTypography.titleMedium.color, AppColors.textPrimary);

      expect(AppTypography.bodyMedium.color, AppColors.textPrimary);
      expect(AppTypography.bodySmall.color, AppColors.textSecondary);
      expect(AppTypography.labelSmall.color, AppColors.textMuted);
    });
  });

  group('AppTheme', () {
    test('provides darkTheme configured for Obsidian & Crimson palette', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.bgPrimary);
      expect(theme.colorScheme.primary, AppColors.accentCrimson);
      expect(theme.colorScheme.surface, AppColors.surfaceCard);
    });
  });
}
