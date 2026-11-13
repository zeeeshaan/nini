import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'dashboard_cart_icon.dart';

// dart format width=100

class DashboardNavItem extends StatelessWidget {
  const DashboardNavItem({
    super.key,
    required this.tab,
    required this.selectedTab,
    required this.onTabSelected,
    this.cartCount,
    this.profileImage,
  });

  final DashboardTab tab;
  final DashboardTab selectedTab;
  final ValueChanged<DashboardTab> onTabSelected;
  final int? cartCount;
  final ImageProvider? profileImage;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTab == tab;

    return Semantics(
      button: true,
      selected: isSelected,
      label: _labelFor(tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Material(
          color: isSelected
              ? AppColors.bottomNavHighlight
              : AppColors.transparent,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            hoverColor: AppColors.bottomNavHighlight,
            focusColor: AppColors.bottomNavHighlight,
            highlightColor: AppColors.bottomNavHighlight,
            splashColor: AppColors.white.withValues(alpha: .12),
            onTap: () => onTabSelected(tab),
            child: SizedBox(
              height: 52,
              child: Center(
                child: ExcludeSemantics(
                  child: _iconFor(context, tab, isSelected),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(DashboardTab tab) {
    if (selectedTab == DashboardTab.cart) {
      return switch (tab) {
        DashboardTab.home => CartStrings.home,
        DashboardTab.cart => CartStrings.cart,
        DashboardTab.create => CartStrings.create,
        DashboardTab.search => CartStrings.search,
        DashboardTab.profile => CartStrings.profile,
      };
    }

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
        return const AppIcon(AppIcons.home, size: 32);

      case DashboardTab.cart:
        return DashboardCartIcon(selected: isSelected, count: cartCount);

      case DashboardTab.create:
        return const AppIcon(AppIcons.add, size: 42);

      case DashboardTab.search:
        return const AppIcon(AppIcons.search, size: 35);

      case DashboardTab.profile:
        return Container(
          width: 35,
          height: 35,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.darkSurfaceContainer,
            foregroundColor: AppColors.white,
            child: profileImage == null
                ? const AppIcon(AppIcons.profile, size: 22)
                : ClipOval(
                    child: Image(
                      image: profileImage!,
                      width: 31,
                      height: 31,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const AppIcon(AppIcons.profile, size: 22),
                    ),
                  ),
          ),
        );
    }
  }
}
