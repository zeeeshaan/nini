import 'package:flutter/material.dart';
import 'package:nini/core/localization/wallet_strings.dart';

import 'wallet_bank_tile.dart';

class WalletPaymentMethods extends StatefulWidget {
  const WalletPaymentMethods({super.key});
  @override
  State<WalletPaymentMethods> createState() => _WalletPaymentMethodsState();
}

class _WalletPaymentMethodsState extends State<WalletPaymentMethods> {
  String _selected = 'mellat';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        WalletStrings.paymentMethod,
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 11),
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 14),
      for (final bank in ['melli', 'mellat', 'saman'])
        WalletBankTile(
          bank: bank,
          selected: _selected == bank,
          onTap: () => setState(() => _selected = bank),
        ),
    ],
  );
}
