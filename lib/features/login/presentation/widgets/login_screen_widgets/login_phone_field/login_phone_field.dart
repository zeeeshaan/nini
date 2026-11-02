import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/localization/auth_strings.dart';

import '../login_country_picker/login_country_picker.dart';

class LoginPhoneField extends StatelessWidget {
  const LoginPhoneField({
    super.key,
    required this.controller,
    required this.onCountryChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCountryChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩]')),
      ],
      validator: (value) => value == null || value.trim().isEmpty
          ? AuthStrings.phoneRequired
          : null,
      onFieldSubmitted: (_) => onSubmitted(),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        hintText: AuthStrings.mobile,
        hintTextDirection: TextDirection.rtl,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        suffixIcon: const Icon(Icons.phone_iphone_outlined, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 100,
          maxWidth: 120,
        ),
        prefixIcon: LoginCountryPicker(onChanged: onCountryChanged),
      ),
    ),
  );
}
