import 'package:flutter/material.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/localization/auth_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/shared/widgets/app_logo/app_logo.dart';

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
            AuthStrings.brand,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 40 * scale,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}
