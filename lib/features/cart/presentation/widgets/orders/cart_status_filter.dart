// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../domain/models/cart_order_status.dart';

class CartStatusFilter extends StatelessWidget {
  const CartStatusFilter({super.key, required this.status, required this.onClear});
  final CartOrderStatus status;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Align(
      alignment: Alignment.centerRight,
      child: InputChip(
        key: const ValueKey('cart-active-status'),
        label: Text(status.label, textDirection: TextDirection.ltr, textAlign: TextAlign.right),
        deleteIcon: const AppIcon(AppIcons.close, size: 16),
        deleteButtonTooltipMessage: CartStrings.clearFilter,
        onDeleted: onClear,
      ),
    ),
  );
}
