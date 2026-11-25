import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_colors/app_colors.dart';

class AnalyticsPolarChart extends StatelessWidget {
  const AnalyticsPolarChart({super.key, required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PolarPainter(values, Theme.of(context).dividerColor),
  );
}

class _PolarPainter extends CustomPainter {
  _PolarPainter(this.values, this.grid);
  final List<double> values;
  final Color grid;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero),
        radius = math.min(size.width, size.height) * .45;
    for (var ring = 1; ring <= 5; ring++) {
      canvas.drawCircle(
        center,
        radius * ring / 5,
        Paint()
          ..color = grid.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6,
      );
    }
    const colors = [
      AppColors.analyticsPurple,
      AppColors.analyticsBlue,
      AppColors.analyticsPink,
      AppColors.analyticsGold,
    ];
    final maxValue = math.max(1.0, values.fold<double>(0, math.max));
    for (var i = 0; i < 4; i++) {
      if (values[i] <= 0) continue;
      final extent = radius * values[i] / maxValue * .92;
      final sector = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: extent),
          -math.pi + i * math.pi / 2,
          math.pi / 2,
          false,
        )
        ..close();
      canvas.drawPath(
        sector,
        Paint()..color = colors[i].withValues(alpha: .55),
      );
      canvas.drawPath(
        sector,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PolarPainter oldDelegate) => true;
}
