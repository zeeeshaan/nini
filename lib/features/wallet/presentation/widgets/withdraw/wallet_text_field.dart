import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/localization/app_string/app_string.dart';

/// Shared outline and spacing for the withdrawal inputs.
class WalletTextField extends StatelessWidget {
  const WalletTextField({
    super.key,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.keyboardType = TextInputType.number,
  });
  final TextEditingController? controller;
  final String? hint;
  final Widget? prefixIcon, suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colors.onSurface.withValues(alpha: .65),
        width: .7,
      ),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      style: AppTextStyles.label,
      decoration: InputDecoration(
        hintText: hint == null ? null : AppStrings.persianDigits(hint!),
        hintTextDirection: TextDirection.ltr,
        hintStyle: AppTextStyles.helper.copyWith(
          color: colors.onSurface.withValues(alpha: .35),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
}
