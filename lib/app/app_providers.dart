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
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/saved_posts/data/local_saved_posts_repository.dart';
import 'package:nini/features/saved_posts/domain/saved_posts_repository.dart';
import 'package:nini/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:nini/features/profile_settings/data/local_user_profile_repository.dart';
import 'package:nini/features/profile_settings/domain/user_profile_repository.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';

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
    this.savedPostsRepository,
    this.userProfileRepository,
  });

  final Widget child;
  final ThemeMode initialThemeMode;
  final PostsRepository? postsRepository;
  final PostAnalyticsRepository? analyticsRepository;
  final CartRepository? cartRepository;
  final ProfileCategoriesRepository? categoriesRepository;
  final SavedPostsRepository? savedPostsRepository;
  final UserProfileRepository? userProfileRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (_) => UserProfileCubit(
            userProfileRepository ?? LocalUserProfileRepository(),
          )..load(),
        ),
        BlocProvider(create: (_) => PostLikesCubit()),
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
        BlocProvider(
          create: (context) => SavedPostsCubit(
            savedPostsRepository ?? LocalSavedPostsRepository(),
            posts: context.read<PostsCubit>(),
          )..load(),
        ),
      ],
      child: child,
    );
  }
}
