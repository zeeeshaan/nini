import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_controls/analytics_controls.dart';

class ClicksInteractionsSection extends StatefulWidget {
  const ClicksInteractionsSection({super.key, required this.reportForPeriod});
  final AnalyticsReportBuilder reportForPeriod;
  @override
  State<ClicksInteractionsSection> createState() =>
      _ClicksInteractionsSectionState();
}

class _ClicksInteractionsSectionState extends State<ClicksInteractionsSection> {
  AnalyticsPeriod _period = AnalyticsPeriod.halfYear;
  bool _first = true, _second = true;
  @override
  Widget build(BuildContext context) {
    final report = widget.reportForPeriod(_period);
    final labels = report.isSample
        ? const [
            AppStrings.april,
            AppStrings.may,
            AppStrings.june,
            AppStrings.july,
            AppStrings.august,
            AppStrings.september,
          ]
        : report.dates.map(PostAnalyticsReport.monthName).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsSectionHeading(
          title: AppStrings.clicksInteractions,
          period: _period,
          onPeriodChanged: (value) => setState(() => _period = value),
          leftInset: 40,
        ),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: constraints.maxWidth * .45,
            child: AnalyticsLineChart(
              key: ValueKey(_period),
              first: report.clicks,
              second: report.saves,
              labels: labels,
              dates: report.dates,
              isSample: report.isSample,
              showFirst: _first,
              showSecond: _second,
              firstName: report.isSample
                  ? AppStrings.product
                  : AppStrings.likesShares,
              secondName: report.isSample
                  ? AppStrings.product
                  : AppStrings.savesComments,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: AnalyticsSummary(
            value: report.isSample
                ? AppStrings.sampleRevenue
                : AppStrings.interactionCount(
                    analyticsNumber(report.totalInteractions),
                  ),
            sample: report.isSample,
            trailing: Wrap(
              spacing: 7,
              children: [
                AnalyticsLegend(
                  label: report.isSample
                      ? AppStrings.sampleProducts[0]
                      : AppStrings.likesShares,
                  color: AnalyticsColors.purple,
                  selected: _first,
                  onTap: () => setState(() => _first = !_first),
                ),
                AnalyticsLegend(
                  label: report.isSample
                      ? AppStrings.sampleProducts[1]
                      : AppStrings.savesComments,
                  color: AnalyticsColors.gold,
                  selected: _second,
                  onTap: () => setState(() => _second = !_second),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
