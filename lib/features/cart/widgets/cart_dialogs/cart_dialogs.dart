// dart format width=100
import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/theme/app_theme/app_theme.dart';
import 'package:hywork/features/cart/utils/cart_helpers.dart';
import 'package:hywork/features/create_post/widgets/post_dialog/post_dialog.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_textfield/app_text_field.dart';

/// Uses the same opposite-theme sheet as the post editor.
Future<int?> showCartAmountDialog(
  BuildContext context, {
  required int value,
  bool wholeUnits = false,
  bool allowZero = false,
  int maximum = 99999999900,
  String title = CartStrings.quantity,
}) => showPostDialog<int>(
  context,
  CartAmountDialog(
    value: value,
    wholeUnits: wholeUnits,
    allowZero: allowZero,
    maximum: maximum,
    title: title,
  ),
);

class CartAmountDialog extends StatefulWidget {
  const CartAmountDialog({
    super.key,
    required this.value,
    required this.wholeUnits,
    required this.allowZero,
    required this.maximum,
    required this.title,
  });
  final int value, maximum;
  final bool wholeUnits, allowZero;
  final String title;
  @override
  State<CartAmountDialog> createState() => _CartAmountDialogState();
}

class _CartAmountDialogState extends State<CartAmountDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: cartAmountInput(widget.value));
  final _focus = FocusNode();
  bool _selectInitialValue = true;

  void _selectValue() {
    if (!_selectInitialValue) return;
    _selectInitialValue = false;
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
  }

  void _clear() {
    _selectInitialValue = false;
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? text) {
    final amount = parseCartAmount(text ?? '');
    if (amount == null || amount < (widget.allowZero ? 0 : 1)) {
      return widget.allowZero ? CartStrings.invalidCharges : CartStrings.invalidAmount;
    }
    if (widget.wholeUnits && amount % 100 != 0) return CartStrings.integerHelp;
    if (amount > widget.maximum) return CartStrings.outOfStock;
    return null;
  }

  void _done() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(parseCartAmount(_controller.text));
  }

  @override
  Widget build(BuildContext context) => PostDialog(
    title: widget.title,
    actions: CartDialogActions(onDone: _done),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              CartStrings.quantityHelp,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.inherit.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 30),
            AppTextField(
              key: const ValueKey('cart-amount-input'),
              controller: _controller,
              focusNode: _focus,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.numberWithOptions(decimal: !widget.wholeUnits),
              textInputAction: TextInputAction.done,
              validator: _validate,
              suffixIcon: IconButton(
                tooltip: CartStrings.clearAmount,
                onPressed: _clear,
                icon: const AppIcon(AppIcons.close, size: 22),
              ),
              onTap: _selectValue,
              onSubmitted: (_) => _done(),
            ),
            const SizedBox(height: 18),
            Text(
              widget.wholeUnits ? CartStrings.integerHelp : CartStrings.decimalHelp,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.inherit.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 42),
          ],
        ),
      ),
    ),
  );
}

/// Shared Persian actions for Cart amount dialogs.
class CartDialogActions extends StatelessWidget {
  const CartDialogActions({super.key, required this.onDone, this.doneLabel = CartStrings.done});
  final VoidCallback onDone;
  final String doneLabel;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AppButton(
          label: CartStrings.cancel,
          variant: AppButtonVariant.outlined,
          height: 44,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: AppButton(label: doneLabel, height: 44, onPressed: onDone),
      ),
    ],
  );
}

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
                          textDirection: TextDirection.ltr,
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
                  textDirection: TextDirection.ltr,
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
                          textDirection: TextDirection.ltr,
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
                        textDirection: TextDirection.ltr,
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
