import 'dart:math' as math;

import 'package:nini/core/theme/app_text_styles.dart';

import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_colors.dart';

class AnalyticsOrdersChart extends StatelessWidget {
  const AnalyticsOrdersChart({
    super.key,
    required this.values,
    required this.labels,
  });
  final List<double> values;
  final List<String> labels;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _OrdersPainter(
      values,
      labels,
      Theme.of(context).colorScheme.onSurface,
      Theme.of(context).textTheme.bodySmall?.fontFamily,
    ),
  );
}

class _OrdersPainter extends CustomPainter {
  _OrdersPainter(this.values, this.labels, this.foreground, this.fontFamily);
  final String? fontFamily;
  final List<double> values;
  final List<String> labels;
  final Color foreground;
  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(0, 0, size.width, size.height - 24);
    final maxValue = math.max(1.0, values.fold<double>(0, math.max));
    final step = size.width / 7, width = step - 7;
    for (var i = 0; i < 7; i++) {
      final x = i * step + 3.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, width, plot.height),
          const Radius.circular(7),
        ),
        Paint()..color = AppColors.analyticsOrders.withValues(alpha: .23),
      );
      final height = values[i] / maxValue * plot.height;
      if (height > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, plot.bottom - height, width, height),
            const Radius.circular(7),
          ),
          Paint()..color = AppColors.analyticsOrders,
        );
      }
      final text = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: AppTextStyles.compactBody.copyWith(
            fontFamily: fontFamily,
            color: foreground.withValues(alpha: .65),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(x + width / 2 - text.width / 2, plot.bottom + 7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrdersPainter oldDelegate) => true;
}
