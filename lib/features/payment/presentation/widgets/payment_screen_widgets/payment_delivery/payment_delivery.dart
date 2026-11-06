import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PaymentDelivery extends StatelessWidget {
  const PaymentDelivery({super.key, required this.details});
  final PaymentDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = details.scheduledAt;
    final dateTime = date == null
        ? 'Not provided'
        : '${date.year}-${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}  |  '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final rows = [
      ('Date & Time', dateTime, AppIcons.calendar),
      ('Location', details.address ?? 'Not provided', AppIcons.location),
      ('Phone number', details.phone ?? 'Not provided', AppIcons.phone),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Delivery Address',
            textAlign: TextAlign.right,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            row.$2,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: AppTextStyles.numberFontFamily,
                              fontFamilyFallback: const ['Arial'],
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: .65,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Text(row.$1, textAlign: TextAlign.right),
                        ),
                        const SizedBox(width: 10),
                        AppIcon(row.$3, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
