import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';

import 'package:hywork/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';

// dart format width=100

/// Preserves the physical hinge layout on foldable devices.
class DashboardFoldLayout extends StatelessWidget {
  const DashboardFoldLayout({
    super.key,
    this.divider,
    required this.constraints,
    required this.child,
    required this.itemBuilder,
  });

  final Rect? divider;
  final BoxConstraints constraints;
  final Widget child;
  final Widget Function(BuildContext, DashboardTab) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final bounds = divider ?? _findAndroidDivider(context);

    if (bounds == null || !constraints.hasBoundedWidth) {
      return child;
    }

    return _split(
          context,
          bounds,
          constraints.maxWidth,
          constraints.maxHeight,
          Directionality.of(context),
        ) ??
        child;
  }

  Widget? _split(
    BuildContext context,
    Rect divider,
    double availableWidth,
    double availableHeight,
    TextDirection textDirection,
  ) {
    final isVertical =
        divider.top <= 1 &&
        divider.bottom >= availableHeight - 1 &&
        divider.left > 0 &&
        divider.right < availableWidth;

    if (!isVertical) return null;

    const clearance = 8.0;

    final leftWidth = (divider.left - clearance)
        .clamp(0.0, availableWidth)
        .toDouble();

    final rightStart = (divider.right + clearance)
        .clamp(0.0, availableWidth)
        .toDouble();

    final rightWidth = availableWidth - rightStart;
    final gapWidth = availableWidth - leftWidth - rightWidth;

    final isRtl = textDirection == TextDirection.ltr;

    final leftTabs = isRtl
        ? [DashboardTab.profile, DashboardTab.search, DashboardTab.create]
        : [DashboardTab.home, DashboardTab.cart];

    final rightTabs = isRtl
        ? [DashboardTab.cart, DashboardTab.home]
        : [DashboardTab.create, DashboardTab.search, DashboardTab.profile];

    // Hinge bounds represent physical left and right panes.
    if (leftWidth < leftTabs.length * 56 ||
        rightWidth < rightTabs.length * 56) {
      return null;
    }

    return Row(
      textDirection: TextDirection.ltr,
      children: [
        SizedBox(
          width: leftWidth,
          child: Row(
            textDirection: TextDirection.ltr,
            children: [for (final tab in leftTabs) itemBuilder(context, tab)],
          ),
        ),
        SizedBox(width: gapWidth),
        SizedBox(
          width: rightWidth,
          child: Row(
            textDirection: TextDirection.ltr,
            children: [for (final tab in rightTabs) itemBuilder(context, tab)],
          ),
        ),
      ],
    );
  }

  Rect? _findAndroidDivider(BuildContext context) {
    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }

    final origin = renderObject.localToGlobal(Offset.zero);

    for (final feature in MediaQuery.displayFeaturesOf(context)) {
      final isHinge = feature.type == DisplayFeatureType.hinge;

      final isActiveFold =
          feature.type == DisplayFeatureType.fold &&
          feature.state == DisplayFeatureState.postureHalfOpened;

      if (isHinge || isActiveFold) {
        return feature.bounds.shift(-origin);
      }
    }

    return null;
  }
}
