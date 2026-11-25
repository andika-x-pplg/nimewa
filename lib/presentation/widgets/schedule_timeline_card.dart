import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/schedule_entry.dart';
import 'anime_image_placeholder.dart';

/// Timeline entry card displaying anime release time, poster, status, and action.
class ScheduleTimelineCard extends StatelessWidget {
  final ScheduleEntry entry;
  final DateTime now;
  final bool isReminded;
  final bool isLastInColumn;
  final bool showTimelineRail;
  final VoidCallback onTap;
  final VoidCallback? onReminderToggle;

  const ScheduleTimelineCard({
    super.key,
    required this.entry,
    required this.now,
    this.isReminded = false,
    this.isLastInColumn = false,
    this.showTimelineRail = true,
    required this.onTap,
    this.onReminderToggle,
  });

  @override
  Widget build(BuildContext context) {
    final status = entry.statusAt(now);
    final rawStatusText = entry.formatStatusText(now);
    final statusText = (!showTimelineRail &&
            status == ScheduleReleaseStatus.delayedOrHiatus &&
            !rawStatusText.contains(entry.formattedTime()))
        ? '${entry.formattedTime()} · $rawStatusText'
        : rawStatusText;

    if (!showTimelineRail) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLastInColumn ? 0 : 12),
        child: _buildCard(status, statusText),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineRail(
            timeLabel: entry.formattedTime(),
            status: status,
            isLastInColumn: isLastInColumn,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLastInColumn ? 0 : 12),
              child: _buildCard(status, statusText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ScheduleReleaseStatus status, String statusText) {
    final statusTextColor = _statusTextColor(status);
    final episodeLabel = entry.format.isNotEmpty &&
            entry.format.toUpperCase() != 'TV'
        ? 'Episode ${entry.episodeNumber} · ${entry.format}'
        : 'Episode ${entry.episodeNumber}';

    return Semantics(
      button: true,
      label: '${entry.title}, $episodeLabel, $statusText',
      child: Material(
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPoster(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            episodeLabel,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (entry.hasVideoAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accentBlue.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.accentBlue
                                      .withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'Tersedia',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: statusTextColor,
                          fontWeight:
                              status == ScheduleReleaseStatus.delayedOrHiatus
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _buildTrailingAction(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final radius = BorderRadius.circular(8);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: 68,
        height: 96,
        child: entry.posterUrl.trim().isEmpty
            ? AnimeImagePlaceholder(
                title: entry.title,
                showTitle: false,
                iconSize: 24,
                borderRadius: radius,
              )
            : Image.network(
                entry.posterUrl,
                width: 68,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    AnimeImagePlaceholder(
                  title: entry.title,
                  showTitle: false,
                  iconSize: 24,
                  borderRadius: radius,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTrailingAction(ScheduleReleaseStatus status) {
    if (status == ScheduleReleaseStatus.released) {
      final hasVideo = entry.hasVideoAvailable;
      return Semantics(
        button: true,
        label: hasVideo
            ? 'Tonton ${entry.title}'
            : 'Lihat detail ${entry.title}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: hasVideo
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                          color: AppColors.accentBlue,
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      toggled: isReminded,
      label: isReminded
          ? 'Hapus pengingat ${entry.title}'
          : 'Ingatkan ${entry.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onReminderToggle,
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                isReminded
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 22,
                color: isReminded
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusTextColor(ScheduleReleaseStatus status) {
    switch (status) {
      case ScheduleReleaseStatus.delayedOrHiatus:
        return AppColors.accentAmber;
      case ScheduleReleaseStatus.released:
        final elapsed = now.difference(entry.airingAt);
        if (elapsed.inMinutes < 60) {
          return AppColors.accentBlue;
        }
        return AppColors.textSecondary;
      case ScheduleReleaseStatus.upcoming:
        return AppColors.textSecondary;
    }
  }
}

class _TimelineRail extends StatelessWidget {
  final String timeLabel;
  final ScheduleReleaseStatus status;
  final bool isLastInColumn;

  const _TimelineRail({
    required this.timeLabel,
    required this.status,
    required this.isLastInColumn,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    switch (status) {
      case ScheduleReleaseStatus.released:
        dotColor = AppColors.accentBlue;
      case ScheduleReleaseStatus.upcoming:
        dotColor = AppColors.textMuted;
      case ScheduleReleaseStatus.delayedOrHiatus:
        dotColor = AppColors.accentAmber;
    }

    return SizedBox(
      width: 52,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            timeLabel,
            maxLines: 1,
            style: AppTypography.labelLarge.copyWith(
              color: status == ScheduleReleaseStatus.delayedOrHiatus
                  ? AppColors.accentAmber
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.bgPrimary,
                width: 1.5,
              ),
            ),
          ),
          if (!isLastInColumn)
            Expanded(
              child: Container(
                width: 1.5,
                margin: const EdgeInsets.only(top: 4),
                color: AppColors.borderSubtle,
              ),
            ),
        ],
      ),
    );
  }
}
