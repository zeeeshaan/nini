import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_controls/analytics_controls.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class OrdersBookingsSection extends StatefulWidget {
  const OrdersBookingsSection({super.key, required this.report});
  final PostAnalyticsReport report;
  @override
  State<OrdersBookingsSection> createState() => _OrdersBookingsSectionState();
}

class _OrdersBookingsSectionState extends State<OrdersBookingsSection> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  AppStrings.dailyAverage,
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .6),
                  ),
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
              onTapDown: (event) => setState(
                () => _selected =
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
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${labels[_selected!]}: ${analyticsNumber(report.dailyOrders[_selected!])} ${report.isSample ? AppStrings.hours : AppStrings.ordersBookings}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
      ],
    );
  }
}
