import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../utils/fa.dart';
import 'user_screen.dart';

const _ink = AppColors.deepBlack;
const _muted = AppColors.midGray;
const _white = AppColors.pureWhite;

/// Chart series colors. Charts are the one place besides file-type icons
/// that uses hue: identity needs color, and black / gray fail the
/// lightness band and chroma floor for data marks. Violet + amber pass
/// every categorical check (lightness, chroma, CVD and normal-vision
/// separation, 3:1 contrast) on the white page. Single-series charts use
/// violet; the second series is also dashed, so identity never rests on
/// color alone.
const _series1 = Color(0xFF7B6FD6);
const _series2 = Color(0xFFC98500);

/// Pie slices, in this fixed order around the ring (violet, amber, aqua,
/// blue, magenta): every neighbour pair, including last-to-first, passes
/// the CVD and normal-vision checks. Aqua and magenta sit under 3:1 on
/// white, so every slice is also labeled and listed with its value.
const _slices = [
  _series1,
  _series2,
  Color(0xFF1BAF7A),
  Color(0xFF2A78D6),
  Color(0xFFE87BA4),
];

/// Periods the charts can cover, in months.
const _periods = [3, 6, 12];

/// Impression sources, in no particular order; the chart ranks them.
const _sources = ['صفحه اصلی', 'جستجو', 'پروفایل', 'هشتگ‌ها', 'اشتراک‌گذاری'];

/// One Jalali month of sample statistics for the post.
class _Month {
  const _Month({
    required this.label,
    required this.views,
    required this.clicks,
    required this.interactions,
    required this.avgSeconds,
  });

  final String label;
  final int views;
  final int clicks;
  final int interactions;
  final int avgSeconds;
}

/// Sample statistics for the last 24 months, oldest first, ending with the
/// current Jalali month. Deterministic, so the page looks the same on
/// every visit (there is no backend yet).
List<_Month> _sampleMonths(DateTime now) {
  final rnd = math.Random(7);
  final (_, month, _) = toJalali(now);
  return [
    for (var i = 23; i >= 0; i--)
      () {
        final m = (month - 1 - i) % 12;
        final t = 23 - i;
        final season = math.sin((t - 4) * math.pi / 6);
        final growth = 1 + t * 0.03;
        final views = ((3200 + 500 * season) * growth + rnd.nextInt(400))
            .round();
        final clicks = (views * (0.22 + rnd.nextDouble() * 0.06)).round();
        return _Month(
          label: kJalaliMonths[m],
          views: views,
          clicks: clicks,
          interactions: (clicks * (0.45 + rnd.nextDouble() * 0.2)).round(),
          avgSeconds: 36 + t ~/ 3 + (6 * season).round() + rnd.nextInt(8),
        );
      }(),
  ];
}

