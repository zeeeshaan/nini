import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    super.key,
    this.name = '',
    this.category = '',
    this.bio = '',
    this.location = '',
  });

  final String name, category, bio, location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          name.isEmpty ? AppStrings.profile : name,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          style: AppTextStyles.profileName.copyWith(height: 1.4),
        ),
        if (category.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            category,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: AppTextStyles.category.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .45),
              height: 1.4,
            ),
          ),
        ],
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            bio,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: AppTextStyles.bio.copyWith(height: 1.6),
          ),
        ],
        if (location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            location,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .6),
            ),
          ),
        ],
      ],
    );
  }
}
