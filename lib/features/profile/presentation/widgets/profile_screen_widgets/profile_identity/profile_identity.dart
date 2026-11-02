import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.responsive});

  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final nameSize = responsive.adaptive<double>(
      compact: 22,
      medium: 26,
      expanded: 28,
    );

    final descriptionSize = responsive.adaptive<double>(
      compact: 13,
      medium: 15,
      expanded: 16,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppStrings.sellerName,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: nameSize,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          AppStrings.shopAndStore,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,

            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppStrings.sellerBio,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: descriptionSize,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
