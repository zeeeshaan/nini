import 'package:flutter/material.dart';

import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/skeleton/product_card_skeleton.dart';

import 'package:nini/features/search/presentation/widgets/results/search_result_card.dart';

class SearchResultsGrid extends StatefulWidget {
  const SearchResultsGrid({
    super.key,
    required this.posts,
    this.onPostSelected,
    this.isLoading = false,
  });

  final List<PostItem> posts;
  final bool isLoading;
  final ValueChanged<PostItem>? onPostSelected;

  @override
  State<SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<SearchResultsGrid> {
  final _scrollController = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final responsive = AppResponsive.fromWidth(constraints.maxWidth);
      final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
        1.0,
        double.infinity,
      );
      final columns = (constraints.maxWidth / (110 * textScale)).floor().clamp(
        1,
        responsive.gridColumns.clamp(1, 3),
      );
      const spacing = 2.0;
      final cardWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      final contentScale = cardWidth / ProfilePostCard.referenceWidth;
      final detailsHeight = ProfilePostCard.detailsHeightFor(
        context,
        contentScale,
      );
      return Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 0,
            mainAxisExtent: cardWidth + detailsHeight,
          ),
          itemCount: widget.isLoading ? columns * 2 : widget.posts.length,
          itemBuilder: (context, index) => widget.isLoading
              ? const ProductCardSkeleton()
              : SearchResultCard(
                  key: ValueKey(widget.posts[index].id),
                  post: widget.posts[index],
                  contentScale: contentScale,
                  detailsHeight: detailsHeight,
                  onTap: widget.onPostSelected == null
                      ? null
                      : () => widget.onPostSelected!(widget.posts[index]),
                ),
        ),
      );
    },
  );
}
