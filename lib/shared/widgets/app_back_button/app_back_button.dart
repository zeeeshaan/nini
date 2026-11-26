import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Right-facing route dismissal for headers that previously used automatic Back.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)?.impliesAppBarDismissal != true) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const AppIcon(AppIcons.backRight),
    );
  }
}
