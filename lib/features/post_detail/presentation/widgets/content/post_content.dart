import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/localization/app_strings.dart';

class PostContent extends StatelessWidget {
  const PostContent({super.key, this.title = AppStrings.postTitle});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.postHeading,
          ),
          const SizedBox(height: 28),
          const Text(
            AppStrings.visualSuggestion,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.captionHeading,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const Text(
            AppStrings.caption,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.serviceBenefits,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.booking,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.hashtagsHeading,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const Text(
            AppStrings.hashtags,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 22),
          const Text(
            AppStrings.callToActionHeading,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const Text(
            AppStrings.callToAction,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
