import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../../../domain/local_post_insights.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_notice.dart';
import '../common/settings_posts_grid.dart';

class TrendingGrid extends StatelessWidget {
  const TrendingGrid({super.key, required this.posts});
  final List<PostItem> posts;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostAnalyticsCubit, PostAnalyticsState>(
        builder: (context, state) {
          if (state.loading && state.events.isEmpty) {
            return const SettingsPostsGrid(
              loading: true,
              gridDirection: TextDirection.rtl,
            );
          }
          final ranked = LocalPostInsights(
            posts: posts,
            events: state.events,
          ).trending;
          if (state.storageError && ranked.isEmpty) {
            return const SettingsEmptyState(
              title: ProfileSettingsStrings.analyticsFailed,
              message: ProfileSettingsStrings.localActivity,
              icon: AppIcons.analytics,
            );
          }
          if (ranked.isEmpty) {
            return const SettingsEmptyState(
              title: ProfileSettingsStrings.noTrending,
              message: ProfileSettingsStrings.trendingHelp,
              icon: AppIcons.analytics,
            );
          }
          return Column(
            children: [
              const SettingsNotice(text: ProfileSettingsStrings.localActivity),
              if (state.storageError)
                const SettingsNotice(
                  text: ProfileSettingsStrings.analyticsFailed,
                ),
              Expanded(
                child: SettingsPostsGrid(
                  posts: ranked,
                  gridDirection: TextDirection.rtl,
                ),
              ),
            ],
          );
        },
      );
}
