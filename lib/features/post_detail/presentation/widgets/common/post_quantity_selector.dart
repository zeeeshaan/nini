import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/post_detail_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/presentation/helpers/cart_format.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class PostQuantitySelector extends StatelessWidget {
  const PostQuantitySelector({
    super.key,
    required this.quantity,
    required this.maximum,
    required this.onChanged,
    required this.unitLabel,
    this.onEdit,
    this.compact = false,
  });

  final int quantity;
  final int maximum;
  final ValueChanged<int> onChanged;
  final String unitLabel;
  final VoidCallback? onEdit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canIncrease = quantity + 100 <= maximum;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Flexible(
            child: TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurface,
                disabledForegroundColor: colors.onSurface.withValues(
                  alpha: .45,
                ),
                minimumSize: compact ? const Size(40, 44) : const Size(64, 48),
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
              ),
              child: Semantics(
                label: PostDetailStrings.quantity,
                child: Text(
                  '${PostDetailStrings.persianDigits(cartQuantity(quantity))} $unitLabel',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? AppTextStyles.label.copyWith(
                          color: colors.onSurface.withValues(
                            alpha: onEdit != null ? 1 : .45,
                          ),
                        )
                      : AppTextStyles.bodyText,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: PostDetailStrings.increaseQuantity,
            onPressed: canIncrease ? () => onChanged(quantity + 100) : null,
            padding: EdgeInsets.all(compact ? 8 : 10),
            constraints: BoxConstraints(
              minWidth: compact ? 44 : 48,
              minHeight: compact ? 44 : 48,
            ),
            icon: AppIcon(
              AppIcons.add,
              size: compact ? 22 : 28,
              color: colors.onSurface.withValues(alpha: canIncrease ? 1 : .35),
            ),
          ),
        ],
      ),
    );
  }
}
