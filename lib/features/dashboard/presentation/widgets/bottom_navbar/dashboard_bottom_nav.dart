// dart format width=100
import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';

import 'dashboard_nav_item.dart';
import 'dashboard_fold_layout.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.cartCount,
    this.profileImage,
    this.maxContentWidth = 720,
  });

  final DashboardTab selectedTab;
  final ValueChanged<DashboardTab> onTabSelected;
  final int? cartCount;
  final ImageProvider? profileImage;
  final double maxContentWidth;

  static const double _barHeight = 68;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _barHeight,
            child: FoldAwareBuilder(
              builder: (context, constraints, fold) {
                return DashboardFoldLayout(
                  divider: fold.spansDivision ? fold.divisionRect : null,
                  constraints: constraints,
                  itemBuilder: _buildNavigationItem,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: _buildNormalNavigation(context),
                    ),
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
      children: [for (final tab in DashboardTab.values) _buildNavigationItem(context, tab)],
    );
  }

  Widget _buildNavigationItem(BuildContext context, DashboardTab tab) => Expanded(
    child: DashboardNavItem(
      tab: tab,
      selectedTab: selectedTab,
      onTabSelected: onTabSelected,
      cartCount: cartCount,
      profileImage: profileImage,
    ),
  );
}
