import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/order_information_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/payment/domain/models/order_customer_details.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class OrderInformationFields extends StatelessWidget {
  const OrderInformationFields({
    super.key,
    required this.controllers,
    required this.onMap,
  });
  final Map<OrderCustomerField, TextEditingController> controllers;
  final VoidCallback onMap;

  static const _labels = {
    OrderCustomerField.name: OrderInformationStrings.name,
    OrderCustomerField.surname: OrderInformationStrings.surname,
    OrderCustomerField.mobile: OrderInformationStrings.mobile,
    OrderCustomerField.city: OrderInformationStrings.city,
    OrderCustomerField.province: OrderInformationStrings.province,
    OrderCustomerField.address: OrderInformationStrings.address,
    OrderCustomerField.postalCode: OrderInformationStrings.postalCode,
  };

  String? _validate(OrderCustomerField field, String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) {
      return OrderInformationStrings.requiredField(_labels[field]!);
    }
    if (field == OrderCustomerField.mobile &&
        !RegExp(r'^\+?\d{7,15}$')
            .hasMatch(OrderCustomerDetails.normalizeMobile(value))) {
      return OrderInformationStrings.invalidMobile;
    }
    if (field == OrderCustomerField.postalCode &&
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9 -]{2,15}$')
            .hasMatch(AppStrings.latinDigits(value))) {
      return OrderInformationStrings.invalidPostalCode;
    }
    return null;
  }

  Widget _input(OrderCustomerField field) => AppTextField(
    controller: controllers[field],
    textDirection:
        field == OrderCustomerField.mobile ||
            field == OrderCustomerField.postalCode
        ? TextDirection.ltr
        : TextDirection.ltr,
    textInputAction: field == OrderCustomerField.postalCode
        ? TextInputAction.done
        : TextInputAction.next,
    keyboardType: field == OrderCustomerField.mobile
        ? TextInputType.phone
        : field == OrderCustomerField.address
        ? TextInputType.streetAddress
        : TextInputType.text,
    validator: (value) => _validate(field, value),
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          OrderInformationStrings.personalInformation,
          textAlign: TextAlign.right,
          style: AppTextStyles.sectionTitle,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 26),
        for (final field in OrderCustomerField.values) ...[
          Text(
            _labels[field]!,
            textAlign: TextAlign.right,
            style: AppTextStyles.body,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 4),
          if (field == OrderCustomerField.address)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onMap,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: const AppIcon(
                      AppIcons.location,
                      size: 22,
                      semanticLabel: OrderInformationStrings.chooseAddress,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(child: _input(field)),
              ],
            )
          else
            _input(field),
          const SizedBox(height: 10),
        ],
      ],
    ),
  );
}
