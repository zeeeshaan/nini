import 'package:flutter/material.dart';

/// Persian locale with the existing control order and right-aligned content.
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
