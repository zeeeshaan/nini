import 'package:flutter/material.dart';
import 'package:nini/core/animations/screen_entrance/screen_entrance.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'settings_detail_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ScreenEntrance(
    child: Scaffold(
      appBar: SettingsDetailHeader(title: title),
      body: SafeArea(
        top: false,
        child: AppResponsiveBuilder(
          builder: (context, responsive) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: responsive.isExpanded ? 720 : 600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
