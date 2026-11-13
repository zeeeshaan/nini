import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';

import '../cubit/insights_metric_cubit.dart';
import '../widgets/common/settings_page.dart';
import '../widgets/common/settings_posts_content.dart';
import '../widgets/insights/insights_content.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    context.read<PostAnalyticsCubit>().load();
    return BlocProvider(
      create: (_) => InsightsMetricCubit(),
      child: SettingsPage(
        title: ProfileSettingsStrings.insights,
        child: SettingsPostsContent(
          builder: (context, posts) => InsightsContent(posts: posts),
        ),
      ),
    );
  }
}
