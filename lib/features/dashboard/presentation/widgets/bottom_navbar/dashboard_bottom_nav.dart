import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foldable/foldable.dart';

import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';

import 'dashboard_fold_layout.dart';
import 'dashboard_nav_item.dart';

// dart format width=100

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
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (theme.appBarTheme.systemOverlayStyle ?? SystemUiOverlayStyle.light)
              .copyWith(
                systemNavigationBarColor: AppColors.black,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarContrastEnforced: false,
              ),
      child: Material(
        color: AppColors.black,
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.white),
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
                        child: Row(
                          children: [
                            for (final tab in DashboardTab.values)
                              _buildNavigationItem(context, tab),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(BuildContext context, DashboardTab tab) {
    return Expanded(
      child: DashboardNavItem(
        tab: tab,
        selectedTab: selectedTab,
        onTabSelected: onTabSelected,
        cartCount: cartCount,
        profileImage: profileImage,
      ),
    );
  }
}
