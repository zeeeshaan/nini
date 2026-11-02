import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';

import '../../../data/wallet_sample_data.dart';

class WalletAmountPresets extends StatelessWidget {
  const WalletAmountPresets({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final amount in WalletSampleData.presets)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: selected == amount ? colors.primary : colors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => onSelected(amount),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      AppStrings.persianDigits(amount),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected == amount
                            ? colors.onPrimary
                            : colors.onSurface,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
