import 'package:nini/features/post_analytics/presentation/cubit/analytics_controls_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/common/analytics_controls.dart';

class ImpressionsSection extends StatefulWidget {
  const ImpressionsSection({super.key, required this.reportForPeriod});
  final AnalyticsReportBuilder reportForPeriod;
  @override
  State<ImpressionsSection> createState() => _ImpressionsSectionState();
}

class _ImpressionsSectionState extends State<ImpressionsSection> {
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
              ? AppStrings.sampleProducts
              : const [
                  AppStrings.home,
                  AppStrings.search,
                  AppStrings.profile,
                  AppStrings.other,
                ];
          const colors = [
            AppColors.analyticsPurple,
            AppColors.analyticsBlue,
            AppColors.analyticsPink,
            AppColors.analyticsGold,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnalyticsSectionHeading(
                title: AppStrings.impressions,
                period: _chart.state.period,
                onPeriodChanged: (value) => _chart.changePeriod(value),
              ),
              LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onTap: () => _chart.toggleTooltip(),
                  child: SizedBox(
                    height: constraints.maxWidth * .70,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnalyticsPolarChart(values: report.channels),
                        ),
                        if (_chart.state.tooltip)
                          Positioned(
                            top: 0,
                            left: (constraints.maxWidth - 176) / 2,
                            child: IgnorePointer(
                              child: AnalyticsTooltip(
                                date: report.isSample
                                    ? AppStrings.sampleDate
                                    : analyticsDate(report.dates.last),
                                total: report.isSample
                                    ? AppStrings.sampleTotal
                                    : analyticsNumber(report.totalImpressions),
                                labels: report.isSample
                                    ? const [
                                        AppStrings.product,
                                        AppStrings.product,
                                        AppStrings.product,
                                        AppStrings.product,
                                      ]
                                    : labels,
                                values: report.isSample
                                    ? const [
                                        AppStrings.sampleFirst,
                                        AppStrings.sampleSecond,
                                        AppStrings.sampleThird,
                                        AppStrings.sampleFourth,
                                      ]
                                    : report.channels
                                          .map(analyticsNumber)
                                          .toList(),
                                colors: colors,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              style: AppTextStyles.micro,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AnalyticsSummary(
                value: report.isSample
                    ? AppStrings.sampleRevenue
                    : AppStrings.impressionCount(
                        analyticsNumber(report.totalImpressions),
                      ),
                sample: report.isSample,
              ),
            ],
          );
        },
      );
}
