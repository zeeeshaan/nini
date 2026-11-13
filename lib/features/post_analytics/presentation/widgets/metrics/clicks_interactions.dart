import 'package:nini/features/post_analytics/presentation/cubit/analytics_controls_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_analytics/domain/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/common/analytics_controls.dart';

class ClicksInteractionsSection extends StatefulWidget {
  const ClicksInteractionsSection({super.key, required this.reportForPeriod});
  final AnalyticsReportBuilder reportForPeriod;
  @override
  State<ClicksInteractionsSection> createState() =>
      _ClicksInteractionsSectionState();
}

class _ClicksInteractionsSectionState extends State<ClicksInteractionsSection> {
  final _chart = AnalyticsControlsCubit();
  @override
  void dispose() {
    _chart.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AnalyticsControlsCubit, AnalyticsControlsState>(
        bloc: _chart,
        builder: (context, state) {
          final report = widget.reportForPeriod(_chart.state.period);
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
                period: _chart.state.period,
                onPeriodChanged: (value) => _chart.changePeriod(value),
                leftInset: 40,
              ),
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: constraints.maxWidth * .45,
                  child: AnalyticsLineChart(
                    key: ValueKey(_chart.state.period),
                    first: report.clicks,
                    second: report.saves,
                    labels: labels,
                    dates: report.dates,
                    isSample: report.isSample,
                    showFirst: _chart.state.first,
                    showSecond: _chart.state.second,
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
                        color: AppColors.analyticsPurple,
                        selected: _chart.state.first,
                        onTap: () => _chart.toggleFirst(),
                      ),
                      AnalyticsLegend(
                        label: report.isSample
                            ? AppStrings.sampleProducts[1]
                            : AppStrings.savesComments,
                        color: AppColors.analyticsGold,
                        selected: _chart.state.second,
                        onTap: () => _chart.toggleSecond(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}
