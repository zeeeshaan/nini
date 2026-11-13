import 'package:flutter/material.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/skeleton/product_card_skeleton.dart';

import '../../helpers/open_settings_post.dart';

class SettingsPostsGrid extends StatelessWidget {
  const SettingsPostsGrid({
    super.key,
    this.posts = const [],
    this.loading = false,
  });
  final List<PostItem> posts;
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
      final cardWidth = (responsive.width - (columns - 1) * 2) / columns;
      final contentScale = cardWidth / ProfilePostCard.referenceWidth;
      final detailsHeight = ProfilePostCard.detailsHeightFor(
        context,
        contentScale,
      );
      final direction = Directionality.of(context);
      return Directionality(
        textDirection: TextDirection.rtl,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          reverse: false,
          itemCount: loading ? columns * 2 : posts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 2,
            mainAxisExtent: cardWidth + detailsHeight,
          ),
          itemBuilder: (context, index) => loading
              ? const ProductCardSkeleton()
              : Directionality(
                  textDirection: direction,
                  child: ProfilePostCard(
                    post: posts[index],
                    detailsHeight: detailsHeight,
                    contentScale: contentScale,
                    onTap: () => openSettingsPost(context, posts[index]),
                  ),
                ),
        ),
      );
    },
  );
}
