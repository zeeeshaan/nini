// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class CartHeader extends StatelessWidget {
  const CartHeader({super.key, required this.title, required this.onBack, this.trailing});
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
    child: SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: CartStrings.back,
            onPressed: onBack,
            icon: const AppIcon(AppIcons.back, size: 25),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}
