import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_colors.dart';

class AnalyticsRadarChart extends StatelessWidget {
  const AnalyticsRadarChart({
    super.key,
    required this.first,
    required this.second,
    required this.labels,
    required this.showFirst,
    required this.showSecond,
  });
  final List<double> first, second;
  final List<String> labels;
  final bool showFirst, showSecond;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _RadarPainter(
      first,
      second,
      labels,
      showFirst,
      showSecond,
      Theme.of(context).colorScheme.onSurface,
      Theme.of(context).dividerColor,
      Theme.of(context).textTheme.bodySmall?.fontFamily,
    ),
  );
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(
    this.first,
    this.second,
    this.labels,
    this.showFirst,
    this.showSecond,
    this.foreground,
    this.grid,
    this.fontFamily,
  );
  final String? fontFamily;
  final List<double> first, second;
  final List<String> labels;
  final bool showFirst, showSecond;
  final Color foreground, grid;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero),
        radius = math.min(size.width, size.height) * .37;
    final n = first.length;
    Offset point(int i, double factor) =>
        center +
        Offset(
              math.cos(-math.pi / 2 + 2 * math.pi * i / n),
              math.sin(-math.pi / 2 + 2 * math.pi * i / n),
            ) *
            radius *
            factor;
    Path polygon(List<double> factors) => Path()
      ..addPolygon([for (var i = 0; i < n; i++) point(i, factors[i])], true);
    for (var level = 1; level <= 5; level++) {
      canvas.drawPath(
        polygon(List.filled(n, level / 5)),
        Paint()
          ..color = grid.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6,
      );
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(
        center,
        point(i, 1),
        Paint()
          ..color = grid.withValues(alpha: .5)
          ..strokeWidth = .6,
      );
      final text = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 10,
            fontFamily: fontFamily,
            color: foreground.withValues(alpha: .65),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      text.paint(
        canvas,
        point(i, 1.17) - Offset(text.width / 2, text.height / 2),
      );
    }
    final maxValue = math.max(
      1.0,
      [...first, ...second].fold<double>(0, math.max),
    );
    void draw(List<double> values, Color color) {
      final path = polygon(
        values.map((value) => value / maxValue * .85).toList(),
      );
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: .5));
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9,
      );
    }

    if (showSecond) draw(second, AppColors.analyticsGold);
    if (showFirst) draw(first, AppColors.analyticsPurple);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
