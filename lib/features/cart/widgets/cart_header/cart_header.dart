// dart format width=100
import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/cubit/cart_state.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

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

class CartTabs extends StatelessWidget {
  const CartTabs({super.key, required this.selected, required this.onSelected});
  final CartTab selected;
  final ValueChanged<CartTab> onSelected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const labels = [CartStrings.cart, CartStrings.history, CartStrings.sales];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tab in CartTab.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Semantics(
                        selected: selected == tab,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () => onSelected(tab),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: selected == tab ? colors.onSurface : colors.surface,
                            ),
                            child: Text(
                              labels[tab.index],
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label.copyWith(
                                color: selected == tab ? colors.surface : colors.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
