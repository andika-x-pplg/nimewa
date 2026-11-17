import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds - Modern Monochrome OLED
  static const Color bgPrimary = Color(0xFF000000);
  static const Color background = Color(0xFF000000);

  // Surfaces
  static const Color surfaceCard = Color(0xFF121212);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1C1C1E);

  // Borders
  static const Color borderSubtle = Color(0xFF26262A);
  static const Color border = Color(0xFF26262A);

  // Accents - Modern Electric / Azure Blue
  static const Color accentBlue = Color(0xFF0066FF);
  static const Color accentPrimary = Color(0xFF0066FF);
  static const Color accentCrimson = Color(0xFF0066FF); // Alias for compatibility
  static const Color accentAmber = Color(0xFFFFB800);
  static const Color amberRating = Color(0xFFFFB800);

  // Text - Pure White & Crisp Neutral Slate
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
}
