import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

import 'package:hywork/core/localization/strings/post_detail_strings.dart';

class PostContent extends StatelessWidget {
  const PostContent({super.key, this.title = PostDetailStrings.postTitle});

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
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: AppTextStyles.postHeading,
          ),
          const SizedBox(height: 28),
          const Text(
            PostDetailStrings.visualSuggestion,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            PostDetailStrings.captionHeading,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const Text(
            PostDetailStrings.caption,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            PostDetailStrings.serviceBenefits,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            PostDetailStrings.booking,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          const Text(
            PostDetailStrings.hashtagsHeading,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const Text(
            PostDetailStrings.hashtags,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 22),
          const Text(
            PostDetailStrings.callToActionHeading,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
          const Text(
            PostDetailStrings.callToAction,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.postBody,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
