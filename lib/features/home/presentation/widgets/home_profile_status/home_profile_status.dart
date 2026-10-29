import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

class HomeProfileStats extends StatelessWidget {
  const HomeProfileStats({super.key, required this.responsive});

  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final valueSize = responsive.adaptive<double>(
      compact: 23,
      medium: 28,
      expanded: 32,
    );

    final labelSize = responsive.adaptive<double>(
      compact: 13,
      medium: 16,
      expanded: 18,
    );

    return Row(
      children: [
        Expanded(
          child: _StatisticItem(
            value: '۳۸۵',
            label: AppStrings.posts,
            valueSize: valueSize,
            labelSize: labelSize,
          ),
        ),
        Expanded(
          child: _StatisticItem(
            value: '۱٬۰۵۱',
            label: AppStrings.sales,
            valueSize: valueSize,
            labelSize: labelSize,
          ),
        ),
        Expanded(
          child: _StatisticItem(
            value: '۱٫۵ هزار',
            label: AppStrings.customers,
            valueSize: valueSize,
            labelSize: labelSize,
          ),
        ),
      ],
    );
  }
}

class _StatisticItem extends StatelessWidget {
  const _StatisticItem({
    required this.value,
    required this.label,
    required this.valueSize,
    required this.labelSize,
  });

  final String value;
  final String label;
  final double valueSize;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w400,

                height: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
