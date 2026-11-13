import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/auth_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../domain/email_address.dart';

class LoginEmailField extends StatelessWidget {
  const LoginEmailField({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textAlign: TextAlign.right,
    textDirection: TextDirection.ltr,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.email],
    autocorrect: false,
    enableSuggestions: false,
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return AuthStrings.emailRequired;
      }
      return isValidEmailAddress(value) ? null : AuthStrings.invalidEmail;
    },
    onFieldSubmitted: (_) => onSubmitted(),
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    decoration: const InputDecoration(
      hintText: AuthStrings.email,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      suffixIcon: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: AppIcon(AppIcons.email, size: 20),
      ),
    ),
  );
}
