import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Wraps an episode card/tile with a Wibuku-style clockwise rounded-rectangle
/// progress border in Nimeva's [AppColors.accentBlue].
class EpisodeProgressBorder extends StatelessWidget {
  final double progress;
  final double borderRadius;
  final double strokeWidth;
  final Widget child;

  const EpisodeProgressBorder({
    super.key,
    required this.progress,
    this.borderRadius = 10.0,
    this.strokeWidth = 2.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _EpisodeProgressBorderPainter(
        progress: progress.clamp(0.0, 1.0),
        borderRadius: borderRadius,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _EpisodeProgressBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double strokeWidth;

  _EpisodeProgressBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(borderRadius),
    );

    final trackPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, trackPaint);

    // Build path starting at top-center clockwise.
    final fullPath = Path()..addRRect(rrect);
    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;
    final drawLength = totalLength * progress;

    // Rounded rect path starts near top-left; offset by ~12.5% to start at top-center.
    final startOffset = totalLength * 0.125;
    final progressPath = Path();

    if (startOffset + drawLength <= totalLength) {
      progressPath.addPath(
        metric.extractPath(startOffset, startOffset + drawLength),
        Offset.zero,
      );
    } else {
      progressPath.addPath(
        metric.extractPath(startOffset, totalLength),
        Offset.zero,
      );
      final remaining = (startOffset + drawLength) - totalLength;
      progressPath.addPath(
        metric.extractPath(0, remaining),
        Offset.zero,
      );
    }

    final activePaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(progressPath, activePaint);
  }

  @override
  bool shouldRepaint(covariant _EpisodeProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
