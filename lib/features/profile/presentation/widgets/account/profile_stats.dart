import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    this.postCount = '385',
    this.salesCount = '1,051',
    this.customerCount = '1.5K',
  });

  final String postCount, salesCount, customerCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatisticItem(value: postCount, label: AppStrings.posts),
        ),
        Expanded(
          child: _StatisticItem(value: salesCount, label: AppStrings.sales),
        ),
        Expanded(
          child: _StatisticItem(
            value: customerCount,
            label: AppStrings.customers,
          ),
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
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.statNumber.copyWith(height: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              label,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.statLabel,
            ),
          ),
        ),
      ],
    );
  }
}
