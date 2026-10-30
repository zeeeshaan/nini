import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/models/post/post_item.dart';

class PostPricing extends StatelessWidget {
  const PostPricing({super.key, required this.post});

  final PostItem post;

  @override
  Widget build(BuildContext context) {
    final price = post.price.trim();
    final originalPrice = post.originalPrice.trim();
    final unit = post.details.unit;
    if (price.isEmpty && unit == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (price.isNotEmpty)
            Wrap(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${AppStrings.price}:',
                  textDirection: TextDirection.rtl,
                  style: textTheme.bodyMedium,
                ),
                Text(
                  AppStrings.persianDigits(price),
                  textDirection: TextDirection.rtl,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (originalPrice.isNotEmpty && originalPrice != price)
                  Text(
                    AppStrings.persianDigits(originalPrice),
                    textDirection: TextDirection.rtl,
                    style: textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          if (unit != null) ...[
            if (price.isNotEmpty) const SizedBox(height: 6),
            Text(
              '${AppStrings.unit}: ${unit.label}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
