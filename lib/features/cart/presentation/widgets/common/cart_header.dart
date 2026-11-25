// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class CartHeader extends StatelessWidget {
  const CartHeader({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              style: AppTextStyles.cartTitle,
            ),
          ),
          if (onBack != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: CartStrings.back,
              onPressed: onBack,
              icon: const AppIcon(AppIcons.backRight, size: 25),
            ),
          ],
        ],
      ),
    ),
  );
}
