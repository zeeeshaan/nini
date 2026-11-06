import 'package:flutter/material.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class PaymentActions extends StatelessWidget {
  const PaymentActions({super.key, this.onConfirm});
  final VoidCallback? onConfirm;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Confirm Pay',
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
