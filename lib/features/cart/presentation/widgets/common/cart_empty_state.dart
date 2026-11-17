// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class CartEmptyState extends StatelessWidget {
  const CartEmptyState({super.key, required this.title, this.message});
  final String title;
  final String? message;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppIcon(AppIcons.shoppingBag, size: 44),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message!, textAlign: TextAlign.right, textDirection: TextDirection.ltr),
          ],
        ],
      ),
    ),
  );
}
