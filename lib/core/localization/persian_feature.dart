import 'package:flutter/material.dart';

/// Uses Persian Material labels and dates while preserving the app's established
/// layout order. Text and individual form controls set their own RTL direction.
class PersianFeature extends StatelessWidget {
  const PersianFeature({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('fa', 'IR'),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle.merge(textAlign: TextAlign.right, child: child),
    ),
  );
}
