import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class SellerAvatar extends StatelessWidget {
  const SellerAvatar({
    super.key,
    required this.asset,
    required this.name,
    this.size = 43,
    this.onPressed,
  });

  final String asset, name;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onPressed != null,
    label: onPressed == null ? name : AppStrings.viewSellerProfile(name),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const AppIcon(AppIcons.profile, size: 24),
          ),
        ),
      ),
    ),
  );
}
