import 'package:nini/core/localization/app_string/app_string.dart';

enum AnalyticsPeriod {
  month(1, AppStrings.oneMonth),
  quarter(3, AppStrings.threeMonths),
  halfYear(6, AppStrings.sixMonths),
  year(12, AppStrings.twelveMonths);

  const AnalyticsPeriod(this.months, this.label);
  final int months;
  final String label;
}

enum AnalyticsEventType { view, impression, interaction, watch, order }

class PostAnalyticsEvent {
  const PostAnalyticsEvent({
    required this.id,
    required this.postId,
    required this.type,
    required this.at,
    this.value = 1,
    this.source = 'other',
  });
  final String id, postId, source;
  final AnalyticsEventType type;
  final DateTime at;
  final double value;
  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'type': type.name,
    'at': at.toUtc().toIso8601String(),
    'value': value,
    'source': source,
  };
  factory PostAnalyticsEvent.fromJson(Map<String, dynamic> json) =>
      PostAnalyticsEvent(
        id: json['id'] as String,
        postId: json['postId'] as String,
        type: AnalyticsEventType.values.byName(json['type'] as String),
        at: DateTime.parse(json['at'] as String).toLocal(),
        value: (json['value'] as num).toDouble(),
        source: json['source'] as String,
      );
}

class PostAnalyticsReport {
  const PostAnalyticsReport({
    required this.isSample,
    required this.dates,
    required this.views,
    required this.exposures,
    required this.clicks,
    required this.saves,
    required this.averageSeconds,
    required this.previousSeconds,
    required this.channels,
    required this.dailyOrders,
    this.measuredAverageSeconds,
  });
  final bool isSample;
  final List<DateTime> dates;
  final List<double> views,
      exposures,
      clicks,
      saves,
      averageSeconds,
      previousSeconds,
      channels,
      dailyOrders;
  final double? measuredAverageSeconds;
  double get totalViews => _sum(views);
  double get totalInteractions => _sum(clicks) + _sum(saves);
  double get totalImpressions => _sum(channels);
  double get averageWatch =>
      measuredAverageSeconds ??
      (averageSeconds.isEmpty
          ? 0
          : _sum(averageSeconds) / averageSeconds.length);
  double get averageOrders => _sum(dailyOrders) / 7;
  bool get hasActivity =>
      totalViews +
          totalInteractions +
          totalImpressions +
          _sum(averageSeconds) +
          _sum(dailyOrders) >
      0;
  static double _sum(List<double> values) =>
      values.fold(0, (sum, value) => sum + value);
  static String monthName(DateTime date) => const [
    AppStrings.january,
    AppStrings.february,
    AppStrings.march,
    AppStrings.april,
    AppStrings.may,
    AppStrings.june,
    AppStrings.july,
    AppStrings.august,
    AppStrings.september,
    AppStrings.october,
    AppStrings.november,
    AppStrings.december,
  ][date.month - 1];

