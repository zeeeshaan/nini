import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/core/theme/theme_cubit.dart';
import 'package:nini/features/cart/domain/repositories/cart_repository.dart';
import 'package:nini/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/post_analytics/data/post_analytics_repository.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/saved_posts/domain/saved_posts_repository.dart';
import 'package:nini/features/profile_settings/domain/user_profile_repository.dart';
import 'package:nini/features/otp_verification/presentation/pages/otp_verification_screen.dart';

import 'app_providers.dart';

/// Configures the app and connects it to its shared state.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialThemeMode = ThemeMode.system,
    this.postsRepository,
    this.analyticsRepository,
    this.cartRepository,
    this.categoriesRepository,
    this.savedPostsRepository,
    this.userProfileRepository,
  });

  final ThemeMode initialThemeMode;
  final PostsRepository? postsRepository;
  final PostAnalyticsRepository? analyticsRepository;
  final CartRepository? cartRepository;
  final ProfileCategoriesRepository? categoriesRepository;
  final SavedPostsRepository? savedPostsRepository;
  final UserProfileRepository? userProfileRepository;

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      initialThemeMode: initialThemeMode,
      postsRepository: postsRepository,
      analyticsRepository: analyticsRepository,
      cartRepository: cartRepository,
      categoriesRepository: categoriesRepository,
      savedPostsRepository: savedPostsRepository,
      userProfileRepository: userProfileRepository,
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('fa', 'IR')],
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          FlutterQuillLocalizations.delegate,
        ],
        navigatorObservers: [entranceRouteObserver],
        // Keep the established layout order and right-aligned development copy.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).appBarTheme.systemOverlayStyle!,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.right,
              child: ResponsiveConfig.materialAppBuilder(context, child),
            ),
          ),
        ),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const DashboardScreen(initialTab: DashboardTab.home),
      ),
    );
  }
}
