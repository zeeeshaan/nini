import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/theme/theme_cubit/theme_cubit.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/create_post/data/api_categories_repository.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/core/security/account_storage/account_storage.dart';
import 'package:hywork/features/login/data/auth_repo.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/otp_verification/data/otp_verification_repo.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/data/in_memory_chat_repository.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/team/data/in_memory_teams_repository.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/data/push_device_sync.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:hywork/features/cart/data/local_cart_repository.dart';
import 'package:hywork/features/cart/domain/repositories/cart_repository.dart';
import 'package:hywork/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hywork/features/post_analytics/data/post_analytics_repository.dart';
import 'package:hywork/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:hywork/features/posts/data/local_posts_repository.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:hywork/features/posts/data/api_profile_categories_repository.dart';
import 'package:hywork/features/posts/domain/posts_repository.dart';
import 'package:hywork/features/posts/domain/profile_categories_repository.dart';
import 'package:hywork/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:hywork/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:hywork/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:hywork/features/saved_posts/data/local_saved_posts_repository.dart';
import 'package:hywork/features/saved_posts/domain/saved_posts_repository.dart';
import 'package:hywork/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:hywork/features/profile_settings/data/api_user_profile_repository.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';
import 'package:hywork/features/reports/data/api_reports_repository.dart';
import 'package:hywork/features/profile_settings/domain/user_profile_repository.dart';
import 'package:hywork/features/profile_settings/presentation/cubit/user_profile_cubit.dart';

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
    this.apiClient,
    this.tokenStore,
  });

  final Widget child;
  final ThemeMode initialThemeMode;
  final PostsRepository? postsRepository;
  final PostAnalyticsRepository? analyticsRepository;
  final CartRepository? cartRepository;
  final ProfileCategoriesRepository? categoriesRepository;
  final SavedPostsRepository? savedPostsRepository;
  final UserProfileRepository? userProfileRepository;
  final ApiClient? apiClient;
  final SecureTokenStore? tokenStore;

  AccountStorage _storage(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    if (session.status != SessionStatus.authenticated ||
        session.userId == null) {
      throw StateError('A validated session is required for account data.');
    }
    return AccountStorage(session.userId!);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>(create: (_) => apiClient ?? ApiClient()),
        RepositoryProvider<ApiCategoriesRepository>(
          create: (context) =>
              ApiCategoriesRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<SecureTokenStore>(
          create: (_) => tokenStore ?? SecureTokenStore(),
        ),
        RepositoryProvider<ApiPublicProfileRepository>(
          create: (context) => ApiPublicProfileRepository(
            context.read<ApiClient>(),
            context.read<SecureTokenStore>(),
          ),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(
            context.read<ApiClient>(),
            tokenStore: context.read<SecureTokenStore>(),
          ),
        ),
        RepositoryProvider<OtpVerificationRepository>(
          create: (context) => OtpVerificationRepository(
            context.read<ApiClient>(),
            context.read<SecureTokenStore>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SessionCubit(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (_) => ThemeCubit(initialMode: initialThemeMode),
          ),
        ],
        child: BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) => current.userId != previous.userId,
          listener: (context, session) {
            final account = session.status == SessionStatus.authenticated
                ? session.userId
                : null;
            InMemoryChatRepository.instance.useAccount(account);
            InMemoryTeamsRepository.instance.useAccount(account);
          },
          child: BlocBuilder<SessionCubit, SessionState>(
            // Dispose account state and the navigation stack only on logout.
            buildWhen: (previous, current) =>
                previous.accountRevision != current.accountRevision,
            builder: (context, session) =>
                RepositoryProvider<ApiPostsRepository>(
                  key: ValueKey('api-posts-${session.accountRevision}'),
                  dispose: (repository) => repository.dispose(),
                  create: (context) {
                    final account = context.read<SessionCubit>();
                    final initial = account.state;
                    bool current() =>
                        !account.isClosed &&
                        account.state.status == SessionStatus.authenticated &&
                        !account.state.isLoggingOut &&
                        !account.state.logoutCleanupRequired &&
                        account.state.userId != null &&
                        account.state.userId == initial.userId &&
                        account.state.accountRevision ==
                            initial.accountRevision;
                    return ApiPostsRepository(
                      context.read<ApiClient>(),
                      context.read<SecureTokenStore>(),
                      isCurrentAccount: current,
                      onUnauthorized: () async {
                        if (current()) await account.logout();
                      },
                    );
                  },
                  child: RepositoryProvider<ApiReportsRepository>(
                    key: ValueKey('api-reports-${session.accountRevision}'),
                    create: (context) {
                      final account = context.read<SessionCubit>();
                      final initial = account.state;
                      return ApiReportsRepository(
                        context.read<ApiClient>(),
                        context.read<SecureTokenStore>(),
                        isCurrentAccount: () =>
                            !account.isClosed &&
                            account.state.status ==
                                SessionStatus.authenticated &&
                            !account.state.isLoggingOut &&
                            !account.state.logoutCleanupRequired &&
                            account.state.userId != null &&
                            account.state.userId == initial.userId &&
                            account.state.accountRevision ==
                                initial.accountRevision,
                      );
                    },
                    child: RepositoryProvider<ApiNotificationsRepository>(
                      key: ValueKey(
                        'api-notifications-${session.accountRevision}',
                      ),
                      create: (context) {
                        final account = context.read<SessionCubit>();
                        final initial = account.state;
                        bool current() =>
                            !account.isClosed &&
                            account.state.status ==
                                SessionStatus.authenticated &&
                            !account.state.isLoggingOut &&
                            !account.state.logoutCleanupRequired &&
                            account.state.userId != null &&
                            account.state.userId == initial.userId &&
                            account.state.accountRevision ==
                                initial.accountRevision;
                        final repository = ApiNotificationsRepository(
                          context.read<ApiClient>(),
                          context.read<SecureTokenStore>(),
                          isCurrentAccount: current,
                          onUnauthorized: () async {
                            if (current()) await account.logout();
                          },
                        );
                        final userId = initial.userId;
                        if (initial.status == SessionStatus.authenticated &&
                            userId != null) {
                          PushDeviceSync.instance.attach(
                            repository: repository,
                            isCurrentAccount: current,
                            userId: userId,
                            accountRevision: initial.accountRevision,
                          );
                        }
                        return repository;
                      },
                      child: RepositoryProvider<ApiChatsRepository>(
                        key: ValueKey('api-chats-${session.accountRevision}'),
                        create: (context) {
                          final account = context.read<SessionCubit>();
                          final initial = account.state;
                          bool current() =>
                              !account.isClosed &&
                              account.state.status ==
                                  SessionStatus.authenticated &&
                              !account.state.isLoggingOut &&
                              !account.state.logoutCleanupRequired &&
                              account.state.userId != null &&
                              account.state.userId == initial.userId &&
                              account.state.accountRevision ==
                                  initial.accountRevision;
                          return ApiChatsRepository(
                            context.read<ApiClient>(),
                            context.read<SecureTokenStore>(),
                            isCurrentAccount: current,
                            onUnauthorized: () async {
                              if (current()) await account.logout();
                            },
                          );
                        },
                        child: RepositoryProvider<RealtimeSocketClient>(
                          key: ValueKey(
                            'realtime-socket-${session.accountRevision}',
                          ),
                          dispose: (client) {
                            unawaited(client.dispose());
                          },
                          create: (context) {
                            final account = context.read<SessionCubit>();
                            final initial = account.state;
                            bool current() =>
                                !account.isClosed &&
                                account.state.status ==
                                    SessionStatus.authenticated &&
                                !account.state.isLoggingOut &&
                                !account.state.logoutCleanupRequired &&
                                account.state.userId != null &&
                                account.state.userId == initial.userId &&
                                account.state.accountRevision ==
                                    initial.accountRevision;
                            return RealtimeSocketClient(
                              tokenStore: context.read<SecureTokenStore>(),
                              isCurrentAccount: current,
                              accountRevision: initial.accountRevision,
                              userId: initial.userId,
                            );
                          },
                          child: MultiBlocProvider(
                            key: ValueKey(session.accountRevision),
                            providers: [
                              // Account data stays lazy until session validation opens Dashboard.
                              BlocProvider(
                                create: (context) => FeedCubit(
                                  context.read<ApiPostsRepository>(),
                                ),
                              ),
                              BlocProvider(
                                create: (context) => OwnPostsCubit(
                                  context.read<ApiPostsRepository>(),
                                ),
                              ),
                              BlocProvider(
                                create: (context) {
                                  final session = context.read<SessionCubit>();
                                  final userId = session.state.userId ?? '';
                                  return UserProfileCubit(
                                    userProfileRepository ??
                                        ApiUserProfileRepository(
                                          context.read<ApiClient>(),
                                          context.read<SecureTokenStore>(),
                                          userId: userId,
                                          onUnauthorized: () async {
                                            if (session.state.userId ==
                                                userId) {
                                              await session.logout();
                                            }
                                          },
                                        ),
                                    userId: userId,
                                  )..load();
                                },
                              ),
                              BlocProvider(
                                create: (context) => PostLikesCubit(
                                  context.read<ApiPostsRepository>(),
                                ),
                              ),
                              BlocProvider(
                                create: (context) {
                                  final session = context.read<SessionCubit>();
                                  final account = session.state;
                                  bool isCurrentAccount() =>
                                      !session.isClosed &&
                                      session.state.status ==
                                          SessionStatus.authenticated &&
                                      !session.state.isLoggingOut &&
                                      !session.state.logoutCleanupRequired &&
                                      session.state.userId != null &&
                                      session.state.userId == account.userId &&
                                      session.state.accountRevision ==
                                          account.accountRevision;
                                  return ProfileCategoriesCubit(
                                    categoriesRepository ??
                                        ApiProfileCategoriesRepository(
                                          context.read<ApiClient>(),
                                          context.read<SecureTokenStore>(),
                                          isCurrentAccount: isCurrentAccount,
                                          onUnauthorized: () async {
                                            if (isCurrentAccount()) {
                                              await session.logout();
                                            }
                                          },
                                        ),
                                  )..load();
                                },
                              ),
                              BlocProvider(
                                create: (context) => CartCubit(
                                  cartRepository ??
                                      LocalCartRepository(
                                        directoryProvider: _storage(context)
                                            .directory,
                                      ),
                                )..load(),
                              ),
                              BlocProvider(
                                create: (context) {
                                  final account = context.read<SessionCubit>();
                                  final initial = account.state;
                                  bool current() =>
                                      !account.isClosed &&
                                      account.state.status ==
                                          SessionStatus.authenticated &&
                                      !account.state.isLoggingOut &&
                                      !account.state.logoutCleanupRequired &&
                                      account.state.userId != null &&
                                      account.state.userId == initial.userId &&
                                      account.state.accountRevision ==
                                          initial.accountRevision;
                                  return NotificationsCubit(
                                    context.read<ApiNotificationsRepository>(),
                                    isCurrentAccount: current,
                                    realtime: context
                                        .read<RealtimeSocketClient>(),
                                  );
                                },
                              ),
                              BlocProvider(
                                create: (context) {
                                  final account = context.read<SessionCubit>();
                                  final initial = account.state;
                                  bool current() =>
                                      !account.isClosed &&
                                      account.state.status ==
                                          SessionStatus.authenticated &&
                                      !account.state.isLoggingOut &&
                                      !account.state.logoutCleanupRequired &&
                                      account.state.userId != null &&
                                      account.state.userId == initial.userId &&
                                      account.state.accountRevision ==
                                          initial.accountRevision;
                                  return ChatUnreadCubit(
                                    context.read<ApiChatsRepository>(),
                                    isCurrentAccount: current,
                                    realtime: context
                                        .read<RealtimeSocketClient>(),
                                  );
                                },
                              ),
                              BlocProvider(
                                create: (context) => PostAnalyticsCubit(
                                  analyticsRepository ??
                                      LocalPostAnalyticsRepository(
                                        directoryProvider: _storage(context)
                                            .directory,
                                      ),
                                ),
                              ),
                              BlocProvider(
                                create: (context) => PostsCubit(
                                  postsRepository ??
                                      LocalPostsRepository(
                                        directoryProvider: _storage(context)
                                            .directory,
                                      ),
                                )..load(),
                              ),
                              BlocProvider(
                                create: (context) => SavedPostsCubit(
                                  savedPostsRepository ??
                                      LocalSavedPostsRepository(
                                        directoryProvider: _storage(context)
                                            .directory,
                                      ),
                                  posts: context.read<PostsCubit>(),
                                  backendPosts: context
                                      .read<ApiPostsRepository>(),
                                )..load(),
                              ),
                            ],
                            child: BlocListener<SessionCubit, SessionState>(
                              listenWhen: (previous, current) =>
                                  current.status ==
                                      SessionStatus.authenticated &&
                                  (previous.status !=
                                          SessionStatus.authenticated ||
                                      previous.userId != current.userId),
                              listener: (context, session) {
                                context.read<ProfileCategoriesCubit>().load();
                                unawaited(
                                  context.read<NotificationsCubit>().load(),
                                );
                                unawaited(
                                  context
                                      .read<NotificationsCubit>()
                                      .refreshUnreadCount(),
                                );
                                unawaited(
                                  context.read<ChatUnreadCubit>().refresh(),
                                );
                                final account = context.read<SessionCubit>();
                                final userId = session.userId;
                                if (userId == null) return;
                                bool current() =>
                                    !account.isClosed &&
                                    account.state.status ==
                                        SessionStatus.authenticated &&
                                    !account.state.isLoggingOut &&
                                    !account.state.logoutCleanupRequired &&
                                    account.state.userId != null &&
                                    account.state.userId == userId &&
                                    account.state.accountRevision ==
                                        session.accountRevision;
                                PushDeviceSync.instance.attach(
                                  repository: context
                                      .read<ApiNotificationsRepository>(),
                                  isCurrentAccount: current,
                                  userId: userId,
                                  accountRevision: session.accountRevision,
                                );
                              },
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
