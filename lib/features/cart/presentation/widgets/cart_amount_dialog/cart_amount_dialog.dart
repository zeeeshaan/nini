// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

import '../../helpers/cart_format.dart';
import '../cart_dialog_actions/cart_dialog_actions.dart';

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
  late final _controller = TextEditingController(text: cartQuantity(widget.value));
  @override
  void dispose() {
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
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 30),
            AppTextField(
              key: const ValueKey('cart-amount-input'),
              controller: _controller,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              keyboardType: TextInputType.numberWithOptions(decimal: !widget.wholeUnits),
              textInputAction: TextInputAction.done,
              validator: _validate,
              suffixIcon: const Padding(
                padding: EdgeInsets.all(14),
                child: AppIcon(AppIcons.addCircle, size: 22),
              ),
              onSubmitted: (_) => _done(),
            ),
            const SizedBox(height: 18),
            Text(
              widget.wholeUnits ? CartStrings.integerHelp : CartStrings.decimalHelp,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 42),
          ],
        ),
      ),
    ),
  );
}
