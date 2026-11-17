import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/core/theme/app_colors.dart';
import 'package:nimeva/core/theme/app_typography.dart';
import 'package:nimeva/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('defines correct Modern Monochrome & Azure Blue design tokens', () {
      expect(AppColors.bgPrimary, const Color(0xFF000000));
      expect(AppColors.surfaceCard, const Color(0xFF121212));
      expect(AppColors.surfaceElevated, const Color(0xFF1C1C1E));
      expect(AppColors.borderSubtle, const Color(0xFF26262A));
      expect(AppColors.accentBlue, const Color(0xFF0066FF));
      expect(AppColors.accentAmber, const Color(0xFFFFB800));
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.textSecondary, const Color(0xFFA1A1AA));
      expect(AppColors.textMuted, const Color(0xFF71717A));
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
    test('provides darkTheme configured for Modern Monochrome & Azure Blue palette', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.bgPrimary);
      expect(theme.colorScheme.primary, AppColors.accentBlue);
      expect(theme.colorScheme.surface, AppColors.surfaceCard);
    });
  });
}
