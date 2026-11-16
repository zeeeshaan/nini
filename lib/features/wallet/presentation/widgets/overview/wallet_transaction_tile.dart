import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../domain/wallet_transaction.dart';

class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({super.key, required this.transaction});
  final WalletTransaction transaction;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final amountColor = switch (transaction.type) {
      WalletTransactionType.credit => AppColors.walletCredit,
      WalletTransactionType.debit => AppColors.red,
      WalletTransactionType.pending => AppColors.walletPending,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.persianDigits(transaction.amount),
              style: AppTextStyles.amount.copyWith(color: amountColor),
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  WalletStrings.transactionTitle(transaction.title),
                  style: AppTextStyles.helper,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 3),
                Text(
                  AppStrings.persianDigits(
                    WalletStrings.transactionDate(transaction.date),
                  ),
                  style: AppTextStyles.micro.copyWith(
                    color: colors.onSurface.withValues(alpha: .4),
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 19,
            backgroundColor: colors.surfaceContainerHighest,
            child: AppIcon(
              AppIcons.personOutline,
              size: 23,
              color: colors.onSurface.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}
