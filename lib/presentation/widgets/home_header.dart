import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Cinematic Obsidian & Crimson Home Header widget.
/// Displays greeting, prominent username, notification bell button with unread badge,
/// and uppercase initial avatar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.username = 'dikzzz',
    this.greeting = 'Selamat Menonton',
    this.showNotificationBadge = true,
    this.onNotificationTap,
    this.onProfileTap,
  });

  final String username;
  final String? greeting;
  final bool showNotificationBadge;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  String get _initial {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (greeting != null && greeting!.isNotEmpty) ...[
                  Text(
                    greeting!,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  username,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationButton(context),
              const SizedBox(width: 10),
              _buildAvatar(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifikasi',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onNotificationTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                if (showNotificationBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      key: const Key('notification_badge'),
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accentCrimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profil Pengguna',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onProfileTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _initial,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
