import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/theme/theme_cubit.dart';
import 'package:nini/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nini/features/cart/data/local_cart_repository.dart';
import 'package:nini/features/cart/domain/repositories/cart_repository.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/post_analytics/data/post_analytics_repository.dart';
import 'package:nini/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:nini/features/posts/data/local_posts_repository.dart';
import 'package:nini/features/posts/data/local_profile_categories_repository.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';

/// Creates and owns the Cubits shared across the app.
class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.child,
    this.initialThemeMode = ThemeMode.system,
    this.postsRepository,
    this.analyticsRepository,
    this.cartRepository,
    this.categoriesRepository,
  });

  final Widget child;
  final ThemeMode initialThemeMode;
  final PostsRepository? postsRepository;
  final PostAnalyticsRepository? analyticsRepository;
  final CartRepository? cartRepository;
  final ProfileCategoriesRepository? categoriesRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ProfileCategoriesCubit(
            categoriesRepository ?? LocalProfileCategoriesRepository(),
          )..load(),
        ),
        BlocProvider(
          create: (_) =>
              CartCubit(cartRepository ?? LocalCartRepository())..load(),
        ),
        BlocProvider(
          create: (context) => NotificationsCubit(context.read<CartCubit>()),
        ),
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
      child: child,
    );
  }
}
