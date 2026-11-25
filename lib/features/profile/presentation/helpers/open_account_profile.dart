import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';

import '../pages/profile_screen.dart';

class AccountProfileNavigation extends InheritedWidget {
  const AccountProfileNavigation({
    super.key,
    required this.onOpenProfile,
    required super.child,
  });
  final VoidCallback onOpenProfile;

  static VoidCallback? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<AccountProfileNavigation>()
      ?.onOpenProfile;

  @override
  bool updateShouldNotify(AccountProfileNavigation oldWidget) =>
      onOpenProfile != oldWidget.onOpenProfile;
}

void openAccountProfile(BuildContext context) {
  final open = AccountProfileNavigation.maybeOf(context);
  if (open != null) {
    open();
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,

          actions: [
            IconButton(
              tooltip: AppStrings.back,
              onPressed: () => Navigator.of(context).pop(),
              icon: const AppIcon(AppIcons.backRight),
            ),
          ],
        ),
        body: const SafeArea(top: false, child: ProfileScreen()),
      ),
    ),
  );
}
