import 'package:flutter/material.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_image_carousel.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'home_post_media_indicator.dart';

class HomePostMediaSlider extends StatelessWidget {
  const HomePostMediaSlider({
    super.key,
    required this.post,
    required this.onTap,
  });
  final PostItem post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = post.media.isEmpty ? 1 : post.media.length;
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          child: PostImageCarousel(
            key: ValueKey(post.media.map((media) => media.path).join('|')),
            media: post.media,
            images: [post.imageAsset],
            mediaFit: BoxFit.cover,
            showIndicators: false,
          ),
        ),
        if (count > 1)
          Positioned(
            bottom: 18,
            left: 28,
            child: IgnorePointer(
              child: HomePostMediaIndicator(count: count),
            ),
          ),
      ],
    );
  }
}
