
import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/widgets/skeleton/detail_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/list_tile_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/message_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/post_card_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/product_card_skeleton.dart';
import 'package:nini/shared/widgets/skeleton/profile_skeleton.dart';


class ShimmerPreviewScreen extends StatelessWidget {
  const ShimmerPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Shimmer Preview',
          textAlign: TextAlign.right,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Skeleton Loading Preview',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyText.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'These placeholders appear while content is loading.',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                // Home feed.
                _sectionTitle(context, 'Home Post'),
                const PostCardSkeleton(),

                const SizedBox(height: 32),

                // Search and marketplace.
                _sectionTitle(context, 'Product Card'),
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: ProductCardSkeleton(),
                  ),
                ),

                const SizedBox(height: 32),

                // User and seller profiles.
                _sectionTitle(context, 'Profile'),
                const ProfileSkeleton(),

                const SizedBox(height: 32),

                // Inbox and notifications.
                _sectionTitle(context, 'List Items'),
                const ListTileSkeleton(),
                const ListTileSkeleton(),
                const ListTileSkeleton(),

                const SizedBox(height: 32),

                // Chat messages.
                _sectionTitle(context, 'Chat Messages'),
                const MessageSkeleton(messageCount: 5),

                const SizedBox(height: 32),

                // Post details.
                _sectionTitle(context, 'Post Details'),
                const DetailsSkeleton(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
      BuildContext context,
      String title,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodyText.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
