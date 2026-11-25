import 'package:flutter/material.dart';

import 'package:nini/core/animations/screen_entrance/screen_entrance.dart';

/// Fades, lifts, and gently scales content without changing its layout size.
/// Delays are capped so even long grids finish their entrance within 760 ms.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    this.index = 0,
    this.distance = 20,
    required this.child,
  }) : assert(index >= 0);

  final int index;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = ScreenEntranceScope.maybeOf(context);
    if (parent == null || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final delay = index.clamp(0, 6) * 45;
    final progress = parent.drive(
      CurveTween(
        curve: Interval(
          delay / ScreenEntrance.duration.inMilliseconds,
          (delay + 480) / ScreenEntrance.duration.inMilliseconds,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return FadeTransition(
      opacity: progress,
      child: AnimatedBuilder(
        animation: progress,
        child: RepaintBoundary(child: child),
        builder: (context, child) {
          final remaining = 1 - progress.value;
          return IgnorePointer(
            ignoring: progress.value < 0.15,
            child: Transform.translate(
              offset: Offset(0, distance * remaining),
              child: Transform.scale(
                scale: 1 - 0.015 * remaining,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
