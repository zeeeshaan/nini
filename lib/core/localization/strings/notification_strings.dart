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
  static const loadFailed = "Could not load notifications. Please try again.";
  static const markReadFailed = "Could not mark the notification as read.";
  static const signInRequired = "Sign in to view notifications.";
  static const openFailed = "This notification destination is unavailable.";
  static const openUnsupported = "This notification type cannot be opened yet.";
}
