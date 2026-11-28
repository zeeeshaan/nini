import 'package:hywork/features/cart/models/cart_order.dart';
import 'package:hywork/features/cart/utils/order_access.dart';
import 'package:hywork/features/post_analytics/domain/post_analytics.dart';
import 'package:hywork/shared/models/post/post_item.dart';

enum InsightMetric {
  posts,
  views,
  interactions,
  bookings,
  sales,
  trendingServices,
}

/// Only recorded local activity is counted; demo receipts and other sellers
/// are excluded. These values are not marketplace-wide statistics.
class LocalPostInsights {
  LocalPostInsights({
    required List<PostItem> posts,
    required List<PostAnalyticsEvent> events,
    List<CartOrder> orders = const [],
    String userId = '',
  }) {
    publishedPosts = posts.where((post) => post.isPublished).toList();
    final ids = publishedPosts.map((post) => post.id).toSet();
    final now = DateTime.now();
    ownEvents = events
        .where((event) => ids.contains(event.postId) && !event.at.isAfter(now))
        .toList();
    providerOrders = orders
        .where(
          (order) =>
              !order.isDemoPayment && OrderAccess.isProvider(order, userId),
        )
        .toList();
    for (final event in ownEvents) {
      if (event.type == AnalyticsEventType.view ||
          event.type == AnalyticsEventType.interaction) {
        scores.update(
          event.postId,
          (value) => value + event.value,
          ifAbsent: () => event.value,
        );
      }
    }
  }

  late final List<PostItem> publishedPosts;
  late final List<PostAnalyticsEvent> ownEvents;
  late final List<CartOrder> providerOrders;
  final Map<String, double> scores = {};

  List<PostItem> get trending =>
      publishedPosts.where((post) => (scores[post.id] ?? 0) > 0).toList()
        ..sort((a, b) {
          final rank = scores[b.id]!.compareTo(scores[a.id]!);
          return rank != 0 ? rank : a.id.compareTo(b.id);
        });

  num value(InsightMetric metric) => switch (metric) {
    InsightMetric.posts => publishedPosts.length,
    InsightMetric.views =>
      ownEvents
          .where((event) => event.type == AnalyticsEventType.view)
          .fold(0.0, (sum, event) => sum + event.value),
    InsightMetric.interactions =>
      ownEvents
          .where((event) => event.type == AnalyticsEventType.interaction)
          .fold(0.0, (sum, event) => sum + event.value),
    InsightMetric.bookings =>
      providerOrders
          .where((order) => order.items.any((item) => item.isService))
          .length,
    InsightMetric.sales =>
      providerOrders
          .where((order) => order.status == CartOrderStatus.completed)
          .length,
    InsightMetric.trendingServices =>
      trending.where((post) => post.isService).length,
  };
}
