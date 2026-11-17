import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/core/localization/strings/payment_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class PaymentEscrow extends StatelessWidget {
  const PaymentEscrow({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Text(
        PaymentStrings.buyerEscrowSecurity,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodyBold,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 4),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Text(
          CartStrings.escrowHelp,
          textAlign: TextAlign.right,
          style: AppTextStyles.smallPrint.copyWith(height: 1.5),
          textDirection: TextDirection.ltr,
        ),
      ),
    ],
  );
}
