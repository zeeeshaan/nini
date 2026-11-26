// dart format width=100
import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

import '../../../domain/models/cart_order_status.dart';

/// A filter menu, never an action that rewrites an order's status.
class CartStatusMenu extends StatelessWidget {
  const CartStatusMenu({super.key, required this.selected, required this.onSelected});
  final CartOrderStatus? selected;
  final ValueChanged<CartOrderStatus?> onSelected;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: const ValueKey('cart-status-menu'),
    tooltip: CartStrings.filterStatus,
    icon: const AppIcon(AppIcons.more, size: 24),
    color: AppColors.darkSurfaceContainer,
    position: PopupMenuPosition.under,
    constraints: const BoxConstraints(minWidth: 210, maxWidth: 260),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onSelected: (value) => onSelected(value == 'all' ? null : CartOrderStatus.fromName(value)),
    itemBuilder: (_) => [
      _option('all', CartStrings.allStatuses, selected == null),
      for (final status in CartOrderStatus.values)
        _option(status.name, status.label, selected == status),
    ],
  );
  PopupMenuEntry<String> _option(String value, String label, bool selected) => PopupMenuItem(
    key: ValueKey('cart-status-$value'),
    value: value,
    height: 42,
    child: Semantics(
      selected: selected,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.compactBody.copyWith(color: AppColors.white),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const AppIcon(AppIcons.check, size: 14, color: AppColors.white),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