/// "Analytics" for a single service post: the post, then views, clicks and
/// interactions, average time viewed, impressions by source and bookings
/// per weekday. Each card has its own period menu, shows its headline
/// number against the previous period and can switch to a table.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.now});

  /// "Today", for tests; defaults to [DateTime.now].
  final DateTime? now;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final _all = _sampleMonths(widget.now ?? DateTime.now());

  /// Months shown per card, keyed by card title; 6 until changed.
  final _periods = <String, int>{};

  int _period(String card) => _periods[card] ?? 6;

  List<_Month> _current(int months) => _all.sublist(_all.length - months);
  List<_Month> _previous(int months) =>
      _all.sublist(_all.length - 2 * months, _all.length - months);

  static int _sum(List<_Month> ms, int Function(_Month) f) =>
      ms.fold(0, (a, m) => a + f(m));

  static double _avgSeconds(List<_Month> ms) =>
      ms.fold(0, (a, m) => a + m.avgSeconds) / ms.length;

  /// A card wired to its own period menu.
  Widget _card(
    String title,
    Widget Function(int months, List<_Month> cur, List<_Month> prev) build,
  ) {
    final months = _period(title);
    final card = build(months, _current(months), _previous(months));
    return _PeriodScope(
      value: months,
      onChanged: (m) => setState(() => _periods[title] = m),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  const _PostSummary(),
                  _card(
                    'کل بازدیدها',
                    (_, cur, prev) => _ChartCard(
                      title: 'کل بازدیدها',
                      headline: faAmount(_sum(cur, (m) => m.views)),
                      change: _change(
                        _sum(cur, (m) => m.views),
                        _sum(prev, (m) => m.views),
                      ),
                      table: _Table(
                        columns: const ['ماه', 'بازدید'],
                        rows: [
                          for (final m in cur) [m.label, faAmount(m.views)],
                        ],
                      ),
                      chart: _TrendChart(
                        months: cur,
                        series: [
                          _Series('بازدید', _series1, [
                            for (final m in cur) m.views,
                          ]),
                        ],
                      ),
                    ),
                  ),
                  _card(
                    'کلیک‌ها / تعامل‌ها',
                    (_, cur, prev) => _ChartCard(
                      title: 'کلیک‌ها / تعامل‌ها',
                      headline: faAmount(_sum(cur, (m) => m.clicks)),
                      headlineUnit: 'کلیک',
                      change: _change(
                        _sum(cur, (m) => m.clicks),
                        _sum(prev, (m) => m.clicks),
                      ),
                      legend: const [
                        _Series('کلیک', _series1, []),
                        _Series('تعامل', _series2, [], dashed: true),
                      ],
                      table: _Table(
                        columns: const ['ماه', 'کلیک', 'تعامل'],
                        rows: [
                          for (final m in cur)
                            [
                              m.label,
                              faAmount(m.clicks),
                              faAmount(m.interactions),
                            ],
                        ],
                      ),
                      chart: _TrendChart(
                        months: cur,
                        series: [
                          _Series('کلیک', _series1, [
                            for (final m in cur) m.clicks,
                          ]),
                          _Series('تعامل', _series2, [
                            for (final m in cur) m.interactions,
                          ], dashed: true),
                        ],
                      ),
                    ),
                  ),
                  _card(
                    'میانگین زمان مشاهده',
                    (_, cur, prev) => _ChartCard(
                      title: 'میانگین زمان مشاهده',
                      headline: faDigits(_avgSeconds(cur).round()),
                      headlineUnit: 'ثانیه',
                      change: _change(_avgSeconds(cur), _avgSeconds(prev)),
                      legend: const [
                        _Series('این دوره', _series1, []),
                        _Series('دوره قبل', _series2, []),
                      ],
                      table: _Table(
                        columns: const ['ماه', 'این دوره', 'دوره قبل'],
                        rows: [
                          for (var i = 0; i < cur.length; i++)
                            [
                              cur[i].label,
                              faDigits(cur[i].avgSeconds),
                              faDigits(prev[i].avgSeconds),
                            ],
                        ],
                      ),
                      chart: _TimeRadar(current: cur, previous: prev),
                    ),
                  ),
                  _card('نمایش‌ها', (_, cur, prev) {
                    final impressions = _impressionsBySource(
                      _sum(cur, (m) => m.views),
                    );
                    return _ChartCard(
                      title: 'نمایش‌ها',
                      headline: faAmount(
                        impressions.fold(0, (a, s) => a + s.$2),
                      ),
                      headlineUnit: 'نمایش',
                      change: _change(
                        _sum(cur, (m) => m.views),
                        _sum(prev, (m) => m.views),
                      ),
                      chartHeight: 300,
                      table: _Table(
                        columns: const ['منبع', 'نمایش'],
                        rows: [
                          for (final (s, v) in impressions) [s, faAmount(v)],
                        ],
                      ),
                      chart: _SourcePie(items: impressions),
                    );
                  }),
                  _card('کل سفارش‌ها / رزروها', (months, _, _) {
                    final bookings = _bookingsByWeekday(months);
                    final perDay = bookings.fold(0, (a, b) => a + b) / 7;
                    return _ChartCard(
                      title: 'کل سفارش‌ها / رزروها',
                      headline: faDigits(perDay.round()),
                      headlineUnit: 'رزرو · میانگین روزانه',
                      table: _Table(
                        columns: const ['روز', 'رزرو'],
                        rows: [
                          for (var i = 0; i < 7; i++)
                            [kFaWeekdaysLong[i], faDigits(bookings[i])],
                        ],
                      ),
                      chart: _MonthBars(
                        labels: kFaWeekdays,
                        tooltipLabels: kFaWeekdaysLong,
                        values: bookings,
                        unit: 'رزرو',
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Impressions split across [_sources], ranked highest first.
  List<(String, int)> _impressionsBySource(int views) {
    const shares = [0.34, 0.27, 0.18, 0.13, 0.08];
    final total = (views * 3.4).round();
    return [
      for (var i = 0; i < _sources.length; i++)
        (_sources[i], (total * shares[i]).round()),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  /// Bookings per weekday (Saturday first) over the period.
  List<int> _bookingsByWeekday(int months) {
    const weights = [1.1, 1.0, 0.95, 1.05, 1.2, 0.85, 0.6];
    return [for (final w in weights) (w * 2.1 * months * 4.3).round()];
  }

  static double? _change(num current, num previous) =>
      previous == 0 ? null : (current - previous) / previous * 100;
}

/// Full Persian weekday names, Saturday first, for tooltips and tables.
const kFaWeekdaysLong = [
  'شنبه',
  'یکشنبه',
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
];

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, color: _ink, size: 28),
          ),
          const Text(
            'آمار و تحلیل',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The post being measured: author and its cover photo.
class _PostSummary extends StatelessWidget {
  const _PostSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            ProfileAvatar(size: 30, ring: true),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'پایپ‌مستر',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'تعمیر شیر آب چکه‌کن',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.asset(
              ProfileImages.works.first,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.surfaceOnLight,
                child: Icon(Icons.image_outlined, color: _muted, size: 40),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hands a card its period and setter, for the menu in its header.
class _PeriodScope extends InheritedWidget {
  const _PeriodScope({
    required this.value,
    required this.onChanged,
    required super.child,
  });

  final int value;
  final ValueChanged<int> onChanged;

  static _PeriodScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PeriodScope>();

  @override
  bool updateShouldNotify(_PeriodScope old) => old.value != value;
}

/// "۶ ماه ▾": the card's period.
class _PeriodMenu extends StatelessWidget {
  const _PeriodMenu({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'بازه زمانی',
      color: _white,
      position: PopupMenuPosition.under,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final p in _periods)
          CheckedPopupMenuItem(
            value: p,
            checked: p == value,
            child: Text('${faDigits(p)} ماه اخیر'),
          ),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
        decoration: BoxDecoration(
          border: Border.all(color: _ink.withValues(alpha: 0.75)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${faDigits(value)} ماه',
              style: const TextStyle(color: _ink, fontSize: 12),
            ),
            const Icon(Icons.arrow_drop_down, color: _ink, size: 20),
          ],
        ),
      ),
    );
  }
}

/// A named series of values, one per x position.
class _Series {
  const _Series(this.label, this.color, this.values, {this.dashed = false});

  final String label;
  final Color color;
  final List<int> values;
  final bool dashed;
}

/// Titled card: headline number with its change against the previous
/// period, an optional legend, then the chart — or its table.
class _ChartCard extends StatefulWidget {
  const _ChartCard({
    required this.title,
    required this.headline,
    required this.chart,
    required this.table,
    this.headlineUnit,
    this.change,
    this.legend = const [],
    this.chartHeight = 180,
  });

  final String title;
  final String headline;
  final String? headlineUnit;

  /// Percent change against the previous period, or null to hide it.
  final double? change;
  final List<_Series> legend;
  final Widget chart;
  final Widget table;
  final double chartHeight;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  bool _asTable = false;

  @override
  Widget build(BuildContext context) {
    final period = _PeriodScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (period != null)
                    _PeriodMenu(
                      value: period.value,
                      onChanged: period.onChanged,
                    ),
                  IconButton(
                    onPressed: () => setState(() => _asTable = !_asTable),
                    tooltip: _asTable ? 'نمایش نمودار' : 'نمایش جدول',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _asTable ? Icons.show_chart : Icons.table_rows_outlined,
                      color: _ink,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: _Headline(
                  value: widget.headline,
                  unit: widget.headlineUnit,
                  change: widget.change,
                ),
              ),
              if (widget.legend.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Legend(series: widget.legend),
              ],
              const SizedBox(height: 14),
              _asTable
                  ? widget.table
                  : SizedBox(height: widget.chartHeight, child: widget.chart),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big number, its unit, and "▲ ٪۱۲٫۴ نسبت به دوره قبل" in ink: the arrow
/// and sign carry direction, not color.
class _Headline extends StatelessWidget {
  const _Headline({required this.value, this.unit, this.change});

  final String value;
  final String? unit;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (unit != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              unit!,
              style: const TextStyle(color: _muted, fontSize: 11.5),
            ),
          ),
        if (change != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _ink,
                  size: 13,
                ),
                Text(
                  '٪${faDigits(change.abs().toStringAsFixed(1)).replaceAll('.', '٫')}'
                  ' نسبت به دوره قبل',
                  style: const TextStyle(color: _ink, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Series keys as short strokes (dashed where the line is), with labels.
class _Legend extends StatelessWidget {
  const _Legend({required this.series});

  final List<_Series> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final s in series)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 8,
                child: CustomPaint(
                  painter: _KeyPainter(color: s.color, dashed: s.dashed),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                s.label,
                style: const TextStyle(color: _ink, fontSize: 11.5),
              ),
            ],
          ),
      ],
    );
  }
}

class _KeyPainter extends CustomPainter {
  const _KeyPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), paint);
      return;
    }
    for (var x = 1.0; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 4, size.width - 1), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_KeyPainter old) =>
      old.color != color || old.dashed != dashed;
}

