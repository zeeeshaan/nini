import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/localization/strings/auth_strings.dart';

class LoginPhoneField extends StatelessWidget {
  const LoginPhoneField({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
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
        prefixIcon: const Center(
          widthFactor: 1,
          child: Text('+98', textDirection: TextDirection.ltr),
        ),
      ),
    ),
  );
}
