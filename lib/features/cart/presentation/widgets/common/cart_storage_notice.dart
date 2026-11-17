// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';

class CartStorageNotice extends StatelessWidget {
  const CartStorageNotice({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        TextButton(
          onPressed: onRetry,
          child: const Text(
            CartStrings.retry,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            CartStrings.storageError,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.helper,
          ),
        ),
      ],
    ),
  );
}
