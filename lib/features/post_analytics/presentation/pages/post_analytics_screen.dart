import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/security/account_storage/account_storage.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/post_analytics/data/post_analytics_repository.dart';
import 'package:hywork/features/post_analytics/domain/post_analytics.dart';
import 'package:hywork/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/common/analytics_header.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/metrics/average_time_viewed.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/metrics/clicks_interactions.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/metrics/impressions.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/metrics/orders_bookings.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/metrics/total_views.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_loader/app_loader.dart';
import 'package:hywork/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:hywork/shared/widgets/skeleton/list_tile_skeleton.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';

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
    final session = context.read<SessionCubit?>()?.state;
    if (session?.status != SessionStatus.authenticated ||
        session?.userId == null) {
      return const _AnalyticsAccessNotice(loading: false);
    }
    return BlocProvider(
      create: (_) => PostAnalyticsCubit(
        LocalPostAnalyticsRepository(
          directoryProvider: AccountStorage(session!.userId!).directory,
        ),
      )..load(),
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
      automaticallyImplyLeading: false,

      actions: [
        IconButton(
          tooltip: AppStrings.back,
          icon: const AppIcon(AppIcons.backRight, size: 19),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: loading
              ? const AppLoader()
              : const Text(
                  AppStrings.analyticsOwnerOnly,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body,
                  textDirection: TextDirection.ltr,
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
      title: Align(
        alignment: Alignment.centerRight,
        child: const Text(
          AppStrings.analytics,
          style: AppTextStyles.analyticsTitle,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        ),
      ),

      actions: [
        IconButton(
          tooltip: AppStrings.back,
          icon: const AppIcon(AppIcons.backRight, size: 19),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: BlocBuilder<PostAnalyticsCubit, PostAnalyticsState>(
            builder: (context, state) {
              if (state.loading && state.events.isEmpty) {
                return AppShimmer(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: 6,
                    itemBuilder: (_, index) => const ListTileSkeleton(
                      showAvatar: false,
                      animated: false,
                    ),
                  ),
                );
              }
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
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
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
