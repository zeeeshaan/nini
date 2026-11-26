import 'package:flutter/material.dart';

import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    this.postCount = '—',
    this.salesCount = '—',
    this.customerCount = '—',
    this.salesLabel = ProfileScreenStrings.sales,
    this.customerLabel = ProfileScreenStrings.customers,
  });

  final String postCount, salesCount, customerCount;
  final String salesLabel, customerLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatisticItem(value: postCount, label: ProfileScreenStrings.posts),
        ),
        Expanded(
          child: _StatisticItem(value: salesCount, label: salesLabel),
        ),
        Expanded(
          child: _StatisticItem(value: customerCount, label: customerLabel),
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
              AppStrings.persianDigits(value),
              textDirection: TextDirection.ltr,
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
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              style: AppTextStyles.statLabel,
            ),
          ),
        ),
      ],
    );
  }
}
