import 'package:nini/features/post_analytics/presentation/cubit/analytics_controls_cubit.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/features/post_analytics/presentation/widgets/common/analytics_controls.dart';

class AnalyticsLineChart extends StatefulWidget {
  const AnalyticsLineChart({
    super.key,
    required this.first,
    required this.second,
    required this.labels,
    required this.dates,
    required this.isSample,
    this.area = false,
    this.showFirst = true,
    this.showSecond = true,
    this.firstName = AppStrings.product,
    this.secondName = AppStrings.product,
  });
  final List<double> first, second;
  final List<String> labels;
  final List<DateTime> dates;
  final bool isSample, area, showFirst, showSecond;
  final String firstName, secondName;
  @override
  State<AnalyticsLineChart> createState() => _AnalyticsLineChartState();
}

class _AnalyticsLineChartState extends State<AnalyticsLineChart> {
  final _chart = AnalyticsControlsCubit();
  @override
  void dispose() {
    _chart.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AnalyticsControlsCubit, AnalyticsControlsState>(
    bloc: _chart,
    builder: (context, state) => LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final selected = (_chart.state.selected ?? widget.first.length ~/ 3)
            .clamp(0, widget.first.length - 1);
        final left = widget.area ? 0.0 : 40.0;
        final pointX =
            left +
            (width - left) * selected / math.max(1, widget.first.length - 1);
        void select(Offset offset) => _chart.select(
          (((offset.dx - left) / (width - left)) * (widget.first.length - 1))
              .round()
              .clamp(0, widget.first.length - 1),
        );
        final first = widget.first[selected],
            second = widget.second[selected.clamp(0, widget.second.length - 1)];
        final preview = widget.isSample && _chart.state.selected == null;
        final date = preview
            ? AppStrings.sampleDate
            : analyticsDate(
                widget.dates[(selected *
                        widget.dates.length ~/
                        widget.first.length)
                    .clamp(0, widget.dates.length - 1)],
              );
        return Semantics(
          label: AppStrings.chartHelp(widget.area),
          child: MouseRegion(
            onHover: (event) => select(event.localPosition),
            child: GestureDetector(
              onTapDown: (event) => select(event.localPosition),
              onPanUpdate: (event) => select(event.localPosition),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LinePainter(
                        first: widget.first,
                        second: widget.second,
                        labels: widget.labels,
                        area: widget.area,
                        sample: widget.isSample,
                        selected: selected,
                        showFirst: widget.showFirst,
                        showSecond: widget.showSecond,
                        foreground: Theme.of(context).colorScheme.onSurface,
                        grid: Theme.of(context).dividerColor,
                        fontFamily: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.fontFamily,
                      ),
                    ),
                  ),
                  if (widget.showFirst || widget.showSecond)
                    Positioned(
                      left: (pointX - 65).clamp(
                        left,
                        math.max(left, width - 178),
                      ),
                      top: widget.area ? constraints.maxHeight * .31 : -2,
                      child: IgnorePointer(
                        child: AnalyticsTooltip(
                          date: date,
                          total: preview
                              ? AppStrings.sampleTotal
                              : analyticsNumber(first + second),
                          labels: [
                            if (widget.showFirst) widget.firstName,
                            if (widget.showSecond) widget.secondName,
                          ],
                          values: [
                            if (widget.showFirst)
                              preview
                                  ? AppStrings.sampleFirst
                                  : analyticsNumber(first),
                            if (widget.showSecond)
                              preview
                                  ? AppStrings.sampleSecond
                                  : analyticsNumber(second),
                          ],
                          colors: [
                            if (widget.showFirst) AppColors.analyticsPurple,
                            if (widget.showSecond) AppColors.analyticsGold,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.first,
    required this.second,
    required this.labels,
    required this.area,
    required this.sample,
    required this.selected,
    required this.showFirst,
    required this.showSecond,
    required this.foreground,
    required this.grid,
    this.fontFamily,
  });
  final List<double> first, second;
  final List<String> labels;
  final bool area, sample, showFirst, showSecond;
  final int selected;
  final Color foreground, grid;
  final String? fontFamily;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(area ? 0 : 40, 8, size.width, size.height - 24);
    final highest = [...first, ...second].fold<double>(0, math.max);
    final maxY = sample
        ? math.max(area ? 48.0 : 25000.0, highest * 1.1)
        : math.max(5.0, (highest / 5).ceil() * 5.0);
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: .5)
      ..strokeWidth = .65;
    for (var step = 0; step <= 5; step++) {
      final y = rect.bottom - step * rect.height / 5;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      if (!area) {
        _text(
          canvas,
          maxY >= 1000 && step > 0
              ? AppStrings.persianDigits('${(maxY * step / 5000).round()},000')
              : analyticsNumber(maxY * step / 5),
          Offset(0, y - 6),
        );
      }
    }
    for (var step = 0; step < labels.length; step++) {
      final x = rect.left + step * rect.width / math.max(1, labels.length - 1);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      _text(
        canvas,
        labels[step],
        Offset((x - 13).clamp(0, size.width - 28), rect.bottom + 8),
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..color = grid.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    List<Offset> points(List<double> values) => [
      for (var i = 0; i < values.length; i++)
        Offset(
          rect.left + i * rect.width / math.max(1, values.length - 1),
          rect.bottom - values[i] / maxY * rect.height,
        ),
    ];
    canvas.save();
    canvas.clipRect(rect);
    void draw(List<double> values, Color color, bool dashed) {
      final positions = points(values);
      final curve = _smooth(positions);
      if (area) {
        final fill = Path.from(curve)
          ..lineTo(positions.last.dx, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: .72),
                color.withValues(alpha: .05),
              ],
            ).createShader(rect),
        );
      }
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = area ? .8 : 1.5;
      if (dashed) {
        _dash(canvas, curve, stroke);
      } else {
        canvas.drawPath(curve, stroke);
      }
      final position = positions[selected.clamp(0, positions.length - 1)];
      canvas.drawCircle(position, 3.5, Paint()..color = AppColors.white);
      canvas.drawCircle(
        position,
        3.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    if (showFirst) draw(first, AppColors.analyticsPurple, false);
    if (showSecond) draw(second, AppColors.analyticsGold, !area);
    canvas.restore();
  }

  void _text(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyles.metadata.copyWith(
          color: foreground.withValues(alpha: .7),
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => true;
}

Path _smooth(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 0; i < points.length - 1; i++) {
    final before = points[math.max(0, i - 1)],
        current = points[i],
        next = points[i + 1],
        after = points[math.min(points.length - 1, i + 2)];
    final a = current + (next - before) / 6, b = next - (after - current) / 6;
    path.cubicTo(a.dx, a.dy, b.dx, b.dy, next.dx, next.dy);
  }
  return path;
}

void _dash(Canvas canvas, Path path, Paint paint) {
  for (final metric in path.computeMetrics()) {
    for (var distance = 0.0; distance < metric.length; distance += 7) {
      canvas.drawPath(
        metric.extractPath(distance, math.min(distance + 4, metric.length)),
        paint,
      );
    }
  }
}
