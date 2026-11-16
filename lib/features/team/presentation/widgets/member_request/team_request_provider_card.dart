import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';
import 'package:nini/features/team/domain/team_provider_selection.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_images/profile_image_provider.dart';

class TeamRequestProviderCard extends StatelessWidget {
  const TeamRequestProviderCard({super.key, required this.request});

  final TeamProviderSelection request;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final seller = request.provider;
    final post = request.post;
    final image = profileImageProvider(post.imageAsset);

    return Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          seller.name,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.authorName,
                          textDirection: TextDirection.rtl,
                        ),
                        if (seller.location.isNotEmpty)
                          Text(
                            seller.location,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.smallPrint.copyWith(
                              color: colors.onSurface.withValues(alpha: .55),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SellerAvatar(
                    asset: seller.avatarAsset,
                    name: seller.name,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'عنوان: ${post.title}',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyBold,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox.square(
            dimension: 88,
            child: post.media.isNotEmpty
                ? PostMediaView(media: post.media.first)
                : image != null
                ? Image(
                    image: image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: AppIcon(AppIcons.imageUnavailable, size: 28),
                    ),
                  )
                : ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: const Center(
                      child: AppIcon(AppIcons.imageUnavailable, size: 28),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
