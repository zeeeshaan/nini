import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/payment_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';
import 'package:nini/features/payment/presentation/widgets/order_information/order_information_item.dart';

class PaymentOrderDetails extends StatelessWidget {
  const PaymentOrderDetails({super.key, required this.details});
  final PaymentDetails details;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        PaymentStrings.orderDetails,
        textAlign: TextAlign.right,
        style: AppTextStyles.sectionTitle,
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 12),
      for (final item in details.items)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: OrderInformationItem(item: item, readOnly: true),
        ),
    ],
  );
}
