import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/post_detail_strings.dart';
import 'package:hywork/features/cart/presentation/helpers/cart_format.dart';
import 'package:hywork/shared/models/post/post_item.dart';

class PostPricing extends StatelessWidget {
  const PostPricing({
    super.key,
    required this.post,
    this.color,
    this.showCurrency = true,
    this.fallbackUnitLabel,
  });

  final PostItem post;
  final Color? color;
  final bool showCurrency;
  final String? fallbackUnitLabel;

  int? _amount(String value) => parseCartAmount(
    AppStrings.latinDigits(value).replaceAll(RegExp(r'[,\s]'), ''),
  );

  String _label(String value) {
    final amount = _amount(value);
    return amount == null ? AppStrings.persianDigits(value) : cartMoney(amount);
  }

  @override
  Widget build(BuildContext context) {
    final price = post.price.trim();
    final original = post.originalPrice.trim();
    final amount = _amount(price);
    final originalAmount = _amount(original);
    final hasDiscount =
        amount != null && originalAmount != null && originalAmount > amount;
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    final unit = post.details.unit?.label ?? fallbackUnitLabel;
    final currencyStyle = AppTextStyles.micro.copyWith(
      color: foreground,
      height: 1,
    );
    final currencyInset = showCurrency
        ? MediaQuery.textScalerOf(context).scale(currencyStyle.fontSize!) + 2
        : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        if (hasDiscount)
          Padding(
            padding: EdgeInsets.only(left: currencyInset),
            child: Text(
              _label(original),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: AppTextStyles.homeOriginalPrice.copyWith(
                color: foreground.withValues(alpha: .55),
                height: 1,
                decoration: TextDecoration.lineThrough,
                decorationColor: foreground.withValues(alpha: .55),
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (price.isNotEmpty) ...[
              if (showCurrency) ...[
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    PostDetailStrings.toman,
                    style: currencyStyle,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              Text(
                _label(price),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: AppTextStyles.homePostPrice.copyWith(
                  color: foreground,
                  height: 1,
                ),
              ),
            ],
            if (unit != null) ...[
              if (price.isNotEmpty) const SizedBox(width: 8),
              Text(
                unit,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: AppTextStyles.heading.copyWith(
                  color: foreground,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
