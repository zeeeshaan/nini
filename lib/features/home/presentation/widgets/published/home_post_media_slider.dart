import 'package:flutter/material.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_image_carousel.dart';
import 'package:nini/shared/models/post/post_item.dart';

class HomePostMediaSlider extends StatelessWidget {
  const HomePostMediaSlider({
    super.key,
    required this.post,
    required this.onTap,
  });
  final PostItem post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: PostImageCarousel(
      key: ValueKey(post.media.map((media) => media.path).join('|')),
      media: post.media,
      images: [post.imageAsset],
      mediaFit: BoxFit.cover,
    ),
  );
}
