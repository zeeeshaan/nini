import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/wallet_strings.dart';

import 'wallet_action_tile.dart';

class WalletActionsRow extends StatelessWidget {
  const WalletActionsRow({
    super.key,
    required this.onWithdraw,
    required this.onTopUp,
  });
  final VoidCallback onWithdraw, onTopUp;
  @override
  Widget build(BuildContext context) => Row(
    spacing: 7,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: WalletActionTile(
          label: WalletStrings.topUp,
          icon: AppIcons.walletTopUp,
          onTap: onTopUp,
        ),
      ),
      const Expanded(
        child: WalletActionTile(
          label: WalletStrings.transfer,
          icon: AppIcons.walletTransfer,
        ),
      ),
      const Expanded(
        child: WalletActionTile(
          label: WalletStrings.request,
          icon: AppIcons.walletRequest,
        ),
      ),
      Expanded(
        child: WalletActionTile(
          label: WalletStrings.withdraw,
          icon: AppIcons.walletWithdraw,
          onTap: onWithdraw,
        ),
      ),
      const Expanded(
        child: WalletActionTile(
          label: WalletStrings.payment,
          icon: AppIcons.walletPayment,
        ),
      ),
    ],
  );
}
