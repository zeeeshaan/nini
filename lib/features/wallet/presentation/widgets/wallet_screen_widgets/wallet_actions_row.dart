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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(9) / 9;
      final columns = ((constraints.maxWidth + 7) / (52 * scale + 7))
          .floor()
          .clamp(1, 5);
      final width = (constraints.maxWidth - 7 * (columns - 1)) / columns;
      final actions = [
        WalletActionTile(
          label: WalletStrings.topUp,
          icon: AppIcons.walletTopUp,
          onTap: onTopUp,
        ),
        const WalletActionTile(
          label: WalletStrings.transfer,
          icon: AppIcons.walletTransfer,
        ),
        const WalletActionTile(
          label: WalletStrings.request,
          icon: AppIcons.walletRequest,
        ),
        WalletActionTile(
          label: WalletStrings.withdraw,
          icon: AppIcons.walletWithdraw,
          onTap: onWithdraw,
        ),
        const WalletActionTile(
          label: WalletStrings.payment,
          icon: AppIcons.walletPayment,
        ),
      ];
      return Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final action in actions) SizedBox(width: width, child: action),
        ],
      );
    },
  );
}
