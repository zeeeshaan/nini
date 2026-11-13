import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';

import '../cubit/settings_query_cubit.dart';
import '../widgets/common/settings_page.dart';
import '../widgets/common/settings_posts_content.dart';
import '../widgets/common/settings_search_field.dart';
import '../widgets/my_media/my_media_grid.dart';

class MyMediaScreen extends StatelessWidget {
  const MyMediaScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsQueryCubit(),
    child: SettingsPage(
      title: ProfileSettingsStrings.myMedia,
      child: Column(
        children: [
          const SettingsSearchField(),
          Expanded(
            child: SettingsPostsContent(
              builder: (context, posts) => MyMediaGrid(posts: posts),
            ),
          ),
        ],
      ),
    ),
  );
}
