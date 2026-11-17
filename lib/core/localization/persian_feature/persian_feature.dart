import 'package:flutter/material.dart';

/// English testing locale with the existing feature wrapper API.
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
