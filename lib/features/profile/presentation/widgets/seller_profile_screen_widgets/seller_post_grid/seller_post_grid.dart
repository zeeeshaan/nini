import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_carousel_image.dart';
import 'package:nini/features/posts/presentation/widgets/post_media_view/post_media_view.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class SellerPostGrid extends StatelessWidget {
  const SellerPostGrid({
    super.key,
    required this.posts,
    required this.onPostTap,
  });

  final List<PostItem> posts;
  final ValueChanged<PostItem> onPostTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Divider(height: 1),
      Semantics(
        label: AppStrings.posts,
        selected: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              const AppIcon(AppIcons.grid, size: 22),
              const SizedBox(height: 12),
              Container(
                width: 56,
                height: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
      if (posts.isEmpty)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Text(AppStrings.noSellerPosts, style: AppTextStyles.body),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            final post = posts[index];
            return Semantics(
              label: post.title,
              button: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => onPostTap(post),
                  child: post.media.isEmpty
                      ? PostCarouselImage(path: post.imageAsset)
                      : PostMediaView(media: post.media.first),
                ),
              ),
            );
          },
        ),
    ],
  );
}
