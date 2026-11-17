import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';

class HomePostMediaIndicator extends StatelessWidget {
  const HomePostMediaIndicator({
    super.key,
    required this.count,
    this.controller,
  });

  final int count;
  final PageController? controller;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    final pageController = controller;
    if (pageController != null) {
      return AnimatedBuilder(
        animation: pageController,
        builder: (context, child) {
          final page =
              pageController.hasClients &&
                  pageController.position.hasContentDimensions
              ? pageController.page ?? pageController.initialPage.toDouble()
              : pageController.initialPage.toDouble();
          return _buildDots(context, page);
        },
      );
    }
    return BlocBuilder<PostDetailCubit, PostDetailState>(
      buildWhen: (previous, current) =>
          previous.imageIndex != current.imageIndex,
      builder: (context, state) => TweenAnimationBuilder<double>(
        tween: Tween(
          begin: state.imageIndex.toDouble(),
          end: state.imageIndex.toDouble(),
        ),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, page, child) => _buildDots(context, page),
      ),
    );
  }

  Widget _buildDots(BuildContext context, double currentPage) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final page = currentPage.clamp(0.0, count - 1.0);
    final visibleCount = count > 5 ? 5 : count;
    // Keep the first three pages fixed. Let the strip follow slightly behind
    // the swipe so the selected dot moves too, then gently recentres.
    final targetFirstDot = (page - 2).clamp(
      0.0,
      (count - visibleCount).toDouble(),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: targetFirstDot, end: targetFirstDot),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (context, animatedFirstDot, child) {
        final firstDot = animatedFirstDot.clamp(
          0.0,
          (count - visibleCount).toDouble(),
        );
        return Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppColors.black
                    : foreground.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SizedBox(
                  width: visibleCount * 12,
                  height: 8,
                  child: ClipRect(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CarouselDotsPainter(
                              count: count,
                              page: page,
                              firstDot: firstDot,
                              foreground: foreground,
                            ),
                          ),
                        ),
                        // One highlight follows the finger while the strip catches
                        // up, rather than remaining pinned in the centre.
                        Positioned(
                          key: const ValueKey('carousel-active-dot'),
                          left:
                              (page - firstDot).clamp(0.0, visibleCount - 1.0) *
                                  12 +
                              2,
                          top: 0,
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CarouselDotsPainter extends CustomPainter {
  const _CarouselDotsPainter({
    required this.count,
    required this.page,
    required this.firstDot,
    required this.foreground,
  });

  final int count;
  final double page, firstDot;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Paint only the visible dots and their neighbours, retaining each dot's
    // absolute image index as it enters or leaves the clipped viewport.
    final first = (firstDot.floor() - 1).clamp(0, count - 1);
    final last = (firstDot + size.width / 12).ceil().clamp(0, count - 1);
    for (var index = first; index <= last; index++) {
      final distance = (index - page).abs();
      final diameter = distance <= 1
          ? 4.0
          : distance <= 2
          ? lerpDouble(4, 2.8, distance - 1)!
          : lerpDouble(2.8, 1.8, (distance - 2).clamp(0.0, 1.0))!;
      final opacity = distance <= 1
          ? .55 * distance
          : distance <= 2
          ? lerpDouble(.55, .3, distance - 1)!
          : lerpDouble(.3, .15, (distance - 2).clamp(0.0, 1.0))!;
      paint.color = foreground.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset((index - firstDot) * 12 + 6, size.height / 2),
        diameter / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CarouselDotsPainter oldDelegate) =>
      count != oldDelegate.count ||
      page != oldDelegate.page ||
      firstDot != oldDelegate.firstDot ||
      foreground != oldDelegate.foreground;
}
