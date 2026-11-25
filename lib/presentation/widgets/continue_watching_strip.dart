import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/my_list_entry.dart';
import 'anime_image_placeholder.dart';

/// Compact horizontal strip of up to 5 active `Watching` anime on HomeScreen.
class ContinueWatchingStrip extends StatelessWidget {
  final List<MyListEntry> entries;
  final VoidCallback onSeeAllTap;
  final ValueChanged<MyListEntry> onEntryTap;
  final ValueChanged<MyListEntry>? onPlayTap;

  const ContinueWatchingStrip({
    super.key,
    required this.entries,
    required this.onSeeAllTap,
    required this.onEntryTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = min(entries.length, 5);
    final visible = entries.take(visibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Continue watching',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAllTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.accentBlue,
                ),
                child: Text(
                  'Lihat semua',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = visible[index];
              return _buildCard(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(MyListEntry entry) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onEntryTap(entry),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 248,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 96,
                  color: AppColors.surfaceElevated,
                  child: entry.posterUrl.trim().isEmpty
                      ? AnimeImagePlaceholder(title: entry.title, showTitle: false)
                      : Image.network(
                          entry.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => AnimeImagePlaceholder(
                            title: entry.title,
                            showTitle: false,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                entry.totalEpisodes > 0
                                    ? 'Ep ${entry.watchedEpisode}/${entry.totalEpisodes}'
                                    : 'Ep ${entry.watchedEpisode}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${entry.completedPercent}%',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.progressFraction,
                            minHeight: 5,
                            backgroundColor: AppColors.borderSubtle,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (entry.hasVideoAvailable && onPlayTap != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => onPlayTap!(entry),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentBlue.withValues(alpha: 0.16),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.accentBlue,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
