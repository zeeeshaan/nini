import 'package:flutter/material.dart';

/// Semantic typography. Colors and text direction remain owned by the UI.
abstract final class AppTextStyles {
  static const fontFamily = 'YekanBakh';

  // Match the existing Material text theme for general-purpose app text.
  static const heading = TextStyle(fontSize: 22, fontWeight: regular);
  static const body = TextStyle(fontSize: 14, fontWeight: regular);
  static const button = TextStyle(fontSize: 14, fontWeight: medium);
  static const caption = TextStyle(fontSize: 14, fontWeight: regular);

  static const username = TextStyle(fontSize: 16, fontWeight: semiBold);
  static const profileName = TextStyle(fontSize: 14, fontWeight: bold);
  static const bio = TextStyle(fontSize: 14, fontWeight: regular);
  static const website = TextStyle(fontSize: 14, fontWeight: regular);
  static const statNumber = TextStyle(fontSize: 14, fontWeight: bold);
  static const statLabel = TextStyle(fontSize: 14, fontWeight: regular);
  static const category = TextStyle(fontSize: 14, fontWeight: regular);

  // Readable profile-card roles. Keep these sizes independent of card width.
  static const postTitle = TextStyle(
    fontSize: 14,
    fontWeight: bold,
    height: 1.25,
  );
  static const listingTitle = TextStyle(fontWeight: bold);
  static const postMetadata = TextStyle(fontSize: 12, height: 1.25);
  static const postStock = TextStyle(
    fontSize: 12,
    fontWeight: bold,
    height: 1.25,
  );
  static const originalPrice = TextStyle(fontSize: 12, height: 1.1);
  static const postPrice = TextStyle(
    fontSize: 18,
    fontWeight: heavy,
    height: 1.1,
  );
  static const postCardHeading = postPrice;
  static const pricePrefix = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.2,
  );
  static const discountBadge = TextStyle(
    fontSize: 11,
    fontWeight: bold,
    height: 1,
  );
  static const notificationBadge = TextStyle(fontSize: 9, fontWeight: semiBold);
  static const screenTitle = TextStyle(fontSize: 24, fontWeight: medium);
  static const sectionTitle = TextStyle(fontSize: 17, fontWeight: bold);
  static const settingsLabel = TextStyle(fontSize: 15);
  static const settingsDetailTitle = TextStyle(
    fontSize: 18,
    fontWeight: medium,
  );

  // App-wide roles preserving the existing screen designs.
  static const inherit = TextStyle();
  static const badgeSmall = TextStyle(fontSize: 7);
  static const micro = TextStyle(fontSize: 8);
  static const metadata = TextStyle(fontSize: 9);
  static const metadataBold = TextStyle(fontSize: 9, fontWeight: bold);
  static const smallPrint = TextStyle(fontSize: 10);
  static const smallPrintMedium = TextStyle(fontSize: 10, fontWeight: medium);
  static const smallPrintEmphasis = TextStyle(
    fontSize: 10,
    fontWeight: semiBold,
  );
  static const smallPrintBold = TextStyle(fontSize: 10, fontWeight: bold);
  static const helper = TextStyle(fontSize: 11);
  static const helperBold = TextStyle(fontSize: 11, fontWeight: bold);
  static const badgeLabel = TextStyle(fontSize: 11, height: 1.2);
  static const notificationBody = TextStyle(fontSize: 11, height: 1.5);
  static const label = TextStyle(fontSize: 12);
  static const labelMedium = TextStyle(fontSize: 12, fontWeight: medium);
  static const labelEmphasis = TextStyle(fontSize: 12, fontWeight: semiBold);
  static const labelBold = TextStyle(fontSize: 12, fontWeight: bold);
  static const checkoutHelp = TextStyle(fontSize: 12, height: 1.7);
  static const compactBody = TextStyle(fontSize: 13);
  static const toast = TextStyle(fontSize: 13, fontWeight: medium);
  static const compactBodyBold = TextStyle(fontSize: 13, fontWeight: bold);
  static const bodyText = TextStyle(fontSize: 14);
  static const bodyBold = TextStyle(fontSize: 14, fontWeight: bold);
  static const bodyEmphasis = TextStyle(fontSize: 14, fontWeight: semiBold);
  static const postBody = TextStyle(
    fontSize: 14,
    height: 1.75,
    fontWeight: regular,
  );
  static const messageBody = TextStyle(fontSize: 14, height: 1.45);
  static const comfortableBody = TextStyle(fontSize: 15);
  static const authorName = TextStyle(fontSize: 15, fontWeight: semiBold);
  static const comfortableBodyBold = TextStyle(fontSize: 15, fontWeight: bold);
  static const permissionPrompt = TextStyle(fontSize: 15, height: 1.4);
  static const largeBody = TextStyle(fontSize: 16);
  static const conversationName = TextStyle(fontSize: 16, fontWeight: semiBold);
  static const sellerName = TextStyle(fontSize: 16, fontWeight: bold);
  static const specificationValue = TextStyle(fontSize: 16, height: 1.6);
  static const subtitle = TextStyle(fontSize: 17);
  static const galleryTitle = TextStyle(fontSize: 17, fontWeight: regular);
  static const pageTitle = TextStyle(fontSize: 18);
  static const dialogTitle = TextStyle(fontSize: 18, fontWeight: medium);
  static const pageTitleBold = TextStyle(fontSize: 18, fontWeight: bold);
  static const amount = TextStyle(fontSize: 20);
  static const orderPayable = TextStyle(
    fontSize: 48,
    fontWeight: heavy,
    height: 1.1,
  );
  static const analyticsTitle = TextStyle(fontSize: 20, fontWeight: regular);
  static const specificationsHeading = TextStyle(
    fontSize: 20,
    fontWeight: medium,
  );
  static const postHeading = TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.6,
  );
  static const walletBalance = TextStyle(fontSize: 21, fontWeight: semiBold);
  static const callName = TextStyle(fontSize: 21, fontWeight: bold);
  static const createPlaceholder = TextStyle(fontSize: 22);
  static const cartTitle = TextStyle(fontSize: 23, fontWeight: medium);
  static const productTitle = TextStyle(
    fontSize: 23,
    fontWeight: bold,
    height: 1.2,
  );
  static const authTitle = TextStyle(fontSize: 24, fontWeight: semiBold);
  static const productPrice = TextStyle(fontSize: 24, fontWeight: bold);
  static const otpCode = TextStyle(fontSize: 26);
  static const inboxTitle = TextStyle(fontSize: 27, fontWeight: bold);
  static const analyticsTotal = TextStyle(fontSize: 28, fontWeight: semiBold);
  static const scheduleTime = TextStyle(fontSize: 28);
  static const homeBrand = TextStyle(
    fontSize: 30,
    fontWeight: extraBold,
    height: 1.1,
  );
  static const splashBrand = TextStyle(
    fontSize: 40,
    height: 1,
    fontWeight: bold,
  );
  static const regularText = TextStyle(fontWeight: regular);
  static const boldText = TextStyle(fontWeight: bold);
  static const emoji = TextStyle(fontFamily: null);

  static const numberFontFamily = 'Roboto';
  static const emojiSize = 27.0;
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extraBold = FontWeight.w800;
  static const heavy = FontWeight.w900;

  static const materialTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: regular),
    displayMedium: TextStyle(fontSize: 45, fontWeight: regular),
    displaySmall: TextStyle(fontSize: 36, fontWeight: regular),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: regular),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: regular),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: regular),
    titleLarge: heading,
    titleMedium: TextStyle(fontSize: 16, fontWeight: medium),
    titleSmall: TextStyle(fontSize: 14, fontWeight: medium),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: regular),
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: labelMedium,
    labelSmall: TextStyle(fontSize: 11, fontWeight: medium),
  );

  static TextStyle scaledSplashBrand(double scale) =>
      splashBrand.copyWith(fontSize: splashBrand.fontSize! * scale);

  static TextStyle avatarInitial(double radius) =>
      inherit.copyWith(fontSize: radius * .7);
}
