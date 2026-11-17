import 'package:flutter/material.dart';
import 'package:nimeva/core/theme/app_colors.dart';
import 'package:nimeva/core/theme/app_typography.dart';

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem({
    required this.label,
    required this.icon,
  });
}

/// Custom Bottom Navigation Bar following the Obsidian & Crimson aesthetic.
/// Features 5 navigation tabs: Home, Explore, Jadwal, My list, and Profile.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = [
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: 'Explore', icon: Icons.explore_rounded),
    _NavItem(label: 'Jadwal', icon: Icons.calendar_month_rounded),
    _NavItem(label: 'My list', icon: Icons.bookmark_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('custom_bottom_nav_container'),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;
              final color = isActive ? AppColors.accentBlue : AppColors.textMuted;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: item.label,
                  child: InkResponse(
                    onTap: () => onTap(index),
                    containedInkWell: true,
                    highlightShape: BoxShape.rectangle,
                    splashColor: AppColors.accentBlue.withValues(alpha: 0.12),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: color,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: color,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (isActive)
                            Container(
                              key: Key('active_indicator_$index'),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.accentBlue,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
