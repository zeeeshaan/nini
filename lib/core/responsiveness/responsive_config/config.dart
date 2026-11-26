import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:foldable/foldable.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';

class ResponsiveConfig extends StatelessWidget {
  const ResponsiveConfig({super.key, required this.child});

  final Widget child;

  static const Size designSize = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      child: FoldableProvider(
        bridgeMode: DisplayFeatureBridgeMode.none,
        child: child,
      ),
    );
  }

  static Widget materialAppBuilder(BuildContext context, Widget? child) {
    return ResponsiveBreakpoints.builder(
      child: child ?? const SizedBox.shrink(),
      breakpoints: const [
        Breakpoint(start: 0, end: 599, name: 'COMPACT'),
        Breakpoint(
          start: AppResponsive.mediumBreakpoint,
          end: 839,
          name: 'MEDIUM',
        ),
        Breakpoint(
          start: AppResponsive.expandedBreakpoint,
          end: double.infinity,
          name: 'EXPANDED',
        ),
      ],
    );
  }
}
