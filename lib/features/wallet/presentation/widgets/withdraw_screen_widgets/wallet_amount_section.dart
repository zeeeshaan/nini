import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/wallet_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../data/wallet_sample_data.dart';
import 'wallet_amount_presets.dart';
import 'wallet_text_field.dart';

class WalletAmountSection extends StatefulWidget {
  const WalletAmountSection({
    super.key,
    this.label = WalletStrings.pendingAmount,
  });
  final String label;
  @override
  State<WalletAmountSection> createState() => _WalletAmountSectionState();
}

class _WalletAmountSectionState extends State<WalletAmountSection> {
  final _amount = TextEditingController(
    text: AppStrings.persianDigits(WalletSampleData.pendingAmount),
  );
  String? _selected = WalletSampleData.presets.last;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.label,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 11),
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 8),
      WalletTextField(
        controller: _amount,
        suffixIcon: const Padding(
          padding: EdgeInsets.all(11),
          child: AppIcon(AppIcons.bankNote, size: 18),
        ),
        onChanged: (value) => setState(
          () => _selected = WalletSampleData.presets
              .where(
                (amount) =>
                    amount == value ||
                    AppStrings.persianDigits(amount) == value,
              )
              .firstOrNull,
        ),
      ),
      const SizedBox(height: 6),
      WalletAmountPresets(
        selected: _selected,
        onSelected: (amount) {
          _amount.text = AppStrings.persianDigits(amount);
          setState(() => _selected = amount);
        },
      ),
    ],
  );
}
