import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_app/screens/accessibility_screen.dart';
import 'package:simple_app/screens/archive_screen.dart';
import 'package:simple_app/screens/blocked_screen.dart';
import 'package:simple_app/screens/cart_screen.dart';
import 'package:simple_app/screens/device_permissions_screen.dart';
import 'package:simple_app/screens/insights_screen.dart';
import 'package:simple_app/screens/language_screen.dart';
import 'package:simple_app/screens/location_permission_screen.dart';
import 'package:simple_app/screens/locations_screen.dart';
import 'package:simple_app/screens/mode_screen.dart';
import 'package:simple_app/screens/my_media_screen.dart';
import 'package:simple_app/screens/notifications_screen.dart';
import 'package:simple_app/screens/phone_screen.dart';
import 'package:simple_app/screens/post_screen.dart';
import 'package:simple_app/screens/profile_setting_screen.dart';
import 'package:simple_app/screens/root_screen.dart';
import 'package:simple_app/screens/saved_screen.dart';
import 'package:simple_app/screens/scheduled_content_screen.dart';
import 'package:simple_app/screens/settings_screen.dart';
import 'package:simple_app/screens/tags_keywords_screen.dart';
import 'package:simple_app/screens/top_up_screen.dart';
import 'package:simple_app/screens/trending_screen.dart';
import 'package:simple_app/screens/user_screen.dart';
import 'package:simple_app/screens/verification_screen.dart';
import 'package:simple_app/screens/wallet_screen.dart';
import 'package:simple_app/screens/withdraw_screen.dart';
import 'package:simple_app/screens/withdraw_success_screen.dart';
import 'package:simple_app/screens/search_screen.dart';
import 'package:simple_app/theme.dart';
import 'package:simple_app/widgets/country_picker_sheet.dart';

void main() {
  // Measure with the real Persian font rather than the test font, so any
  // overflow reported here also happens on a device.
  setUpAll(() async {
    final font = File('assets/fonts/YekanBakh-Regular.ttf').readAsBytes();
    await (FontLoader(
      'YekanBakh',
    )..addFont(font.then((b) => ByteData.sublistView(b)))).load();
  });

  final screens = <String, Widget>{
    'root': const RootScreen(),
    'search': const Scaffold(body: SearchScreen()),
    'user': const Scaffold(body: UserScreen()),
    'cart': const CartScreen(),
    'phone': const PhoneScreen(),
    'location permission': const LocationPermissionScreen(),
    'verification': const VerificationScreen(),
    'settings': const SettingsScreen(),
    'profile': const ProfileSettingScreen(),
    'post': const PostScreen(),
    'locations': const LocationsScreen(),
    'wallet': const WalletScreen(),
    'withdraw': const WithdrawScreen(),
    'top up': const TopUpScreen(),
    'withdraw success': const WithdrawSuccessScreen(),
    'saved': const SavedScreen(),
    'notifications': const NotificationsScreen(),
    'trending': const TrendingScreen(),
    'insights': const InsightsScreen(),
    'scheduled': const ScheduledContentScreen(),
    'blocked': const BlockedScreen(),
    'language': const LanguageScreen(),
    'device permissions': const DevicePermissionsScreen(),
    'accessibility': const AccessibilityScreen(),
    'mode': const ModeScreen(),
    'my media': const MyMediaScreen(),
    'tags': const TagsKeywordsScreen(),
    'archive': const ArchiveScreen(),
    'country picker': const CountryPickerSheet(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders RTL without overflow on a phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('fa', 'IR'),
          supportedLocales: const [Locale('fa', 'IR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: entry.value,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        Directionality.of(tester.element(find.byWidget(entry.value))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
