import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_assets/app_assets.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

class ProfilePostsEmptyState extends StatelessWidget {
  const ProfilePostsEmptyState({super.key});

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final illustration = Image.asset(
        AppAssets.profileNoPosts,
        width: (responsive.width * .68).clamp(0.0, 300.0),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Theme.of(context).brightness == Brightness.dark)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -1,
                  0,
                  0,
                  0,
                  255,
                  0,
                  -1,
                  0,
                  0,
                  255,
                  0,
                  0,
                  -1,
                  0,
                  255,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: illustration,
              )
            else
              illustration,
            const SizedBox(height: 28),
            const Text(
              ProfilePostStrings.noPublishedPosts,
              textAlign: TextAlign.center,
              style: AppTextStyles.largeBody,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      );
    },
  );
}
