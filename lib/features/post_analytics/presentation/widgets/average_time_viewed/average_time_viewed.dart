import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_controls/analytics_controls.dart';

class AverageTimeViewedSection extends StatefulWidget {
  const AverageTimeViewedSection({super.key, required this.reportForPeriod});
  final AnalyticsReportBuilder reportForPeriod;
  @override
  State<AverageTimeViewedSection> createState() =>
      _AverageTimeViewedSectionState();
}

class _AverageTimeViewedSectionState extends State<AverageTimeViewedSection> {
  AnalyticsPeriod _period = AnalyticsPeriod.halfYear;
  bool _first = true, _second = true;
  int _selected = 0;
  bool _inspecting = false;
  @override
  Widget build(BuildContext context) {
    final report = widget.reportForPeriod(_period);
    final selected = _selected.clamp(0, report.averageSeconds.length - 1);
    final average = report.averageWatch;
    final formatted = average >= 60
        ? AppStrings.averageMinutes(analyticsNumber(average / 60))
        : AppStrings.averageSeconds(analyticsNumber(average));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsSectionHeading(
          title: AppStrings.averageTimeViewed,
          period: _period,
          onPeriodChanged: (value) => setState(() {
            _period = value;
            _selected = 0;
            _inspecting = false;
          }),
        ),
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapUp: (_) => setState(() {
              _selected = (_selected + 1) % report.averageSeconds.length;
              _inspecting = true;
            }),
            child: SizedBox(
              height: constraints.maxWidth * .66,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnalyticsRadarChart(
                      first: report.averageSeconds,
                      second: report.previousSeconds,
                      labels: report.isSample
                          ? const [
                              AppStrings.january,
                              AppStrings.february,
                              AppStrings.march,
                              AppStrings.april,
                              AppStrings.may,
                              AppStrings.june,
                              AppStrings.july,
                            ]
                          : report.dates
                                .map(PostAnalyticsReport.monthName)
                                .toList(),
                      showFirst: _first,
                      showSecond: _second,
                    ),
                  ),
                  Positioned(
                    top: 42,
                    left: (constraints.maxWidth - 176) / 2,
                    child: IgnorePointer(
                      child: AnalyticsTooltip(
                        date: report.isSample && !_inspecting
                            ? AppStrings.sampleDate
                            : analyticsDate(
                                report.dates[selected % report.dates.length],
                              ),
                        total: report.isSample && !_inspecting
                            ? AppStrings.sampleTotal
                            : AppStrings.seconds(
                                analyticsNumber(
                                  report.averageSeconds[selected],
                                ),
                              ),
                        labels: [
                          if (_first)
                            report.isSample
                                ? AppStrings.product
                                : AppStrings.thisPeriod,
                          if (_second)
                            report.isSample
                                ? AppStrings.product
                                : AppStrings.previousPeriod,
                        ],
                        values: [
                          if (_first)
                            report.isSample && !_inspecting
                                ? AppStrings.sampleFirst
                                : AppStrings.seconds(
                                    analyticsNumber(
                                      report.averageSeconds[selected],
                                    ),
                                  ),
                          if (_second)
                            report.isSample && !_inspecting
                                ? AppStrings.sampleSecond
                                : AppStrings.seconds(
                                    analyticsNumber(
                                      report.previousSeconds[selected],
                                    ),
                                  ),
                        ],
                        colors: [
                          if (_first) AnalyticsColors.purple,
                          if (_second) AnalyticsColors.gold,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnalyticsSummary(
          value: report.isSample ? AppStrings.sampleRevenue : formatted,
          sample: report.isSample,
          trailing: Wrap(
            spacing: 7,
            children: [
              AnalyticsLegend(
                label: report.isSample
                    ? AppStrings.sampleProducts[0]
                    : AppStrings.thisPeriod,
                color: AnalyticsColors.purple,
                selected: _first,
                onTap: () => setState(() => _first = !_first),
              ),
              AnalyticsLegend(
                label: report.isSample
                    ? AppStrings.sampleProducts[1]
                    : AppStrings.previousPeriod,
                color: AnalyticsColors.gold,
                selected: _second,
                onTap: () => setState(() => _second = !_second),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
