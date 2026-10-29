import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_controls/analytics_controls.dart';

class TotalViewsSection extends StatefulWidget {
  const TotalViewsSection({super.key, required this.reportForPeriod});
  final AnalyticsReportBuilder reportForPeriod;
  @override
  State<TotalViewsSection> createState() => _TotalViewsSectionState();
}

class _TotalViewsSectionState extends State<TotalViewsSection> {
  AnalyticsPeriod _period = AnalyticsPeriod.halfYear;
  @override
  Widget build(BuildContext context) {
    final report = widget.reportForPeriod(_period);
    final dates = report.dates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsSectionHeading(
          title: AppStrings.totalViews,
          period: _period,
          onPeriodChanged: (value) => setState(() => _period = value),
        ),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: constraints.maxWidth * .67,
            child: AnalyticsLineChart(
              key: ValueKey(_period),
              first: report.views,
              second: report.exposures,
              labels: report.isSample
                  ? const [AppStrings.april, AppStrings.may, AppStrings.june]
                  : [
                      PostAnalyticsReport.monthName(dates.first),
                      PostAnalyticsReport.monthName(dates[dates.length ~/ 2]),
                      PostAnalyticsReport.monthName(dates.last),
                    ],
              dates: dates,
              isSample: report.isSample,
              area: true,
              firstName: report.isSample
                  ? AppStrings.product
                  : AppStrings.views,
              secondName: report.isSample
                  ? AppStrings.product
                  : AppStrings.impressions,
            ),
          ),
        ),
        if (!report.isSample)
          AnalyticsSummary(
            value: AppStrings.viewCount(analyticsNumber(report.totalViews)),
            trailing: Text(
              AppStrings.impressionCount(
                analyticsNumber(report.totalImpressions),
              ),
              style: const TextStyle(fontSize: 10),
            ),
          ),
      ],
    );
  }
}
