import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nini/core/animations/staggered_animation/staggered_animation.dart';
import 'package:nini/core/localization/strings/auth_strings.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/shared/widgets/app_loader/app_loader.dart';

import 'splash_brand.dart';

/// Fit the reference on phones and larger displays; short windows can scroll.
class SplashContent extends StatelessWidget {
  const SplashContent({super.key, this.status});

  final Widget? status;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = math
          .min(constraints.maxWidth / 390, constraints.maxHeight / 700)
          .clamp(0.6, 1.25)
          .toDouble();
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SplashBrand(scale: scale),
                    SizedBox(height: 18 * scale),
                    StaggeredEntrance(
                      index: 2,
                      child:
                          status ??
                          Semantics(
                            label: AuthStrings.loading,
                            liveRegion: true,
                            child: AppLoader(
                              size: 24 * scale,
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
