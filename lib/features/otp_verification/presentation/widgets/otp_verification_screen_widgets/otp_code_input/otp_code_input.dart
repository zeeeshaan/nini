import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/localization/auth_strings.dart';
import 'package:pinput/pinput.dart';

class OtpCodeInput extends StatelessWidget {
  const OtpCodeInput({
    super.key,
    required this.phoneNumber,
    required this.onChanged,
  });

  final String phoneNumber;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = Theme.of(context).colorScheme;
      final width = math.min(64.0, (constraints.maxWidth - 36) / 4);
      final pinTheme = PinTheme(
        width: width,
        height: 64,
        textStyle: TextStyle(fontSize: 26, color: colors.onSurface),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.onSurface, width: 1),
        ),
      );
      return Semantics(
        label: AuthStrings.codeFor(phoneNumber),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            length: 4,
            defaultPinTheme: pinTheme,
            focusedPinTheme: pinTheme.copyDecorationWith(
              border: Border.all(color: colors.onSurface, width: 2),
            ),
            separatorBuilder: (_) => const SizedBox(width: 12),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩]')),
            ],
            onChanged: onChanged,
          ),
        ),
      );
    },
  );
}
