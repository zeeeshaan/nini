import 'package:flutter/material.dart';

/// Uses English development labels without changing the established layout
/// order or right alignment. Kept here so the display language is easy to restore.
class PersianFeature extends StatelessWidget {
  const PersianFeature({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('en'),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle.merge(textAlign: TextAlign.right, child: child),
    ),
  );
}
