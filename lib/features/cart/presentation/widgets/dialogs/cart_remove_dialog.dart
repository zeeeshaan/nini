// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

Future<bool> showCartRemoveDialog(BuildContext context, {required String itemTitle}) async {
  ContextMenuController.removeAny();
  FocusScope.of(context).unfocus();
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context).brightness == Brightness.light
              ? AppTheme.dark
              : AppTheme.light;
          return Theme(
            data: theme,
            child: CartRemoveDialog(itemTitle: itemTitle),
          );
        },
      ) ??
      false;
}

class CartRemoveDialog extends StatelessWidget {
  const CartRemoveDialog({super.key, required this.itemTitle});

  final String itemTitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final noButton = AppButton(
      label: CartStrings.no,
      variant: AppButtonVariant.outlined,
      onPressed: () => Navigator.of(context).pop(false),
    );
    final yesButton = AppButton(
      label: CartStrings.yes,
      onPressed: () => Navigator.of(context).pop(true),
    );
    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AppResponsiveBuilder(
            builder: (context, responsive) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        namesRoute: true,
                        header: true,
                        child: Text(
                          CartStrings.removeTitle,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.heading.copyWith(fontWeight: AppTextStyles.bold),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(AppIcons.trash, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  CartStrings.removeConfirmation,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body.copyWith(color: colors.onSurface.withValues(alpha: .8)),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodyEmphasis,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const AppIcon(AppIcons.shoppingBag, size: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        CartStrings.removeUndoHelp,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.helper.copyWith(
                          color: colors.onSurface.withValues(alpha: .75),
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: AppIcon(AppIcons.undo, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (responsive.width < 260 || MediaQuery.textScalerOf(context).scale(16) > 24)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [noButton, const SizedBox(height: 12), yesButton],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: noButton),
                      const SizedBox(width: 12),
                      Expanded(child: yesButton),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
