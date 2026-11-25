import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/saved_posts_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/skeleton/product_card_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/app_shimmer.dart';

import '../../../domain/saved_post.dart';

class SavedPostsGrid extends StatelessWidget {
  const SavedPostsGrid({
    super.key,
    required this.posts,
    required this.onPostTap,
    required this.onRemove,
    this.saving = false,
    this.loading = false,
  });

  final List<SavedPost> posts;
  final ValueChanged<SavedPost> onPostTap, onRemove;
  final bool saving;
  final bool loading;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
        1.0,
        double.infinity,
      );
      final columns = (responsive.width / (110 * textScale)).floor().clamp(
        1,
        responsive.gridColumns.clamp(1, 3),
      );
      const spacing = 2.0;
      final cardWidth = (responsive.width - spacing * (columns - 1)) / columns;
      final scale = cardWidth / ProfilePostCard.referenceWidth;
      final detailsHeight = ProfilePostCard.detailsHeightFor(context, scale);
      final cardDirection = Directionality.of(context);
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppShimmer.when(
          enabled: loading,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: loading ? columns * 2 : posts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisExtent: cardWidth + detailsHeight,
            ),
            itemBuilder: (_, index) {
              if (loading) return const ProductCardSkeleton(animated: false);
              final entry = posts[index];
              return Directionality(
                key: ValueKey(entry.post.id),
                textDirection: cardDirection,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProfilePostCard(
                      post: entry.post,
                      detailsHeight: detailsHeight,
                      contentScale: scale,
                      onTap: () => onPostTap(entry),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: .92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: SavedPostsStrings.unsave,
                          onPressed: saving ? null : () => onRemove(entry),
                          icon: const AppIcon(
                            AppIcons.bookmarkFilled,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
