import 'package:nini/features/post_analytics/presentation/cubit/analytics_controls_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_analytics/domain/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/common/analytics_controls.dart';

class AverageTimeViewedSection extends StatefulWidget {
  const AverageTimeViewedSection({super.key, required this.reportForPeriod});
  final AnalyticsReportBuilder reportForPeriod;
  @override
  State<AverageTimeViewedSection> createState() =>
      _AverageTimeViewedSectionState();
}

class _AverageTimeViewedSectionState extends State<AverageTimeViewedSection> {
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
    builder: (context, state) {
      final report = widget.reportForPeriod(_chart.state.period);
      final selected = (_chart.state.selected ?? 0).clamp(
        0,
        report.averageSeconds.length - 1,
      );
      final average = report.averageWatch;
      final formatted = average >= 60
          ? AppStrings.averageMinutes(analyticsNumber(average / 60))
          : AppStrings.averageSeconds(analyticsNumber(average));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalyticsSectionHeading(
            title: AppStrings.averageTimeViewed,
            period: _chart.state.period,
            onPeriodChanged: (value) =>
                _chart.changePeriod(value, resetSelection: true),
          ),
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapUp: (_) => _chart.next(report.averageSeconds.length),
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
                        showFirst: _chart.state.first,
                        showSecond: _chart.state.second,
                      ),
                    ),
                    Positioned(
                      top: 42,
                      left: (constraints.maxWidth - 176) / 2,
                      child: IgnorePointer(
                        child: AnalyticsTooltip(
                          date: report.isSample && !_chart.state.inspecting
                              ? AppStrings.sampleDate
                              : analyticsDate(
                                  report.dates[selected % report.dates.length],
                                ),
                          total: report.isSample && !_chart.state.inspecting
                              ? AppStrings.sampleTotal
                              : AppStrings.seconds(
                                  analyticsNumber(
                                    report.averageSeconds[selected],
                                  ),
                                ),
                          labels: [
                            if (_chart.state.first)
                              report.isSample
                                  ? AppStrings.product
                                  : AppStrings.thisPeriod,
                            if (_chart.state.second)
                              report.isSample
                                  ? AppStrings.product
                                  : AppStrings.previousPeriod,
                          ],
                          values: [
                            if (_chart.state.first)
                              report.isSample && !_chart.state.inspecting
                                  ? AppStrings.sampleFirst
                                  : AppStrings.seconds(
                                      analyticsNumber(
                                        report.averageSeconds[selected],
                                      ),
                                    ),
                            if (_chart.state.second)
                              report.isSample && !_chart.state.inspecting
                                  ? AppStrings.sampleSecond
                                  : AppStrings.seconds(
                                      analyticsNumber(
                                        report.previousSeconds[selected],
                                      ),
                                    ),
                          ],
                          colors: [
                            if (_chart.state.first) AppColors.analyticsPurple,
                            if (_chart.state.second) AppColors.analyticsGold,
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
                  color: AppColors.analyticsPurple,
                  selected: _chart.state.first,
                  onTap: () => _chart.toggleFirst(),
                ),
                AnalyticsLegend(
                  label: report.isSample
                      ? AppStrings.sampleProducts[1]
                      : AppStrings.previousPeriod,
                  color: AppColors.analyticsGold,
                  selected: _chart.state.second,
                  onTap: () => _chart.toggleSecond(),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
