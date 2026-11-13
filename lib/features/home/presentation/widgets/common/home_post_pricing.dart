import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/post_detail_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'home_badge.dart';

class HomePostPricing extends StatelessWidget {
  const HomePostPricing({super.key, required this.post});

  final PostItem post;

  String _amount(String value) {
    final normalized = AppStrings.persianDigits(value)
        .trim()
        .replaceAll(RegExp(r'[,٬\s]'), '')
        .replaceAll('٫', '.');
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) return value;
    final parts = normalized.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final price = post.price.trim();
    final original = post.originalPrice.trim();
    final unit = post.details.unit;
    final currencyStyle = AppTextStyles.labelBold.copyWith(
      height: 1,
      color: foreground,
    );
    final currencyInset =
        MediaQuery.textScalerOf(context).scale(currencyStyle.fontSize!) + 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final prices = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (original.isNotEmpty && _amount(original) != _amount(price))
              Padding(
                padding: EdgeInsets.only(left: currencyInset),
                child: Text(
                  _amount(original),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: AppTextStyles.homeOriginalPrice.copyWith(
                    color: foreground.withValues(alpha: .3),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: foreground.withValues(alpha: .3),
                  ),
                ),
              ),
            if (price.isNotEmpty)
              Wrap(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          AppStrings.tomanPersian,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: currencyStyle,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _amount(price),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: AppTextStyles.homePostPrice.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (unit != null)
                    Text(
                      PostDetailStrings.unit(unit),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.heading.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: foreground,
                      ),
                    ),
                ],
              ),
          ],
        );
        final stock = post.isService
            ? null
            : HomeBadge(
                label: post.stockCount > 0
                    ? AppStrings.inStock(post.stockCount)
                    : AppStrings.stockUnavailable,
                background: AppColors.stockBadgeBackground,
                foreground: AppColors.notificationBadge,
              );
        // Keep the price on the left and stock on the right. On narrow screens
        // or with larger text, give each a full line without shrinking text.
        if (constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(16) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (price.isNotEmpty || original.isNotEmpty) prices,
              if (stock != null) ...[
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: stock),
              ],
            ],
          );
        }
        return Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: prices),
            if (stock != null) ...[const SizedBox(width: 12), stock],
          ],
        );
      },
    );
  }
}
