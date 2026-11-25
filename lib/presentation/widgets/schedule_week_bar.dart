import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/schedule_entry.dart';

/// Rolling Sunday-to-Saturday weekly selector bar with month/timezone info.
class ScheduleWeekBar extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDate;
  final DateTime today;
  final Set<String> reminderDateKeys;
  final ValueChanged<DateTime> onDaySelected;

  const ScheduleWeekBar({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.today,
    this.reminderDateKeys = const {},
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedKey = ScheduleDateHelper.dateKey(selectedDate);
    final todayKey = ScheduleDateHelper.dateKey(today);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                ScheduleDateHelper.monthYearHeader(selectedDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                ScheduleDateHelper.gmtOffsetLabel(today),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: _WeekDayCell(
                  day: days[i],
                  isSelected: ScheduleDateHelper.dateKey(days[i]) == selectedKey,
                  isToday: ScheduleDateHelper.dateKey(days[i]) == todayKey,
                  hasReminder: reminderDateKeys.contains(
                    ScheduleDateHelper.dateKey(days[i]),
                  ),
                  onTap: () => onDaySelected(days[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool hasReminder;
  final VoidCallback onTap;

  const _WeekDayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasReminder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = ScheduleDateHelper.shortDayLabel(day);
    final monthLabel = ScheduleDateHelper.shortMonthLabel(day.month);
    final semanticsParts = <String>[
      '$dayLabel ${day.day} $monthLabel',
      if (isToday) 'Hari ini',
      if (hasReminder) 'Ada pengingat',
    ];

    final Color dotColor;
    if (isSelected) {
      dotColor = Colors.white;
    } else if (hasReminder) {
      dotColor = AppColors.accentAmber;
    } else {
      dotColor = AppColors.accentBlue;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsParts.join(', '),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentBlue : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? AppColors.accentBlue : AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  maxLines: 1,
                  style: AppTypography.titleMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 5,
                  child: (isToday || hasReminder)
                      ? Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
