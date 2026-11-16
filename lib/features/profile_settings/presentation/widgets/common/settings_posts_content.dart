import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'settings_empty_state.dart';
import 'settings_posts_grid.dart';

class SettingsPostsContent extends StatelessWidget {
  const SettingsPostsContent({super.key, required this.builder});
  final Widget Function(BuildContext context, List<PostItem> posts) builder;

  @override
  Widget build(BuildContext context) => BlocBuilder<PostsCubit, PostsState>(
    buildWhen: (previous, current) =>
        previous.posts != current.posts ||
        previous.isLoading != current.isLoading ||
        previous.loadFailed != current.loadFailed,
    builder: (context, state) {
      if (state.isLoading && state.posts.isEmpty) {
        return const SettingsPostsGrid(loading: true);
      }
      if (state.loadFailed && state.posts.isEmpty) {
        return SettingsEmptyState(
          title: AppStrings.savedPostsLoadFailed,
          message: AppStrings.retry,
          onRetry: context.read<PostsCubit>().load,
        );
      }
      return Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (state.loadFailed)
            TextButton(
              onPressed: context.read<PostsCubit>().load,
              child: const Text(
                AppStrings.retry,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          Expanded(child: builder(context, state.posts)),
        ],
      );
    },
  );
}
