import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';

class HomePostMediaIndicator extends StatelessWidget {
  const HomePostMediaIndicator({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostDetailCubit, PostDetailState>(
        buildWhen: (previous, current) =>
            previous.imageIndex != current.imageIndex,
        builder: (context, state) {
          final active = state.imageIndex.clamp(0, count - 1);
          final visibleCount = count > 5 ? 5 : count;
          final first = (active - 2).clamp(0, count - visibleCount);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: List.generate(visibleCount, (offset) {
                  final distance = (first + offset - active).abs();
                  final size = switch (distance) {
                    0 => 8.0,
                    1 => 5.0,
                    _ => 3.0,
                  };
                  final opacity = switch (distance) {
                    0 => 1.0,
                    1 => .5,
                    _ => .25,
                  };
                  return SizedBox(
                    width: 14,
                    height: 12,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: opacity),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      );
}
