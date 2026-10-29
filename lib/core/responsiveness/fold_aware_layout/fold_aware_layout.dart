import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

class FoldAwareLayout extends StatelessWidget {
  const FoldAwareLayout({
    super.key,
    required this.primary,
    required this.secondary,
    this.minimumPaneSize = 200,
  });

  final Widget primary;
  final Widget secondary;
  final double minimumPaneSize;

  @override
  Widget build(BuildContext context) {
    return FoldAwareBuilder(
      builder: (context, constraints, fold) {
        if (constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight &&
            fold.spansDivision &&
            fold.divisionRect != null) {
          final foldedLayout = _buildFoldedLayout(
            constraints.biggest,
            fold.divisionRect!,
            Directionality.of(context) == TextDirection.rtl,
          );

          if (foldedLayout != null) {
            return foldedLayout;
          }
        }

        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final isExpanded = width >= AppResponsive.expandedBreakpoint;

        if (!isExpanded) return primary;

        return Row(
          children: [
            Expanded(child: primary),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }

  Widget? _buildFoldedLayout(Size size, Rect divider, bool isRtl) {
    final isVertical = divider.height >= size.height - 1 && divider.width > 0;

    final isHorizontal = divider.width >= size.width - 1 && divider.height > 0;

    if (isVertical) {
      final leftWidth = divider.left.clamp(0.0, size.width).toDouble();

      final rightStart = divider.right.clamp(0.0, size.width).toDouble();

      final rightWidth = size.width - rightStart;
      final gap = rightStart - leftWidth;

      final showBoth =
          leftWidth >= minimumPaneSize && rightWidth >= minimumPaneSize;

      return Row(
        // Keep physical hinge coordinates independent of reading direction.
        textDirection: TextDirection.ltr,
        children: [
          SizedBox(
            width: leftWidth,
            child: showBoth
                ? (isRtl ? secondary : primary)
                : leftWidth >= rightWidth
                ? primary
                : const SizedBox.shrink(),
          ),
          SizedBox(width: gap),
          SizedBox(
            width: rightWidth,
            child: showBoth
                ? (isRtl ? primary : secondary)
                : rightWidth > leftWidth
                ? primary
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    if (isHorizontal) {
      final topHeight = divider.top.clamp(0.0, size.height).toDouble();

      final bottomStart = divider.bottom.clamp(0.0, size.height).toDouble();

      final bottomHeight = size.height - bottomStart;
      final gap = bottomStart - topHeight;

      final showBoth =
          topHeight >= minimumPaneSize && bottomHeight >= minimumPaneSize;

      return Column(
        children: [
          SizedBox(
            height: topHeight,
            child: showBoth || topHeight >= bottomHeight
                ? primary
                : const SizedBox.shrink(),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: bottomHeight,
            child: showBoth
                ? secondary
                : bottomHeight > topHeight
                ? primary
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    return null;
  }
}
