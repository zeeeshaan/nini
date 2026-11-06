import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/home/presentation/helpers/published_home_navigation.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/widgets/pricing/post_pricing.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../home_post_media_slider/home_post_media_slider.dart';
import '../home_engagement_bar/home_engagement_bar.dart';
import '../home_seller_header/home_seller_header.dart';

class HomePublishedPostCard extends StatelessWidget {
  const HomePublishedPostCard({super.key, required this.post});
  final PostItem post;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PostDetailCubit(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSellerHeader(
          seller: localPostSeller,
          onPressed: () => openPublishedHomeSeller(context, post),
        ),
        HomePostMediaSlider(
          post: post,
          onTap: () => openPublishedHomePost(context, post),
        ),
        BlocBuilder<PostDetailCubit, PostDetailState>(
          buildWhen: (previous, current) =>
              previous.isLiked != current.isLiked ||
              previous.isBookmarked != current.isBookmarked,
          builder: (context, state) => HomeEngagementBar(
            isLiked: state.isLiked,
            isBookmarked: state.isBookmarked,
            showSampleMetrics: false,
            onLike: context.read<PostDetailCubit>().toggleLike,
            onBookmark: context.read<PostDetailCubit>().toggleBookmark,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => openPublishedHomePost(context, post),
                child: Text(
                  post.title,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: AppTextStyles.bold),
                ),
              ),
              const SizedBox(height: 6),
              Text(post.category, textAlign: TextAlign.right),
              if (post.caption.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.caption,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (post.price.isNotEmpty) ...[
                const SizedBox(height: 12),
                PostPricing(post: post, showCurrency: true),
              ],
            ],
          ),
        ),
        const Divider(height: 1, thickness: .5),
      ],
    ),
  );
}
