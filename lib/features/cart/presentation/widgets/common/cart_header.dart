// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/cart_strings.dart';
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
        children: [
          if (onBack != null) ...[
            IconButton(
              tooltip: CartStrings.back,
              onPressed: onBack,
              icon: const AppIcon(AppIcons.back, size: 25),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.cartTitle,
            ),
          ),
        ],
      ),
    ),
  );
}
