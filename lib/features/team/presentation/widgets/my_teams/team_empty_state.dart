import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class TeamEmptyState extends StatelessWidget {
  const TeamEmptyState({
    super.key,
    required this.imageAsset,
    required this.imageWidth,
    this.searching = false,
  });
  final String imageAsset;
  final double imageWidth;
  final bool searching;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        if (!searching)
          Image.asset(imageAsset, width: imageWidth, fit: BoxFit.contain),
        const SizedBox(height: 12),
        Text(
          searching ? "تیمی مطابق جستجوی شما یافت نشد" : "هنوز تیمی ندارید",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyText,
          textDirection: TextDirection.rtl,
        ),
      ],
    ),
  );
}
