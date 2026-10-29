import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.cartCount = 9,
    this.profileImage,
    this.maxContentWidth = 720,
  });

  final DashboardTab selectedTab;
  final ValueChanged<DashboardTab> onTabSelected;
  final int cartCount;
  final ImageProvider? profileImage;
  final double maxContentWidth;

  static const double _barHeight = 68;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _barHeight,
            child: FoldAwareBuilder(
              builder: (context, constraints, fold) {
                final divider = fold.spansDivision
                    ? fold.divisionRect
                    : _findAndroidDivider(context);

                if (divider != null && constraints.hasBoundedWidth) {
                  final splitBar = _buildSplitNavigation(
                    context,
                    divider,
                    constraints.maxWidth,
                    constraints.maxHeight,
                    Directionality.of(context),
                  );

                  if (splitBar != null) {
                    return splitBar;
                  }
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: _buildNormalNavigation(context),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalNavigation(BuildContext context) {
    return Row(
      children: [
        for (final tab in DashboardTab.values)
          _buildNavigationItem(context, tab),
      ],
    );
  }

  Widget? _buildSplitNavigation(
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

    final isRtl = textDirection == TextDirection.rtl;
    final leftTabs = isRtl
        ? [DashboardTab.profile, DashboardTab.search, DashboardTab.create]
        : [DashboardTab.home, DashboardTab.cart];
    final rightTabs = isRtl
        ? [DashboardTab.cart, DashboardTab.home]
        : [DashboardTab.create, DashboardTab.search, DashboardTab.profile];

    // The hinge bounds describe physical left/right panes, even in RTL.
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
            children: [
              for (final tab in leftTabs) _buildNavigationItem(context, tab),
            ],
          ),
        ),
        SizedBox(width: gapWidth),
        SizedBox(
          width: rightWidth,
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              for (final tab in rightTabs) _buildNavigationItem(context, tab),
            ],
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

  Widget _buildNavigationItem(BuildContext context, DashboardTab tab) {
    final isSelected = selectedTab == tab;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: _labelFor(tab),
        child: InkWell(
          onTap: () => onTabSelected(tab),
          child: SizedBox(
            height: _barHeight,
            child: Center(
              child: ExcludeSemantics(
                child: _iconFor(context, tab, isSelected),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(DashboardTab tab) {
    return switch (tab) {
      DashboardTab.home => AppStrings.home,
      DashboardTab.cart => AppStrings.cart,
      DashboardTab.create => AppStrings.create,
      DashboardTab.search => AppStrings.search,
      DashboardTab.profile => AppStrings.profile,
    };
  }

  Widget _iconFor(BuildContext context, DashboardTab tab, bool isSelected) {
    switch (tab) {
      case DashboardTab.home:
        return AppIcon(AppIcons.home, size: 32, selected: isSelected);

      case DashboardTab.cart:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AppIcon(AppIcons.cart, size: 32, selected: isSelected),
            if (cartCount > 0)
              Positioned(
                top: -5,
                right: -8,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2020),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.persianDigits(
                      cartCount > 99 ? '99+' : cartCount,
                    ),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );

      case DashboardTab.create:
        return AppIcon(AppIcons.add, size: 42, selected: isSelected);

      case DashboardTab.search:
        return AppIcon(AppIcons.search, size: 35, selected: isSelected);

      case DashboardTab.profile:
        return Container(
          width: 35,
          height: 35,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundImage: profileImage,
            child: profileImage == null
                ? const AppIcon(AppIcons.profile, size: 22)
                : null,
          ),
        );
    }
  }
}
