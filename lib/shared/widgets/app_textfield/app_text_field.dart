import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.textStyle,
    this.focusNode,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.ltr,
    this.decorationDirection,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autovalidateMode,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onSaved,
  }) : assert(maxLines == null || maxLines > 0);

  final TextEditingController? controller;
  final TextStyle? textStyle;
  final FocusNode? focusNode;

  final String? label;
  final String? hint;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextDirection? decorationDirection;

  final int? maxLines;
  final int? maxLength;

  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  final AutovalidateMode? autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;

  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FormFieldSetter<String>? onSaved;

  @override
  Widget build(BuildContext context) {
    // InputDecorator uses ambient direction for labels and floating labels;
    // setting TextFormField.textDirection alone only changes the input text.
    return Directionality(
      textDirection: decorationDirection ?? textDirection,
      child: TextFormField(
        // Keep selection menus inside Flutter so iOS native menus cannot overlap.
        contextMenuBuilder: (context, editableTextState) =>
            AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState,
            ),
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: obscureText ? 1 : maxLines,
        maxLength: maxLength,
        obscureText: obscureText,
        enabled: enabled,
        readOnly: readOnly,
        autofocus: autofocus,
        autovalidateMode: autovalidateMode,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
        onTap: onTap,
        onFieldSubmitted: onSubmitted,
        onSaved: onSaved,
        style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintTextDirection: textDirection,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
