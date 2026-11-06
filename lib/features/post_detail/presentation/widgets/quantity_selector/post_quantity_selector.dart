import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostQuantitySelector extends StatelessWidget {
  const PostQuantitySelector({
    super.key,
    required this.quantity,
    required this.maximum,
    required this.onChanged,
    required this.unitLabel,
    this.onEdit,
  });

  final int quantity;
  final int maximum;
  final ValueChanged<int> onChanged;
  final String unitLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canIncrease = quantity + 100 <= maximum;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface.withValues(alpha: .65)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              minimumSize: const Size(40, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Semantics(
              label: CartStrings.quantity,
              child: Text(
                '${cartQuantity(quantity)} $unitLabel',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: AppTextStyles.label,
              ),
            ),
          ),
          IconButton(
            tooltip: CartStrings.increaseQuantity,
            onPressed: canIncrease ? () => onChanged(quantity + 100) : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            visualDensity: VisualDensity.compact,
            icon: AppIcon(
              AppIcons.add,
              size: 20,
              color: colors.onSurface.withValues(alpha: canIncrease ? 1 : .35),
            ),
          ),
        ],
      ),
    );
  }
}
