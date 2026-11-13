import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';

import '../widgets/common/settings_page.dart';
import '../widgets/common/settings_posts_content.dart';
import '../widgets/trending/trending_grid.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    context.read<PostAnalyticsCubit>().load();
    return SettingsPage(
      title: ProfileSettingsStrings.trending,
      child: SettingsPostsContent(
        builder: (context, posts) => TrendingGrid(posts: posts),
      ),
    );
  }
}
