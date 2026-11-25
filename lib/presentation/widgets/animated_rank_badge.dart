import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/rank_tier.dart';

/// Displays a rank tier badge with a water-like flowing animated gradient border.
/// Tiers 1-6 use a subtle single-hue flow; Tiers 7-16 use a luxury multi-color
/// flowing border with an outer glow.
class AnimatedRankBadge extends StatefulWidget {
  final RankTier tier;
  final int? currentLevel;
  final bool isActive;
  final bool compact;

  const AnimatedRankBadge({
    super.key,
    required this.tier,
    this.currentLevel,
    this.isActive = false,
    this.compact = false,
  });

  @override
  State<AnimatedRankBadge> createState() => _AnimatedRankBadgeState();
}

class _AnimatedRankBadgeState extends State<AnimatedRankBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isAutomatedTest => WidgetsBinding.instance.runtimeType
      .toString()
      .contains('AutomatedTestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.tier.isLuxury ? 2400 : 4200),
    );
    if (_isAutomatedTest) {
      _controller.value = 0.25;
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedRankBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tier.isLuxury != widget.tier.isLuxury) {
      _controller.duration =
          Duration(milliseconds: widget.tier.isLuxury ? 2400 : 4200);
      if (!_isAutomatedTest) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    final borderWidth = tier.isLuxury ? 2.4 : 1.4;
    final radius = widget.compact ? 12.0 : 16.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;
        return Container(
          padding: EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: SweepGradient(
              colors: tier.borderColors,
              transform: GradientRotation(angle),
            ),
            boxShadow: tier.isLuxury
                ? [
                    BoxShadow(
                      color: tier.color.withValues(alpha: 0.28),
                      blurRadius: 12,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 14,
          vertical: widget.compact ? 6 : 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(radius - borderWidth),
        ),
        child: Row(
          mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Container(
              width: widget.compact ? 28 : 40,
              height: widget.compact ? 28 : 40,
              decoration: BoxDecoration(
                color: tier.color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tier.icon,
                color: tier.color,
                size: widget.compact ? 16 : 22,
              ),
            ),
            SizedBox(width: widget.compact ? 8 : 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tier.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (widget.compact
                                  ? AppTypography.labelLarge
                                  : AppTypography.titleMedium)
                              .copyWith(
                            color: tier.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.currentLevel != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Lv. ${RankCatalog.formatNumber(widget.currentLevel!)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.levelRangeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.compact && widget.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aktif',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

