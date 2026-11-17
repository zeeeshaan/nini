import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/cart/presentation/widgets/dialogs/cart_amount_dialog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class TeamRequestQuantity extends StatelessWidget {
  const TeamRequestQuantity({
    super.key,
    required this.quantity,
    required this.unit,
    required this.onChanged,
  });

  final int quantity;
  final String unit;
  final ValueChanged<int> onChanged;

  Future<void> _edit(BuildContext context) async {
    final result = await showCartAmountDialog(
      context,
      value: quantity,
      title: 'Amount',
    );
    if (context.mounted && result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => _edit(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              AppIcon(AppIcons.add, size: 22, color: colors.onPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${cartQuantity(quantity)} $unit',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyText.copyWith(
                    color: colors.onPrimary,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
