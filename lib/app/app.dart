import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nini/core/animations/screen_entrance/screen_entrance.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/core/theme/app_theme/app_theme.dart';
import 'package:nini/core/theme/theme_cubit/theme_cubit.dart';
import 'package:nini/features/cart/domain/repositories/cart_repository.dart';
import 'package:nini/core/network/api_client/api_client.dart';
import 'package:nini/core/security/secure_token/secure_token.dart';
import 'package:nini/features/splash/presentation/pages/splash_screen.dart';
import 'package:nini/features/post_analytics/data/post_analytics_repository.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/saved_posts/domain/saved_posts_repository.dart';
import 'package:nini/features/profile_settings/domain/user_profile_repository.dart';

import 'app_providers.dart';

import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/login/presentation/pages/login_screen.dart';

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
    this.apiClient,
    this.tokenStore,
  });

  final ThemeMode initialThemeMode;
  final PostsRepository? postsRepository;
  final PostAnalyticsRepository? analyticsRepository;
  final CartRepository? cartRepository;
  final ProfileCategoriesRepository? categoriesRepository;
  final SavedPostsRepository? savedPostsRepository;
  final UserProfileRepository? userProfileRepository;
  final ApiClient? apiClient;
  final SecureTokenStore? tokenStore;

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
      apiClient: apiClient,
      tokenStore: tokenStore,
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
        // English testing locale with the existing control positions.
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
        home:
            context.read<SessionCubit>().state.status ==
                SessionStatus.unauthenticated
            ? const LoginScreen()
            : const SplashScreen(),
      ),
    );
  }
}
