// dart format width=100
import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

class CartSection extends StatelessWidget {
  const CartSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.bodyBold,
          ),
        ),
        child,
      ],
    ),
  );
}
