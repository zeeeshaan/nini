import '../app_string/app_string.dart';

/// English interface text for the notification preview and its accessibility labels.
abstract final class NotificationStrings {
  static const title = "Notifications";
  static const search = "Search notifications";
  static const clearSearch = "Clear search";
  static const noResults = "No notifications match your search.";
  static const empty = "No notifications yet.";
  static const now = "Now";
  static String minutesAgo(int count) =>
      '${AppStrings.persianDigits(count)} minutes ago';
  static String hoursAgo(int count) =>
      '${AppStrings.persianDigits(count)} hours ago';
  static String daysAgo(int count) =>
      '${AppStrings.persianDigits(count)} days ago';
  static const minuteAgo = "1m ago";
  static const brand = 'HYWORK';
  static const newOrder = "You have a new order.";
  static const saleTitle = "SALE IS LIVE";
  static const saleMessage =
      "The sale has started. Do not miss the latest offers.";
}
