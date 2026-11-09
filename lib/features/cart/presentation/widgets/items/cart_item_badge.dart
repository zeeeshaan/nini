// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class CartItemBadge extends StatelessWidget {
  const CartItemBadge({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: colors.onSurface, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: AppTextStyles.micro.copyWith(color: colors.surface),
      ),
    );
  }
}
