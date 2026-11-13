import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

/// Shared Persian actions for Cart amount dialogs.
class CartDialogActions extends StatelessWidget {
  const CartDialogActions({
    super.key,
    required this.onDone,
    this.doneLabel = CartStrings.done,
  });
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
