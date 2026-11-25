import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';

class WithdrawReviewNotice extends StatelessWidget {
  const WithdrawReviewNotice({super.key});
  @override
  Widget build(BuildContext context) {
    final warningColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.walletPending
        : Color.lerp(AppColors.walletPending, AppColors.black, .4)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.walletPending),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle.merge(
        style: AppTextStyles.helper.copyWith(color: warningColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Flexible(
                  child: Text(
                    WalletStrings.reviewCarefully,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.helperBold,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.info_outline, size: 18, color: warningColor),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              WalletStrings.withdrawalReview,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}
