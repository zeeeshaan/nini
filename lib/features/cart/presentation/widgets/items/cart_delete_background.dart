// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class CartDeleteBackground extends StatelessWidget {
  const CartDeleteBackground({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 58,
        height: double.infinity,
        decoration: BoxDecoration(color: colors.onSurface, borderRadius: BorderRadius.circular(12)),
        child: Center(child: AppIcon(AppIcons.trash, color: colors.surface, size: 22)),
      ),
    );
  }
}
