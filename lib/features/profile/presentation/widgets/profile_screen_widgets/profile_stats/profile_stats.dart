import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatisticItem(value: '385', label: AppStrings.posts),
        ),
        Expanded(
          child: _StatisticItem(value: '1,051', label: AppStrings.sales),
        ),
        Expanded(
          child: _StatisticItem(value: '1.5K', label: AppStrings.customers),
        ),
      ],
    );
  }
}

class _StatisticItem extends StatelessWidget {
  const _StatisticItem({required this.value, required this.label});

  final String value;
  final String label;

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
              style: AppTextStyles.statNumber.copyWith(height: 1.2),
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
              style: AppTextStyles.statLabel,
            ),
          ),
        ),
      ],
    );
  }
}
