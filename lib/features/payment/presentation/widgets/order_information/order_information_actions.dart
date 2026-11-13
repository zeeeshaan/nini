import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class OrderInformationActions extends StatelessWidget {
  const OrderInformationActions({
    super.key,
    required this.onCancel,
    required this.onCheckout,
  });
  final VoidCallback onCancel;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: AppStrings.cancel,
                  variant: AppButtonVariant.outlined,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: CartStrings.checkout,
                  onPressed: onCheckout,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
