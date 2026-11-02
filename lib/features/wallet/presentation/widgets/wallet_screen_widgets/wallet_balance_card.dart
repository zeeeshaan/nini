import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/wallet_strings.dart';

import '../../../data/wallet_sample_data.dart';
import 'wallet_card_footer.dart';

/// The same layered balance card is used on both wallet screens.
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({super.key, this.showWithdrawal = false});
  final bool showWithdrawal;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Stack(
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
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.onSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.fromLTRB(40, 32, 16, 24),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: colors.surface),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      WalletStrings.balance,
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      AppStrings.persianDigits(WalletSampleData.balance),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const Spacer(),
                    WalletCardFooter(showWithdrawal: showWithdrawal),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
