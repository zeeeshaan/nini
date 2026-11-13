import 'package:flutter/material.dart';
import 'package:nini/core/assets/app_assets.dart';
import 'package:nini/core/localization/strings/auth_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// Shared vector brand mark; inherits the theme unless a color is supplied.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => AppIcon(
    AppAssets.hyworkLogo,
    size: size,
    color: color,
    semanticLabel: AuthStrings.logo,
  );
}
