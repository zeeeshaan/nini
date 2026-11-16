import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import '../../../data/wallet_sample_data.dart';
import 'wallet_card_footer.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    this.showWithdrawal = false,
    this.onTopUp,
    this.onWithdraw,
  });
  final bool showWithdrawal;
  final VoidCallback? onTopUp, onWithdraw;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 22,
          right: 22,
          bottom: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        Positioned(
          top: 9,
          left: 10,
          right: 10,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 180),
            decoration: BoxDecoration(
              color: colors.onSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.fromLTRB(20, 28, 28, 14),
            child: DefaultTextStyle.merge(
              style: AppTextStyles.inherit.copyWith(color: colors.surface),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    WalletStrings.balance,
                    style: AppTextStyles.label,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    AppStrings.persianDigits(WalletSampleData.balance),
                    style: AppTextStyles.walletBalance,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 28),
                  WalletCardFooter(
                    showWithdrawal: showWithdrawal,
                    onTopUp: onTopUp,
                    onWithdraw: onWithdraw,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
