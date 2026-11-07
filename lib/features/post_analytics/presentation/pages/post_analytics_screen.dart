import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_analytics/data/post_analytics_repository.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_header/analytics_header.dart';
import 'package:nini/features/post_analytics/presentation/widgets/average_time_viewed/average_time_viewed.dart';
import 'package:nini/features/post_analytics/presentation/widgets/clicks_interactions/clicks_interactions.dart';
import 'package:nini/features/post_analytics/presentation/widgets/impressions/impressions.dart';
import 'package:nini/features/post_analytics/presentation/widgets/orders_bookings/orders_bookings.dart';
import 'package:nini/features/post_analytics/presentation/widgets/total_views/total_views.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_loader/app_loader.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';

class PostAnalyticsScreen extends StatelessWidget {
  const PostAnalyticsScreen({super.key, required this.post});
  final PostItem post;
  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostsCubit?>()?.state;
    final ownedPost = posts?.find(post.id);
    if (ownedPost == null || posts?.canViewAnalytics(ownedPost) != true) {
      return _AnalyticsAccessNotice(loading: posts?.isLoading == true);
    }
    final existing = context.read<PostAnalyticsCubit?>();
    if (existing != null) {
      existing.load();
      return _PostAnalyticsView(post: ownedPost);
    }
    return BlocProvider(
      create: (_) => PostAnalyticsCubit(LocalPostAnalyticsRepository())..load(),
      child: _PostAnalyticsView(post: ownedPost),
    );
  }
}

class _AnalyticsAccessNotice extends StatelessWidget {
  const _AnalyticsAccessNotice({required this.loading});
  final bool loading;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: AppStrings.back,
        icon: const AppIcon(AppIcons.back, size: 19),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: loading
              ? const AppLoader()
              : const Text(
                  AppStrings.analyticsOwnerOnly,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
        ),
      ),
    ),
  );
}

class _PostAnalyticsView extends StatelessWidget {
  const _PostAnalyticsView({required this.post});
  final PostItem post;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 48,
      leading: IconButton(
        tooltip: AppStrings.back,
        icon: const AppIcon(AppIcons.back, size: 19),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        AppStrings.analytics,
        style: AppTextStyles.analyticsTitle,
      ),
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: BlocBuilder<PostAnalyticsCubit, PostAnalyticsState>(
            builder: (context, state) {
              PostAnalyticsReport report(AnalyticsPeriod period) =>
                  post.isPublished
                  ? PostAnalyticsReport.fromEvents(
                      state.events
                          .where((event) => event.postId == post.id)
                          .toList(),
                      period,
                      DateTime.now(),
                    )
                  : PostAnalyticsReport.sample(period);
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      AnalyticsPostHeader(post: post),
                      const SizedBox(height: 14),
                      if (state.storageError && post.isPublished)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            AppStrings.analyticsSaveFailed,
                            style: AppTextStyles.helper,
                          ),
                        ),
                      TotalViewsSection(reportForPeriod: report),
                      const SizedBox(height: 78),
                      ClicksInteractionsSection(reportForPeriod: report),
                      const SizedBox(height: 82),
                      AverageTimeViewedSection(reportForPeriod: report),
                      const SizedBox(height: 82),
                      ImpressionsSection(reportForPeriod: report),
                      const SizedBox(height: 66),
                      OrdersBookingsSection(
                        report: report(AnalyticsPeriod.halfYear),
                      ),
                      const SizedBox(height: 160),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
