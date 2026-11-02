import 'package:flutter/material.dart';

class HomeBadge extends StatelessWidget {
  const HomeBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        child: Text(
          label,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: foreground, fontSize: 11, height: 1.2),
        ),
      ),
    );
  }
}
