import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

import 'package:hywork/core/localization/strings/home_strings.dart';

class HomeProductDetails extends StatelessWidget {
  const HomeProductDetails({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.homePostTitle,
          ),
          const SizedBox(height: 8),
          Text(
            HomeStrings.mobile,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: AppTextStyles.heading.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .3),
            ),
          ),
        ],
      ),
    );
  }
}
