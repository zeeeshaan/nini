import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'withdraw_illustration.dart';
import 'withdraw_summary_row.dart';

/// Presentation only. No bank transaction is submitted by this preview.
class WithdrawSuccessSheet extends StatelessWidget {
  const WithdrawSuccessSheet({super.key, required this.amount});
  final String amount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 36, height: 2, color: colors.onSurface),
            ),
            const SizedBox(height: 20),
            const WithdrawIllustration(),
            const SizedBox(height: 20),
            const Text(
              WalletStrings.withdrawalComplete,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyBold,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            const Text(
              WalletStrings.previewOnly,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: .7),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: WithdrawSummaryRow(
                label: WalletStrings.withdrawalAmount,
                value: amount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