  factory PostAnalyticsReport.fromEvents(
    List<PostAnalyticsEvent> events,
    AnalyticsPeriod period,
    DateTime now,
  ) {
    final dates = List.generate(
      period.months,
      (index) => DateTime(now.year, now.month - period.months + index + 1),
    );
    final start = dates.first;
    final previousStart = DateTime(start.year, start.month - period.months);
    final views = List<double>.filled(period.months, 0),
        exposures = List<double>.filled(period.months, 0);
    final clicks = List<double>.filled(period.months, 0),
        saves = List<double>.filled(period.months, 0);
    final watch = List<double>.filled(period.months, 0),
        watchSessions = List.generate(period.months, (_) => <String>{});
    final previous = List<double>.filled(period.months, 0),
        previousSessions = List.generate(period.months, (_) => <String>{});
    final channels = List<double>.filled(4, 0),
        orders = List<double>.filled(7, 0);
    final today = DateTime(now.year, now.month, now.day);
    for (final event in events) {
      if (event.at.isAfter(now)) continue;
      final monthIndex =
          (event.at.year - start.year) * 12 + event.at.month - start.month;
      if (monthIndex >= 0 && monthIndex < period.months) {
        switch (event.type) {
          case AnalyticsEventType.view:
            views[monthIndex] += event.value;
          case AnalyticsEventType.impression:
            exposures[monthIndex] += event.value;
            final channel = const [
              'home',
              'search',
              'profile',
              'other',
            ].indexOf(event.source);
            channels[channel < 0 ? 3 : channel] += event.value;
          case AnalyticsEventType.interaction:
            if (event.source == 'save' || event.source == 'comment') {
              saves[monthIndex] += event.value;
            } else {
              clicks[monthIndex] += event.value;
            }
          case AnalyticsEventType.watch:
            watch[monthIndex] += event.value;
            watchSessions[monthIndex].add(
              event.source == 'other' ? event.id : event.source,
            );
          case AnalyticsEventType.order:
            break;
        }
      }
      if (event.type == AnalyticsEventType.watch &&
          !event.at.isBefore(previousStart) &&
          event.at.isBefore(start)) {
        final index =
            (event.at.year - previousStart.year) * 12 +
            event.at.month -
            previousStart.month;
        previous[index] += event.value;
        previousSessions[index].add(
          event.source == 'other' ? event.id : event.source,
        );
      }
      if (event.type == AnalyticsEventType.order) {
        final age = today
            .difference(DateTime(event.at.year, event.at.month, event.at.day))
            .inDays;
        if (age >= 0 && age < 7) orders[6 - age] += event.value;
      }
    }
    return PostAnalyticsReport(
      isSample: false,
      dates: dates,
      views: views,
      exposures: exposures,
      clicks: clicks,
      saves: saves,
      averageSeconds: List.generate(
        period.months,
        (index) => watchSessions[index].isEmpty
            ? 0
            : watch[index] / watchSessions[index].length,
      ),
      previousSeconds: List.generate(
        period.months,
        (index) => previousSessions[index].isEmpty
            ? 0
            : previous[index] / previousSessions[index].length,
      ),
      channels: channels,
      dailyOrders: orders,
      measuredAverageSeconds:
          watchSessions.expand((sessions) => sessions).toSet().isEmpty
          ? 0
          : _sum(watch) /
                watchSessions.expand((sessions) => sessions).toSet().length,
    );
  }

  /// Reference fixtures are restricted to sample posts and marked in the UI.
  factory PostAnalyticsReport.sample(AnalyticsPeriod period) {
    const purple = [
      0,
      3,
      2,
      2,
      18,
      21,
      26,
      13,
      4,
      29,
      34,
      12,
      39,
      5,
      12,
      32,
      19,
      38,
      27,
      40,
      22,
      43,
      28,
      37,
      35,
      28,
      31,
      33,
      20,
      8,
      0,
      15,
      19,
      11,
      3,
      0,
      4,
      6,
      1,
      0,
    ];
    const gold = [
      0,
      7,
      4,
      1,
      1,
      2,
      7,
      26,
      29,
      12,
      2,
      0,
      0,
      18,
      28,
      8,
      7,
      23,
      36,
      35,
      19,
      29,
      37,
      36,
      31,
      7,
      12,
      31,
      27,
      25,
      23,
      22,
      18,
      13,
      8,
      8,
      8,
      8,
      4,
      0,
    ];
    final factor = period.months / 6;
    return PostAnalyticsReport(
      isSample: true,
      dates: List.generate(6, (index) => DateTime(2023, 4 + index)),
      views: purple.map((value) => value * factor).toList(),
      exposures: gold.map((value) => value * factor).toList(),
      clicks: [
        2000,
        5000,
        15000,
        15000,
        11000,
        9500,
        12500,
        14500,
        17000,
        18000,
        17500,
        12000,
      ].map((value) => value * factor).toList(),
      saves: [
        10000,
        8500,
        6000,
        13000,
        18000,
        11500,
        11500,
        12000,
        19000,
        22000,
        21500,
        17000,
      ].map((value) => value * factor).toList(),
      averageSeconds: [
        50,
        45,
        48,
        57,
        69,
        46,
        40,
      ].map((v) => v * factor).toList(),
      previousSeconds: [
        35,
        35,
        72,
        50,
        46,
        62,
        43,
      ].map((v) => v * factor).toList(),
      channels: [45, 58, 70, 88].map((v) => v * factor).toList(),
      dailyOrders: [0, 1, 3, 7, 5, 8, 5],
    );
  }
}
