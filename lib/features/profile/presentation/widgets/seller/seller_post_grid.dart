import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/shared/models/post/post_item.dart';

class SellerPostGrid extends StatelessWidget {
  const SellerPostGrid({
    super.key,
    required this.posts,
    required this.onPostTap,
    this.emptyMessage = AppStrings.noSellerPosts,
  });

  final List<PostItem> posts;
  final ValueChanged<PostItem> onPostTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Divider(height: 1),
      if (posts.isEmpty)
        Padding(
          padding: EdgeInsets.all(32),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              emptyMessage,
              style: AppTextStyles.body,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ),
        )
      else
        AppResponsiveBuilder(
          builder: (context, responsive) {
            final width = responsive.width;
            final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
                .clamp(1.0, double.infinity);
            final columns = (width / (110 * textScale)).floor().clamp(
              1,
              responsive.gridColumns.clamp(1, 3),
            );
            const spacing = 2.0;
            final cardWidth = (width - spacing * (columns - 1)) / columns;
            final contentScale = cardWidth / ProfilePostCard.referenceWidth;
            final detailsHeight = ProfilePostCard.detailsHeightFor(
              context,
              contentScale,
            );
            return Directionality(
              textDirection: TextDirection.rtl,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: posts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: 0,
                  mainAxisExtent: cardWidth + detailsHeight,
                ),
                itemBuilder: (_, index) {
                  final post = posts[index];
                  return Directionality(
                    textDirection: Directionality.of(context),
                    child: ProfilePostCard(
                      post: post,
                      contentScale: contentScale,
                      detailsHeight: detailsHeight,
                      onTap: () => onPostTap(post),
                    ),
                  );
                },
              ),
            );
          },
        ),
    ],
  );
}
