import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/saved_posts_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

import '../../domain/saved_post.dart';
import '../cubit/saved_posts_cubit.dart';
import '../widgets/common/saved_posts_grid.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  Future<void> _remove(BuildContext context, SavedPost entry) async {
    final success = await context.read<SavedPostsCubit>().remove(entry.post.id);
    if (!success && context.mounted) {
      AppToast.show(
        context,
        message: SavedPostsStrings.saveFailed,
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) => ScreenEntrance(
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Align(
          alignment: Alignment.centerRight,
          child: Text(
            SavedPostsStrings.title,
            textAlign: TextAlign.right,
            style: AppTextStyles.pageTitle,
          ),
        ),

        actions: [
          IconButton(
            tooltip: AppStrings.back,
            onPressed: () => Navigator.of(context).pop(),
            icon: const AppIcon(AppIcons.backRight, size: 18),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AppResponsiveBuilder(
          builder: (context, responsive) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: responsive.adaptive<double>(
                  compact: 600,
                  medium: 600,
                  expanded: 720,
                ),
              ),
              child: BlocBuilder<SavedPostsCubit, SavedPostsState>(
                builder: (context, state) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if ((state.loading && state.posts.isNotEmpty) ||
                          state.saving)
                        const LinearProgressIndicator(minHeight: 2),
                      if (state.loadFailed || state.storageError)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                state.loadFailed
                                    ? SavedPostsStrings.loadFailed
                                    : SavedPostsStrings.saveFailed,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.body,
                              ),
                              TextButton(
                                onPressed: state.loading || state.saving
                                    ? null
                                    : () => context
                                          .read<SavedPostsCubit>()
                                          .load(),
                                child: const Text(AppStrings.retry),
                              ),
                            ],
                          ),
                        ),
                      if (!state.loading &&
                          !state.loadFailed &&
                          state.posts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppIcon(AppIcons.bookmark, size: 40),
                              SizedBox(height: 12),
                              Text(
                                SavedPostsStrings.empty,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.sectionTitle,
                              ),
                              SizedBox(height: 8),
                              Text(
                                SavedPostsStrings.emptyHelp,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      if (state.posts.isNotEmpty || state.loading)
                        SavedPostsGrid(
                          loading: state.loading && state.posts.isEmpty,
                          posts: state.posts,
                          saving: state.saving,
                          onRemove: (entry) => _remove(context, entry),
                          onPostTap: (entry) =>
                              Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(
                                    post: entry.post,
                                    seller: entry.seller,
                                  ),
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
      ),
    ),
  );
}
