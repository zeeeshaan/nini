import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/shared/models/post/post_item.dart';

class PostPricing extends StatelessWidget {
  const PostPricing({
    super.key,
    required this.post,
    this.color,
    this.showCurrency = false,
  });

  final PostItem post;
  final Color? color;
  final bool showCurrency;

  @override
  Widget build(BuildContext context) {
    final price = post.price.trim();
    final original = post.originalPrice.trim();
    final hasDiscount = original.isNotEmpty && original != price;
    final textTheme = Theme.of(context).textTheme;
    final priceLabel = Text(
      AppStrings.persianDigits(price),
      textDirection: TextDirection.rtl,
      style: textTheme.titleLarge?.copyWith(
        color: color,
        fontSize: hasDiscount ? AppTextStyles.body.fontSize : null,
        fontWeight: AppTextStyles.bold,
      ),
      textAlign: TextAlign.right,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (price.isNotEmpty)
              if (showCurrency)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.ltr,
                  children: [
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        AppStrings.toman,
                        style: AppTextStyles.micro.copyWith(color: color),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(child: priceLabel),
                  ],
                )
              else
                priceLabel,
            if (post.details.unit case final unit?)
              Text(
                unit.label,
                style: textTheme.bodyMedium?.copyWith(color: color),
                textAlign: TextAlign.right,
              ),
          ],
        ),
        if (hasDiscount)
          Text(
            AppStrings.persianDigits(original),
            textDirection: TextDirection.rtl,
            style: textTheme.titleLarge?.copyWith(
              color: color,
              decoration: TextDecoration.lineThrough,
              decorationColor: color,
            ),
            textAlign: TextAlign.right,
          ),
      ],
    );
  }
}
