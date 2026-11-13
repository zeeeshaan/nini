import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';

import '../cubit/settings_query_cubit.dart';
import '../widgets/common/settings_page.dart';
import '../widgets/common/settings_posts_content.dart';
import '../widgets/common/settings_search_field.dart';
import '../widgets/posts/settings_posts_list.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key, this.initialQuery = '', this.tag});
  final String initialQuery;
  final String? tag;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsQueryCubit(initialQuery),
    child: SettingsPage(
      title: ProfileSettingsStrings.posts,
      child: Column(
        children: [
          const SettingsSearchField(),
          Expanded(
            child: SettingsPostsContent(
              builder: (context, posts) =>
                  SettingsPostsList(posts: posts, tag: tag),
            ),
          ),
        ],
      ),
    ),
  );
}
