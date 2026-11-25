import 'package:nini/features/post_analytics/presentation/cubit/analytics_controls_cubit.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/post_analytics/domain/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/common/analytics_controls.dart';

class TotalViewsSection extends StatefulWidget {
  const TotalViewsSection({super.key, required this.reportForPeriod});
  final AnalyticsReportBuilder reportForPeriod;
  @override
  State<TotalViewsSection> createState() => _TotalViewsSectionState();
}

class _TotalViewsSectionState extends State<TotalViewsSection> {
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
      final dates = report.dates;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalyticsSectionHeading(
            title: AppStrings.totalViews,
            period: _chart.state.period,
            onPeriodChanged: (value) => _chart.changePeriod(value),
          ),
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: constraints.maxWidth * .67,
              child: AnalyticsLineChart(
                key: ValueKey(_chart.state.period),
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
                style: AppTextStyles.smallPrint,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ),
        ],
      );
    },
  );
}
