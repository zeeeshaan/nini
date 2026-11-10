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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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
          return _buildDots(context, page.round(), reduceMotion);
        },
      );
    }
    return BlocBuilder<PostDetailCubit, PostDetailState>(
      buildWhen: (previous, current) =>
          previous.imageIndex != current.imageIndex,
      builder: (context, state) =>
          _buildDots(context, state.imageIndex, reduceMotion),
    );
  }

  Widget _buildDots(BuildContext context, int currentPage, bool reduceMotion) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final active = currentPage.clamp(0, count - 1);
    final visibleCount = count > 5 ? 5 : count;
    final firstDot = (active - 2).clamp(0, count - visibleCount);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return FittedBox(
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
                  ...List.generate(visibleCount, (offset) {
                    final index = firstDot + offset;
                    final distance = (index - active).abs();
                    final size = switch (distance) {
                      0 => 0.0,
                      1 => 4.0,
                      2 => 2.8,
                      _ => 1.8,
                    };
                    final opacity = switch (distance) {
                      0 => 0.0,
                      1 => .55,
                      2 => .3,
                      _ => .15,
                    };
                    return Positioned(
                      left: offset * 12,
                      top: 0,
                      width: 12,
                      height: 8,
                      child: Center(
                        child: distance == 0
                            ? const SizedBox.shrink()
                            : AnimatedContainer(
                                duration: duration,
                                curve: Curves.easeOutCubic,
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: foreground.withValues(alpha: opacity),
                                ),
                              ),
                      ),
                    );
                  }),
                  // A single highlight moves between the smaller inactive dots.
                  AnimatedPositioned(
                    key: const ValueKey('carousel-active-dot'),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: (active - firstDot) * 12 + 2,
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
    );
  }
}
