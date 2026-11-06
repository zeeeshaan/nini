import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';
import 'package:nini/features/payment/presentation/helpers/payment_money.dart';

class PaymentSummary extends StatelessWidget {
  const PaymentSummary({super.key, required this.details});
  final PaymentDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = details.summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order summary',
            textAlign: TextAlign.right,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            row.$2,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: AppTextStyles.numberFontFamily,
                              fontFamilyFallback: const ['Arial'],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(row.$1, textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.onSurface),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    paymentMoney(details.total),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: AppTextStyles.numberFontFamily,
                      fontFamilyFallback: const ['Arial'],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Total (toman)', textAlign: TextAlign.right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
