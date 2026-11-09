import 'dart:ui';

/// The app's shared color palette.
///
/// Define fixed colors here. For colors that change with light/dark mode, use
/// `Theme.of(context).colorScheme` in widgets; AppTheme builds it from this palette.
abstract final class AppColors {
  // Common colors.
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFFF0000);
  static const white70 = Color(0xB3FFFFFF);

  // Light and dark theme surfaces and borders.
  static const lightSurfaceContainer = Color(0xFFF2F2F2);
  static const darkSurfaceContainer = Color(0xFF202020);
  static const lightOutline = Color(0xFFDADADA);
  static const darkOutline = Color(0xFF666666);
  static const bottomNavHighlight = Color(0xFF26292E);

  // Loading placeholders and their shimmer highlights.
  static const skeletonLightBase = Color(0xFFE5E5E5);
  static const skeletonLightHighlight = Color(0xFFF8F8F8);
  static const skeletonDarkBase = Color(0xFF2B2B2B);
  static const skeletonDarkHighlight = Color(0xFF454545);

  static const cartThumbnail = Color(0xFFEFF3F4);
  static const walletCredit = Color(0xFF00D600);
  static const walletPending = Color(0xFFFFB000);

  // Indicators. Keep the existing shades distinct.
  static const notificationBadge = Color(0xFFFF0000);
  static const cartBadge = Color(0xFFFF2020);
  static const stockBadgeBackground = Color(0xFFFFEEEE);
  static const authorOnline = Color(0xFF00CB28);
  static const profileFollow = Color(0xFF4C5BFF);
  static const profileMessageBackground = Color(0xFFE7E7E7);
  static const analyticsOnline = Color(0xFF00C83C);

  // Analytics chart series.
  static const analyticsPurple = Color(0xFF9C83FF);
  static const analyticsGold = Color(0xFFFFBC00);
  static const analyticsBlue = Color(0xFF009CFF);
  static const analyticsPink = Color(0xFFFFA4DC);
  static const analyticsOrders = Color(0xFF2F80ED);

  // Call actions and video overlays (including their original alpha values).
  static const callEnd = Color(0xFFFF454D);
  static const callAccept = Color(0xFF31EF73);
  static const callMessage = Color(0xFFFFD447);
  static const videoPlaceholder = Color(0xFF333333);
  static const videoGradientTop = Color(0x44000000);
  static const videoGradientBottom = Color(0xCC000000);
  static const videoBackButton = Color(0x55000000);
  static const videoSwitchButton = Color(0x66000000);

  // Attachment preview badges.
  static const pdfBadge = Color(0xFFEE5969);
  static const videoBadge = Color(0xFFA64CE6);
}
