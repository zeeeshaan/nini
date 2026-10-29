import 'features/post_analytics/data/post_analytics_repository.dart';
import 'features/post_analytics/presentation/domain/cubit/post_analytics_cubit.dart';
import 'features/posts/data/local_posts_repository.dart';
import 'features/posts/domain/posts_repository.dart';
import 'features/posts/presentation/cubit/posts_cubit.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'core/animation/screen_entrance.dart';
import 'core/localization/app_strings.dart';
import 'core/responsiveness/responsive_config/config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/dashboard/presentation/page/dashboard_shellscreen/dahboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ResponsiveConfig(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialThemeMode = ThemeMode.system,
    this.postsRepository,
    this.analyticsRepository,
  });

  final ThemeMode initialThemeMode;
  final PostsRepository? postsRepository;
  final PostAnalyticsRepository? analyticsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PostAnalyticsCubit(
            analyticsRepository ?? LocalPostAnalyticsRepository(),
          ),
        ),
        BlocProvider(create: (_) => ThemeCubit(initialMode: initialThemeMode)),
        BlocProvider(
          create: (_) =>
              PostsCubit(postsRepository ?? LocalPostsRepository())..load(),
        ),
      ],
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
        home: const DashboardShellScreen(
          profileImage: AssetImage('assets/Mask group.png'),
        ),
      ),
    );
  }
}
