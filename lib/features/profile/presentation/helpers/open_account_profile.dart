import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/core/icons/app_icons.dart';

import '../pages/profile_screen.dart';

void openAccountProfile(BuildContext context) {
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
