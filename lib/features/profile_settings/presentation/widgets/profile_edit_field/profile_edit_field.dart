import 'package:flutter/material.dart';

class ProfileEditField extends StatelessWidget {
  const ProfileEditField({
    super.key,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      keyboardType: keyboardType,
      maxLines: maxLines,
      textDirection: keyboardType == TextInputType.emailAddress
          ? TextDirection.ltr
          : TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: label,
        hintTextDirection: TextDirection.rtl,
        hintStyle: TextStyle(
          fontSize: 12,
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
