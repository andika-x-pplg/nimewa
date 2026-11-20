import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Clean placeholder widget displayed when anime coverImage or bannerImage is missing or fails to load.
/// Displays an icon and the anime title cleanly centered on a dark surface to prevent blank screens.
class AnimeImagePlaceholder extends StatelessWidget {
  final String title;
  final bool showTitle;
  final double iconSize;
  final double? fontSize;
  final BorderRadius? borderRadius;

  const AnimeImagePlaceholder({
    super.key,
    required this.title,
    this.showTitle = true,
    this.iconSize = 36,
    this.fontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              color: AppColors.accentBlue.withValues(alpha: 0.6),
              size: iconSize,
            ),
            if (showTitle) ...[
              const SizedBox(height: 8),
              Text(
                title.isNotEmpty ? title : 'Nimeva',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: fontSize ?? 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
