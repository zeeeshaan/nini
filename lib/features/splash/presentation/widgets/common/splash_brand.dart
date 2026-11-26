import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/animations/staggered_animation/staggered_animation.dart';
import 'package:hywork/core/localization/strings/splash_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/shared/widgets/app_logo/app_logo.dart';

class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      StaggeredEntrance(
        index: 0,
        child: AppLogo(size: 112 * scale, color: AppColors.white),
      ),
      SizedBox(height: 28 * scale),
      StaggeredEntrance(
        index: 1,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            SplashStrings.brand,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.scaledSplashBrand(scale)
                .copyWith(color: AppColors.white),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ],
  );
}
