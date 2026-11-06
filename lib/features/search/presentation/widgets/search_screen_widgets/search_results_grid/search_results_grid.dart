import 'package:flutter/material.dart';

import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_result_card/search_result_card.dart';

class SearchResultsGrid extends StatefulWidget {
  const SearchResultsGrid({
    super.key,
    required this.posts,
    this.onPostSelected,
  });

  final List<PostItem> posts;
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
      final textScale = (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(
        1.0,
        double.infinity,
      );
      final columns = (constraints.maxWidth / (110 * textScale)).floor().clamp(
        1,
        responsive.gridColumns,
      );
      return Directionality(
        textDirection: TextDirection.rtl,
        child: GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 1,
            mainAxisSpacing: 0,
            mainAxisExtent:
                (constraints.maxWidth - columns + 1) / columns + 80 * textScale,
          ),
          itemCount: widget.posts.length,
          itemBuilder: (context, index) => SearchResultCard(
            key: ValueKey(widget.posts[index].id),
            post: widget.posts[index],
            onTap: widget.onPostSelected == null
                ? null
                : () => widget.onPostSelected!(widget.posts[index]),
          ),
        ),
      );
    },
  );
}
