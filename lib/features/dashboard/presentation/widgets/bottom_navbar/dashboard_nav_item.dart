// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'dashboard_cart_icon.dart';

class DashboardNavItem extends StatelessWidget {
  const DashboardNavItem({
    super.key,
    required this.tab,
    required this.selectedTab,
    required this.onTabSelected,
    this.cartCount,
    this.profileImage,
  });
  final DashboardTab tab, selectedTab;
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
      child: InkWell(
        onTap: () => onTabSelected(tab),
        child: SizedBox(
          height: 68,
          child: Center(child: ExcludeSemantics(child: _iconFor(context, tab, isSelected))),
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
        return AppIcon(AppIcons.home, size: 32, selected: isSelected);

      case DashboardTab.cart:
        return DashboardCartIcon(selected: isSelected, count: cartCount);

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
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundImage: profileImage,
            child: profileImage == null ? const AppIcon(AppIcons.profile, size: 22) : null,
          ),
        );
    }
  }
}
