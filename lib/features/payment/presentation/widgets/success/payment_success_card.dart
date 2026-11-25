import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PaymentSuccessCard extends StatelessWidget {
  const PaymentSuccessCard({
    super.key,
    this.amount,
    this.method,
    this.reference,
  });

  final String? amount, method, reference;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.walletCredit.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: AppIcon(
                  AppIcons.check,
                  color: AppColors.walletCredit,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            ReceiptStrings.paymentSuccessful,
            textAlign: TextAlign.right,
            style: AppTextStyles.pageTitleBold,
            textDirection: TextDirection.ltr,
          ),
          if (amount != null) ...[
            const SizedBox(height: 12),
            Text(
              amount!,
              textAlign: TextAlign.right,
              style: AppTextStyles.analyticsTotal,
              textDirection: TextDirection.ltr,
            ),
          ],
          if (method != null) ...[
            const SizedBox(height: 8),
            Text(
              method!,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyText,
              textDirection: TextDirection.ltr,
            ),
          ],
          if (reference != null) ...[
            const SizedBox(height: 8),
            Text(
              reference!,
              textAlign: TextAlign.right,
              style: AppTextStyles.smallPrint,
              textDirection: TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }
}
