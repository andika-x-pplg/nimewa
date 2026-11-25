import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/my_list_entry.dart';
import 'anime_image_placeholder.dart';

/// Card displaying a saved, watching, or completed anime entry with
/// episode progress bar, completion/remaining percentages, Play/Detail action,
/// and a menu to edit progress, change status, or delete.
class MyListAnimeCard extends StatelessWidget {
  final MyListEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final ValueChanged<MyListStatus>? onStatusChanged;
  final VoidCallback? onEditProgress;
  final VoidCallback? onDelete;

  const MyListAnimeCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onPlayTap,
    this.onStatusChanged,
    this.onEditProgress,
    this.onDelete,
  });

  String _subtitleLine() {
    if (entry.currentEpisodeTitle != null &&
        entry.currentEpisodeTitle!.trim().isNotEmpty) {
      return entry.currentEpisodeTitle!.trim();
    }
    if (!entry.hasVideoAvailable) {
      return 'Tersimpan · Tonton di platform resmi';
    }
    return switch (entry.status) {
      MyListStatus.watching => 'Sedang ditonton',
      MyListStatus.saved => 'Belum mulai ditonton',
      MyListStatus.completed => 'Selesai ditonton',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${entry.title}, ${entry.progressSummaryText}, ${entry.percentSummaryText}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPoster(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _subtitleLine(),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildTrailingAction(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.progressSummaryText,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.progressFraction,
                          minHeight: 6,
                          backgroundColor: AppColors.borderSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            entry.status == MyListStatus.completed
                                ? AppColors.accentBlue
                                : (entry.hasVideoAvailable
                                    ? AppColors.accentBlue
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.percentSummaryText,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onStatusChanged != null ||
                              onEditProgress != null ||
                              onDelete != null)
                            _buildActionMenu(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 68,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: entry.posterUrl.trim().isEmpty
            ? AnimeImagePlaceholder(title: entry.title, showTitle: false)
            : Image.network(
                entry.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    AnimeImagePlaceholder(title: entry.title, showTitle: false),
              ),
      ),
    );
  }

  Widget _buildTrailingAction() {
    final canPlay = entry.hasVideoAvailable && onPlayTap != null;
    if (canPlay) {
      return Semantics(
        button: true,
        label: 'Putar ${entry.title}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('my_list_play_button_${entry.canonicalKey}'),
            onTap: onPlayTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.16),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.accentBlue,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildActionMenu() {
    return SizedBox(
      width: 44,
      height: 44,
      child: PopupMenuButton<String>(
        key: Key('my_list_menu_button_${entry.canonicalKey}'),
        tooltip: 'Opsi daftar',
        color: AppColors.surfaceElevated,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEditProgress?.call();
              break;
            case 'watching':
              onStatusChanged?.call(MyListStatus.watching);
              break;
            case 'saved':
              onStatusChanged?.call(MyListStatus.saved);
              break;
            case 'completed':
              onStatusChanged?.call(MyListStatus.completed);
              break;
            case 'delete':
              onDelete?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          if (onEditProgress != null)
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text(
                'Atur Episode',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          if (onStatusChanged != null && entry.status != MyListStatus.watching)
            const PopupMenuItem<String>(
              value: 'watching',
              child: Text(
                'Pindah ke Watching',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          if (onStatusChanged != null && entry.status != MyListStatus.saved)
            const PopupMenuItem<String>(
              value: 'saved',
              child: Text(
                'Pindah ke Saved',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          if (onStatusChanged != null && entry.status != MyListStatus.completed)
            const PopupMenuItem<String>(
              value: 'completed',
              child: Text(
                'Tandai Selesai (Completed)',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          if (onDelete != null)
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                'Hapus dari My List',
                style: TextStyle(
                  color: Color(0xFFFF5A5F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

