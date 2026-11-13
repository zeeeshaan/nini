import 'package:flutter/material.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/core/localization/strings/payment_strings.dart';

class PaymentActions extends StatelessWidget {
  const PaymentActions({super.key, this.onConfirm, this.isProcessing = false});
  final VoidCallback? onConfirm;
  final bool isProcessing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outlined,
            onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: PaymentStrings.payment,
            isLoading: isProcessing,
            onPressed:
                onConfirm ??
                () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Payment is not connected yet. No money has been charged.',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    );
                },
          ),
        ),
      ],
    ),
  );
}
