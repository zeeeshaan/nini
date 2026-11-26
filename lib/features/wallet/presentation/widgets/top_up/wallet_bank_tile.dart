import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/wallet_strings.dart';

import 'wallet_bank_logo.dart';

class WalletBankTile extends StatelessWidget {
  const WalletBankTile({
    super.key,
    required this.bank,
    required this.selected,
    required this.onTap,
  });
  final String bank;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Semantics(
      button: true,
      selected: selected,
      label: WalletStrings.bankName(bank),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: .7,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
              ),
              const Spacer(),
              WalletBankLogo(bank: bank, size: 42),
            ],
          ),
        ),
      ),
    ),
  );
}
