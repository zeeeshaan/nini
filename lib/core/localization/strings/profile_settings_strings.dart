import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/notification_strings.dart';

/// Labels shared by Profile Settings and its detail screens.
abstract final class ProfileSettingsStrings {
  static const title = "Settings";
  static const logout = 'Log out';
  static const logoutTitle = 'Log out?';
  static const logoutConfirmation = 'Are you sure you want to log out?';
  static const loggingOut = 'Logging out…';
  static const logoutFailed = 'Could not log out. Please try again.';
  static const logoutTimeout =
      'Logout could not be confirmed because the request timed out. Please try again.';
  static const logoutConnectionFailed =
      'Could not connect to log out. Check your internet connection and try again.';
  static const logoutServerFailed =
      'The server did not confirm logout. Please try again.';
  static const logoutCleanupFailed =
      'Your server session has ended, but the saved login could not be removed. Please retry to finish logging out.';
  static const general = "General";
  static const myTeam = "My Team";
  static const profile = "Profile settings";
  static const locations = "Locations";
  static const wallet = "Wallet";
  static const saved = "Saved";
  static const notifications = NotificationStrings.title;
  static const trending = "Trending";
  static const insights = "Insights";
  static const scheduledContent = "Scheduled content";
  static const blocked = "Blocked";
  static const comments = AppStrings.comments;
  static const language = "Language";
  static const devicePermissions = "Device permissions";
  static const accessibility = "Accessibility";
  static const posts = AppStrings.posts;
  static const myMedia = "My media";
  static const tags = AppStrings.tagsKeywords;
  static const archive = "Archive";
  static const searchHint = 'Search';
  static const noResults = 'No results found';
  static const tryAnotherSearch = 'Try another search.';
  static const localActivity = 'Activity recorded on this device';
  static const noTrending = 'No trending posts yet';
  static const trendingHelp =
      'Your published posts appear here when they have recorded views or interactions. This is not a global ranking.';
  static const noScheduled = 'No scheduled content';
  static const scheduledHelp =
      'Add a schedule in the post editor to see it here.';
  static const scheduleNotice =
      'These are saved post schedules. Automatic publishing is not connected.';
  static const viewPost = 'View post';
  static const editPost = 'Edit post';
  static const noBlocked = 'No blocked users';
  static const blockedHelp =
      'People you block appear here. You can unblock them at any time.';
  static const blockedConversation = 'Blocked user';
  static const unblock = 'Unblock';
  static const sessionBlocks =
      'Blocked accounts are saved on your HYWORK profile.';
  static const blockedLoadFailed = 'Could not load blocked users. Try again.';
  static const blockedSignInRequired =
      'Please sign in to manage blocked users.';
  static const unblockFailed = 'Could not unblock this user. Try again.';
  static const unblockSuccess = 'User unblocked.';
  static const noCommentHistory = 'No saved comment history';
  static const commentsHelp =
      'The current post comment sheet is a temporary preview. A comment-history data source is not connected yet.';
  static const english = 'English';
  static const persian = 'Persian';
  static const languageHelp = 'English is enabled for app testing.';
  static const notAvailable = 'Not available yet';
  static const photoLibrary = 'Photos and videos';
  static const location = 'Location';
  static const microphone = 'Microphone';
  static const permissionHelp =
      'Manage access in your device settings. Return here to refresh the current status.';
  static const openDeviceSettings = 'Open device settings';
  static const permissionFailed =
      'Could not read device permissions. Try again.';
  static const settingsFailed = 'Could not open device settings.';
  static const granted = 'Allowed';
  static const denied = 'Not granted';
  static const restricted = 'Restricted by the device';
  static const limited = 'Limited access';
  static const unknown = 'Status unavailable';
  static const noMedia = 'No uploaded media yet';
  static const mediaHelp =
      'Photos, videos and files attached to your posts appear here.';
  static const mediaNotice =
      'Manage attachments in the existing post editor. Shared media files are not deleted from this screen.';
  static const noTags = 'No tags or keywords yet';
  static const tagsHelp = 'Add tags in Create Post or edit an existing post.';
  static const tagsNotice =
      'Tap a keyword to view its posts and edit their tags.';
  static const noArchive = 'No archive is connected';
  static const archiveHelp =
      'Posts cannot be archived in the current app. An archive data source and archive/restore operations are required before items can appear here.';
  static const postStatistics = 'Posts and services statistics';
  static const customerStatistics = 'Statistics of users and customers';
  static const alerts = 'Alerts and reminders';
  static const totalPosts = 'Total posts';
  static const views = 'Views';
  static const interactions = 'Interactions';
  static const bookings = 'Bookings';
  static const sales = 'Sales';
  static const trendingServices = 'Trending services';
  static const newFollowers = 'New followers';
  static const topCustomers = 'Top customers';
  static const feedback = 'Feedback';
  static const usageReminder = 'Usage limit reminder';
  static const unansweredMessages = 'Unanswered messages';
  static const backendRequired = 'Requires a connected backend';
  static const analyticsFailed = 'Could not load the local analytics history.';
  static const analyticsHelp =
      'Counts use your published posts, recorded local events and non-demo provider orders. They are not server-wide statistics.';
  static String tagPosts(int count) =>
      '$count ${count == 1 ? 'post' : 'posts'}';
}
