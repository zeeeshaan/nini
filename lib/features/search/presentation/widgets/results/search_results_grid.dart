import 'package:flutter/material.dart';

import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/skeleton/product_card_skeleton.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';

import 'package:hywork/features/search/presentation/widgets/results/search_result_card.dart';

class SearchResultsGrid extends StatefulWidget {
  const SearchResultsGrid({
    super.key,
    required this.posts,
    this.onPostSelected,
    this.isLoading = false,
    this.onLoadMore,
  });

  final List<PostItem> posts;
  final bool isLoading;
  final VoidCallback? onLoadMore;
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
        textDirection: TextDirection.rtl,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical &&
                notification.metrics.extentAfter < 500)
              widget.onLoadMore?.call();
            return false;
          },
          child: AppShimmer.when(
            enabled: widget.isLoading,
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
              itemBuilder: (_, index) => Directionality(
                textDirection: Directionality.of(context),
                child: widget.isLoading
                    ? const ProductCardSkeleton(animated: false)
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
            ),
          ),
        ),
      );
    },
  );
}
