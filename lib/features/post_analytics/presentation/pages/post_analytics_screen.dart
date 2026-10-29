import 'package:flutter/material.dart';
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

class PostAnalyticsScreen extends StatelessWidget {
  const PostAnalyticsScreen({super.key, required this.post});
  final PostItem post;
  @override
  Widget build(BuildContext context) {
    final existing = context.read<PostAnalyticsCubit?>();
    if (existing != null) {
      existing.load();
      return _PostAnalyticsView(post: post);
    }
    return BlocProvider(
      create: (_) => PostAnalyticsCubit(LocalPostAnalyticsRepository())..load(),
      child: _PostAnalyticsView(post: post),
    );
  }
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
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
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
                            style: TextStyle(fontSize: 11),
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
