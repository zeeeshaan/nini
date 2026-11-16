import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/core/theme/app_text_styles.dart';

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
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final colors = Theme.of(context).colorScheme;
      final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
      final columns = ((responsive.width + 8) / (70 * scale + 8)).floor().clamp(
        1,
        4,
      );
      final width = (responsive.width - (columns - 1) * 8) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final amount in WalletSampleData.presets)
            SizedBox(
              width: width,
              child: Semantics(
                button: true,
                selected: selected == amount,
                child: InkWell(
                  onTap: () => onSelected(amount),
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected == amount
                              ? colors.primary
                              : colors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          AppStrings.persianDigits(amount),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.micro.copyWith(
                            color: selected == amount
                                ? colors.onPrimary
                                : colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
