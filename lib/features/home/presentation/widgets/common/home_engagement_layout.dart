import 'package:flutter/material.dart';

/// Shared by feed cards and post details. Wrap actions instead of scaling their
/// icons down when the viewport or larger text needs more space.
class HomeEngagementLayout extends StatelessWidget {
  const HomeEngagementLayout({
    super.key,
    required this.rating,
    required this.actions,
  });

  static const actionIconSize = 24.0;
  final Widget rating;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.ltr,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      rating,
      const SizedBox(width: 12),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            textDirection: TextDirection.rtl,
            spacing: 6,
            children: actions.reversed.toList(),
          ),
        ),
      ),
    ],
  );
}
