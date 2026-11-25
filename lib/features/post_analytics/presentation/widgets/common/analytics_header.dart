import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/profile_settings/domain/user_profile.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/shared/widgets/app_images/profile_image_provider.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';

import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';

class AnalyticsPostHeader extends StatelessWidget {
  const AnalyticsPostHeader({super.key, required this.post});
  final PostItem post;
  @override
  Widget build(BuildContext context) {
    final profile =
        context.watch<UserProfileCubit?>()?.state.profile ??
        const UserProfile();
    final avatar = profileImageProvider(
      post.isPublished ? profile.avatarPath : null,
    );
    final location = post.isPublished
        ? (post.details.address?.address ?? '')
        : AppStrings.authorLocation;
    return Column(
      children: [
        Row(
          children: [
            Text(
              post.isPublished
                  ? AppStrings.onThisDevice
                  : AppStrings.sampleData,
              style: AppTextStyles.metadata.copyWith(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .5),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
            const Spacer(),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    post.isPublished
                        ? profile.displayName
                        : AppStrings.authorName,
                    style: AppTextStyles.labelEmphasis,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.metadata.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: .38),
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.analyticsOnline,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: avatar == null
                    ? const AppIcon(AppIcons.profile)
                    : Image(
                        image: avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const AppIcon(AppIcons.profile),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SizedBox.square(
              dimension: constraints.maxWidth * .56,
              child: post.media.isNotEmpty
                  ? PostMediaView(media: post.media.first)
                  : Image.asset(
                      post.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Center(
                        child: AppIcon(AppIcons.imageUnavailable),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
