import 'package:hywork/features/post_analytics/presentation/cubit/analytics_controls_cubit.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/features/post_analytics/domain/post_analytics.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/common/analytics_controls.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class OrdersBookingsSection extends StatefulWidget {
  const OrdersBookingsSection({super.key, required this.report});
  final PostAnalyticsReport report;
  @override
  State<OrdersBookingsSection> createState() => _OrdersBookingsSectionState();
}

class _OrdersBookingsSectionState extends State<OrdersBookingsSection> {
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
      final report = widget.report;
      final today = DateTime.now();
      final labels = report.isSample
          ? AppStrings.sampleWeekdays
          : List.generate(
              7,
              (index) =>
                  AppStrings.weekdayLetters[today
                          .subtract(Duration(days: 6 - index))
                          .weekday -
                      1],
            );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              AppStrings.totalOrdersBookings,
              style: AppTextStyles.pageTitleBold,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 38),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: AppIcon(
                    AppIcons.phone,
                    size: 21,
                    color: AppColors.analyticsOrders,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      report.isSample
                          ? AppStrings.sampleHours
                          : analyticsNumber(report.averageOrders),
                      style: AppTextStyles.analyticsTotal,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    AppStrings.dailyAverage,
                    style: AppTextStyles.metadata.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: .6),
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 38),
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onTapDown: (event) => _chart.select(
                  (event.localPosition.dx / constraints.maxWidth * 7)
                      .floor()
                      .clamp(0, 6),
                ),
                child: SizedBox(
                  height: 88,
                  child: AnalyticsOrdersChart(
                    values: report.dailyOrders,
                    labels: labels,
                  ),
                ),
              ),
            ),
          ),
          if (_chart.state.selected != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${labels[_chart.state.selected!]}: ${analyticsNumber(report.dailyOrders[_chart.state.selected!])} ${report.isSample ? AppStrings.hours : AppStrings.ordersBookings}',
                textAlign: TextAlign.right,
                style: AppTextStyles.helper,
                textDirection: TextDirection.ltr,
              ),
            ),
        ],
      );
    },
  );
}
