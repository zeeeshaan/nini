import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppStrings.sellerName,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.profileName.copyWith(height: 1.4),
        ),
        const SizedBox(height: 2),
        Text(
          AppStrings.shopAndStore,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.category.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: .45),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppStrings.sellerBio,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.bio.copyWith(height: 1.6),
        ),
      ],
    );
  }
}
