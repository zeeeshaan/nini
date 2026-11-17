import 'package:flutter/material.dart';

enum AppButtonVariant { primary, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 48,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;

  final AppButtonVariant variant;

  final bool isLoading;
  final bool isExpanded;

  final double height;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final contentColor = variant == AppButtonVariant.primary
        ? colors.onPrimary
        : colors.onSurface;

    final action = isLoading ? null : onPressed;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: contentColor,
            ),
          )
        else
          ?icon,
        if (isLoading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );

    final Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(onPressed: action, child: content);

      case AppButtonVariant.outlined:
        button = OutlinedButton(onPressed: action, child: content);

      case AppButtonVariant.text:
        button = TextButton(onPressed: action, child: content);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: SizedBox(
        width: isExpanded ? double.infinity : null,
        child: button,
      ),
    );
  }
}