/// Compact axis numbers: ۱۲ هزار, ۳٫۴ هزار, ۸۰۰.
String _compact(num v) {
  if (v >= 1000) {
    final k = v / 1000;
    final text = k >= 10 ? k.round().toString() : k.toStringAsFixed(1);
    return '${faDigits(text.replaceAll('.0', '')).replaceAll('.', '٫')} هزار';
  }
  return faDigits(v.round());
}

/// Shared axis styling: horizontal grid only, no border, compact numbers
/// on the left, [labels] under each x position (every other one when
/// crowded).
FlTitlesData _titles(List<String> labels) {
  final step = labels.length > 7 ? 2 : 1;
  const none = AxisTitles(sideTitles: SideTitles(showTitles: false));
  return FlTitlesData(
    topTitles: none,
    rightTitles: none,
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (v, meta) {
          if (v == meta.max) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(
              _compact(v),
              style: const TextStyle(color: _muted, fontSize: 9.5),
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        reservedSize: 24,
        getTitlesWidget: (v, meta) {
          final i = v.round();
          if (v != i || i < 0 || i >= labels.length) {
            return const SizedBox.shrink();
          }
          if ((labels.length - 1 - i) % step != 0) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(
              labels[i],
              style: const TextStyle(color: _muted, fontSize: 9.5),
            ),
          );
        },
      ),
    ),
  );
}

