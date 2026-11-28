import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/cubit/cart_cubit.dart';
import 'package:hywork/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/skeleton/list_tile_skeleton.dart';

import '../../../domain/local_post_insights.dart';
import '../../cubit/insights_metric_cubit.dart';
import '../common/settings_notice.dart';
import 'insights_unavailable_groups.dart';

String insightMetricLabel(InsightMetric metric) => switch (metric) {
  InsightMetric.posts => ProfileSettingsStrings.totalPosts,
  InsightMetric.views => ProfileSettingsStrings.views,
  InsightMetric.interactions => ProfileSettingsStrings.interactions,
  InsightMetric.bookings => ProfileSettingsStrings.bookings,
  InsightMetric.sales => ProfileSettingsStrings.sales,
  InsightMetric.trendingServices => ProfileSettingsStrings.trendingServices,
};

class InsightsContent extends StatelessWidget {
  const InsightsContent({super.key, required this.posts});
  final List<PostItem> posts;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PostAnalyticsCubit, PostAnalyticsState>(
    builder: (context, analytics) {
      final cart = context.watch<CartCubit>();
      final selected = context.watch<InsightsMetricCubit>().state;
      final values = LocalPostInsights(
        posts: posts,
        events: analytics.events,
        orders: cart.state.orders,
        userId: cart.localUser.id,
      );
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const SettingsNotice(text: ProfileSettingsStrings.analyticsHelp),
          if (analytics.loading) const ListTileSkeleton(showAvatar: false),
          if (analytics.storageError)
            const SettingsNotice(text: ProfileSettingsStrings.analyticsFailed),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              ProfileSettingsStrings.postStatistics,
              textAlign: TextAlign.right,
              style: AppTextStyles.sectionTitle,
              textDirection: TextDirection.ltr,
            ),
          ),
          RadioGroup<InsightMetric>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) {
                context.read<InsightsMetricCubit>().select(value);
              }
            },
            child: Column(
              children: [
                for (final metric in InsightMetric.values)
                  RadioListTile<InsightMetric>(
                    value: metric,
                    title: Text(
                      insightMetricLabel(metric),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body,
                      textDirection: TextDirection.ltr,
                    ),
                    subtitle: Text(
                      (analytics.storageError || analytics.loading) &&
                                  (metric == InsightMetric.views ||
                                      metric == InsightMetric.interactions ||
                                      metric ==
                                          InsightMetric.trendingServices) ||
                              (cart.state.loading || cart.state.storageError) &&
                                  (metric == InsightMetric.bookings ||
                                      metric == InsightMetric.sales)
                          ? '—'
                          : AppStrings.persianDigits(values.value(metric)),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyEmphasis,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
              ],
            ),
          ),
          const InsightsUnavailableGroups(),
        ],
      );
    },
  );
}
