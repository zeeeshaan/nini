import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/core/theme/theme_cubit.dart';
import 'package:nini/features/cart/domain/repositories/cart_repository.dart';
import 'package:nini/features/post_analytics/data/post_analytics_repository.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/splash/presentation/page/splash_screen/splash_screen.dart';

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
  });

  final ThemeMode initialThemeMode;
  final PostsRepository? postsRepository;
  final PostAnalyticsRepository? analyticsRepository;
  final CartRepository? cartRepository;
  final ProfileCategoriesRepository? categoriesRepository;

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      initialThemeMode: initialThemeMode,
      postsRepository: postsRepository,
      analyticsRepository: analyticsRepository,
      cartRepository: cartRepository,
      categoriesRepository: categoriesRepository,
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
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          FlutterQuillLocalizations.delegate,
          CountryLocalizations.delegate,
        ],
        navigatorObservers: [entranceRouteObserver],
        // Keep the original design order while Persian text reads right to left.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).appBarTheme.systemOverlayStyle!,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ResponsiveConfig.materialAppBuilder(context, child),
          ),
        ),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
