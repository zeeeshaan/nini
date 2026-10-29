import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/shared/models/post/post_media.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/post_media/post_media_view.dart';

class PostImageCarousel extends StatefulWidget {
  const PostImageCarousel({
    super.key,
    this.images = const [],
    this.media = const [],
  });

  final List<String> images;
  final List<PostMedia> media;

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.media.isNotEmpty
        ? widget.media.length
        : widget.images.length;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: count,
              onPageChanged: (index) {
                context.read<PostDetailCubit>().changeImage(index);
              },
              itemBuilder: (context, index) {
                if (widget.media.isNotEmpty) {
                  return PostMediaView(
                    media: widget.media[index],
                    fit: BoxFit.contain,
                  );
                }
                return Image.asset(
                  widget.images[index],
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Center(
                        child: AppIcon(AppIcons.imageUnavailable, size: 40),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (count > 1)
            Positioned(
              left: 28,
              bottom: 18,
              child: BlocBuilder<PostDetailCubit, PostDetailState>(
                buildWhen: (previous, current) =>
                    previous.imageIndex != current.imageIndex,
                builder: (context, state) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (index) {
                      final isActive = index == state.imageIndex;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 5),
                        width: isActive ? 22 : 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white70,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