final _grid = FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) =>
      const FlLine(color: AppColors.divider, strokeWidth: 1),
);

const _tooltipText = TextStyle(color: _ink, fontSize: 11);
const _tooltipValue = TextStyle(
  color: _ink,
  fontSize: 11.5,
  fontWeight: FontWeight.w700,
);

/// Line chart over months; a single series also gets a soft area fill.
/// Touching shows a crosshair and one tooltip listing every series.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.months, required this.series});

  final List<_Month> months;
  final List<_Series> series;

  @override
  Widget build(BuildContext context) {
    final area = series.length == 1;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: _grid,
          borderData: FlBorderData(show: false),
          titlesData: _titles([for (final m in months) m.label]),
          lineBarsData: [
            for (final s in series)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < s.values.length; i++)
                    FlSpot(i.toDouble(), s.values[i].toDouble()),
                ],
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                color: s.color,
                barWidth: 2,
                dashArray: s.dashed ? [6, 4] : null,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: area,
                  color: s.color.withValues(alpha: 0.16),
                ),
              ),
          ],
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (bar, indexes) => [
              for (final _ in indexes)
                TouchedSpotIndicatorData(
                  const FlLine(color: _muted, strokeWidth: 1),
                  FlDotData(
                    getDotPainter: (_, _, bar, _) => FlDotCirclePainter(
                      radius: 4,
                      color: bar.color ?? _ink,
                      strokeWidth: 2,
                      strokeColor: _white,
                    ),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => _white,
              tooltipBorder: const BorderSide(color: AppColors.divider),
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 160,
              getTooltipItems: (spots) => [
                for (var k = 0; k < spots.length; k++)
                  LineTooltipItem(
                    k == 0 ? '${months[spots[k].x.round()].label}\n' : '',
                    _tooltipText,
                    textDirection: TextDirection.rtl,
                    children: [
                      TextSpan(
                        text: '— ',
                        style: TextStyle(
                          color: series[spots[k].barIndex].color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: faAmount(spots[k].y.round()),
                        style: _tooltipValue,
                      ),
                      TextSpan(text: ' ${series[spots[k].barIndex].label}'),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-series vertical bars, 4px rounded tops on the baseline; touching
/// a bar shows its label and value.
class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.labels,
    required this.values,
    required this.unit,
    this.tooltipLabels,
  });

  final List<String> labels;
  final List<int> values;
  final String unit;

  /// Longer names for the tooltip; defaults to [labels].
  final List<String>? tooltipLabels;

  @override
  Widget build(BuildContext context) {
    final width = values.length > 7 ? 10.0 : 16.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BarChart(
        BarChartData(
          minY: 0,
          gridData: _grid,
          borderData: FlBorderData(show: false),
          titlesData: _titles(labels),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    color: _series1,
                    width: width,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _white,
              tooltipBorder: const BorderSide(color: AppColors.divider),
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${(tooltipLabels ?? labels)[group.x]}\n',
                _tooltipText,
                textDirection: TextDirection.rtl,
                children: [
                  TextSpan(
                    text: faDigits(rod.toY.round()),
                    style: _tooltipValue,
                  ),
                  TextSpan(text: ' $unit'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Average seconds per month on a radar, one spoke per month: this period
/// against the same months of the previous one (amber, lighter fill).
class _TimeRadar extends StatelessWidget {
  const _TimeRadar({required this.current, required this.previous});

  final List<_Month> current;
  final List<_Month> previous;

  @override
  Widget build(BuildContext context) {
    RadarDataSet set(List<_Month> ms, Color color, {double fill = 0.2}) =>
        RadarDataSet(
          dataEntries: [
            for (final m in ms) RadarEntry(value: m.avgSeconds.toDouble()),
          ],
          fillColor: color.withValues(alpha: fill),
          borderColor: color,
          borderWidth: 2,
          entryRadius: 2.5,
        );
    // A radar needs at least three spokes; a 3-month period has exactly
    // three.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            // Invisible zeros: fl_chart scales a radar from its smallest
            // value, which would blow small differences out of proportion.
            RadarDataSet(
              dataEntries: [
                for (final _ in current) const RadarEntry(value: 0),
              ],
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 0,
              entryRadius: 0,
            ),
            set(previous, _series2, fill: 0.08),
            set(current, _series1),
          ],
          radarShape: RadarShape.polygon,
          radarBackgroundColor: Colors.transparent,
          radarBorderData: const BorderSide(color: AppColors.divider),
          gridBorderData: const BorderSide(color: AppColors.divider),
          tickBorderData: const BorderSide(color: AppColors.divider),
          tickCount: 3,
          // fl_chart prints ticks in Latin digits; values are in the table.
          ticksTextStyle: const TextStyle(
            color: Colors.transparent,
            fontSize: 1,
          ),
          titleTextStyle: const TextStyle(color: _muted, fontSize: 10),
          titlePositionPercentageOffset: 0.12,
          getTitle: (i, _) => RadarChartTitle(text: current[i].label),
          radarTouchData: RadarTouchData(enabled: false),
        ),
      ),
    );
  }
}

/// Impressions by source as a donut: slices keep a fixed color per
/// source, each labeled with its share; tapping one shows its source and
/// value in the middle. The legend repeats every value.
class _SourcePie extends StatefulWidget {
  const _SourcePie({required this.items});

  final List<(String, int)> items;

  @override
  State<_SourcePie> createState() => _SourcePieState();
}

class _SourcePieState extends State<_SourcePie> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final total = items.fold(0, (a, e) => a + e.$2);
    // Color follows the source, not its rank.
    Color colorOf(String source) => _slices[_sources.indexOf(source)];
    final touched = _touched;
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 46,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final i = response?.touchedSection?.touchedSectionIndex;
                      if (!event.isInterestedForInteractions) return;
                      setState(
                        () => _touched = (i == null || i < 0) ? null : i,
                      );
                    },
                  ),
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].$2.toDouble(),
                        color: colorOf(items[i].$1),
                        radius: i == touched ? 58 : 52,
                        title:
                            '٪${faDigits((items[i].$2 * 100 / total).round())}',
                        titleStyle: const TextStyle(
                          color: _ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                        // Labels sit just outside the ring, in ink.
                        titlePositionPercentageOffset: 1.32,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    touched == null
                        ? _compact(total)
                        : _compact(items[touched].$2),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    touched == null ? 'کل' : items[touched].$1,
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final (source, value) in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorOf(source),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$source ${_compact(value)}',
                    style: const TextStyle(color: _ink, fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Plain table of what a chart draws.
class _Table extends StatelessWidget {
  const _Table({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, {bool head = false, bool first = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            text,
            textAlign: first ? TextAlign.start : TextAlign.end,
            style: TextStyle(
              color: head ? _muted : _ink,
              fontSize: 11.5,
              fontWeight: head ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
    return Table(
      border: const TableBorder(
        horizontalInside: BorderSide(color: AppColors.divider),
      ),
      children: [
        TableRow(
          children: [
            for (var i = 0; i < columns.length; i++)
              cell(columns[i], head: true, first: i == 0),
          ],
        ),
        for (final r in rows)
          TableRow(
            children: [
              for (var i = 0; i < r.length; i++) cell(r[i], first: i == 0),
            ],
          ),
      ],
    );
  }
}
