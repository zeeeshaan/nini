import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/shared/models/post/post_item.dart';

import '../../cubit/settings_query_cubit.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_posts_grid.dart';

class SettingsPostsList extends StatelessWidget {
  const SettingsPostsList({super.key, required this.posts, this.tag});
  final List<PostItem> posts;
  final String? tag;
  @override
  Widget build(BuildContext context) => BlocBuilder<SettingsQueryCubit, String>(
    builder: (context, query) {
      final matches = posts
          .where(
            (post) =>
                (tag == null || post.details.tags.contains(tag)) &&
                '${post.title} ${post.caption} ${post.details.tags.join(' ')}'
                    .toLowerCase()
                    .contains(query),
          )
          .toList();
      if (matches.isEmpty) {
        return SettingsEmptyState(
          title: query.isEmpty
              ? ProfilePostStrings.noPublishedPosts
              : ProfileSettingsStrings.noResults,
          message: query.isEmpty
              ? ProfileSettingsStrings.tagsHelp
              : ProfileSettingsStrings.tryAnotherSearch,
        );
      }
      return SettingsPostsGrid(
        posts: matches,
        gridDirection: TextDirection.rtl,
      );
    },
  );
}
