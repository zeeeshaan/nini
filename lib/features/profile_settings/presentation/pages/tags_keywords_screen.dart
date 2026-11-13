import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';

import '../cubit/settings_query_cubit.dart';
import '../widgets/common/settings_page.dart';
import '../widgets/common/settings_posts_content.dart';
import '../widgets/common/settings_search_field.dart';
import '../widgets/tags_keywords/tags_keywords_list.dart';

class TagsKeywordsScreen extends StatelessWidget {
  const TagsKeywordsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsQueryCubit(),
    child: SettingsPage(
      title: ProfileSettingsStrings.tags,
      child: Column(
        children: [
          const SettingsSearchField(),
          Expanded(
            child: SettingsPostsContent(
              builder: (context, posts) => TagsKeywordsList(posts: posts),
            ),
          ),
        ],
      ),
    ),
  );
}
