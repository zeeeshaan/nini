import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class ProfileEditField extends StatelessWidget {
  const ProfileEditField({
    super.key,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.textStyle = AppTextStyles.caption,
    this.controller,
    this.validator,
    this.enabled = true,
  });
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final TextStyle textStyle;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      textDirection: keyboardType == TextInputType.emailAddress
          ? TextDirection.ltr
          : TextDirection.ltr,
      textAlign: TextAlign.right,
      style: textStyle,
      decoration: InputDecoration(
        hintText: label,
        hintTextDirection: TextDirection.ltr,
        hintStyle: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    ),
  );
}
