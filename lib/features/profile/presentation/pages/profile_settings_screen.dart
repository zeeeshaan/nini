import 'package:flutter/material.dart';
import 'package:nini/core/animation/screen_entrance.dart';

import '../widgets/settings/profile_settings_header.dart';
import '../widgets/settings/profile_settings_list.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenEntrance(
    child: Scaffold(
      appBar: const ProfileSettingsHeader(),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: const ProfileSettingsList(),
          ),
        ),
      ),
    ),
  );
}
