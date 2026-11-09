// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/localization/cart_strings.dart';

import '../../cubit/cart_state.dart';
import '../../helpers/cart_format.dart';

class CartPaymentSummary extends StatelessWidget {
  const CartPaymentSummary({super.key, required this.state, required this.onCharges});
  final CartState state;
  final VoidCallback onCharges;
  Widget _row(String label, int amount, {bool bold = false, VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              cartMoney(amount),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: (bold ? AppTextStyles.pageTitleBold : AppTextStyles.bodyBold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: (bold ? AppTextStyles.boldText : AppTextStyles.regularText),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      children: [
        _row(CartStrings.subtotal, state.subtotal),
        _row(CartStrings.discount, state.discount),
        _row(CartStrings.charges, state.charges, onTap: onCharges),
        const SizedBox(height: 6),
        const Divider(),
        _row('${CartStrings.total} (${CartStrings.toman})', state.total, bold: true),
      ],
    ),
  );
}
