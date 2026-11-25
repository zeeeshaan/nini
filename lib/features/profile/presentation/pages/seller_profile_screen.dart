import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animations/screen_entrance/screen_entrance.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/features/chat/presentation/helpers/open_seller_conversation.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/profile_settings/presentation/widgets/common/settings_empty_state.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/skeleton/profile_skeleton.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';

import '../../data/api_public_profile_repository.dart';
import '../../domain/public_user_profile.dart';
import '../cubit/seller_profile_cubit.dart';
import '../helpers/show_seller_moderation_actions.dart';
import '../widgets/seller/seller_profile_content.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({
    super.key,
    required this.username,
    this.expectedUserId,
    this.onOwnProfilePressed,
  });
  final String username;
  final String? expectedUserId;
  final VoidCallback? onOwnProfilePressed;

  bool _isOwn(BuildContext context, PublicUserProfile profile) {
    final session = context.read<SessionCubit?>()?.state;
    final id = session == null
        ? context.read<UserProfileCubit?>()?.state.profile.id
        : session.status == SessionStatus.authenticated
        ? session.userId
        : null;
    return profile.isMe == true ||
        (id != null && id.isNotEmpty && id == profile.seller.id);
  }

  Widget _screen(
    BuildContext context,
    SellerProfileState state, {
    VoidCallback? retry,
    VoidCallback? follow,
    SellerProfileCubit? cubit,
  }) {
    final profile = state.profile;
    return ScreenEntrance(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            if (profile != null &&
                !_isOwn(context, profile) &&
                context.read<SessionCubit?>()?.state.status ==
                    SessionStatus.authenticated)
              IconButton(
                tooltip: AppStrings.morePostOptions,
                onPressed: state.blocking
                    ? null
                    : () => showSellerModerationActions(context),
                icon: const AppIcon(AppIcons.more, size: 24),
              ),
            IconButton(
              tooltip: AppStrings.message,
              onPressed: profile == null
                  ? null
                  : () => openSellerConversation(context, profile.seller),
              icon: const AppIcon(AppIcons.send, size: 30),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: AppStrings.back,
              onPressed: () => Navigator.of(context).pop(),
              icon: const AppIcon(AppIcons.backRight),
            ),
          ],
          centerTitle: false,
        ),
        body: SafeArea(
          child: state.loading && profile == null
              ? const SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: ProfileSkeleton(seller: true),
                  ),
                )
              : profile == null
              ? SettingsEmptyState(
                  title: ProfilePostStrings.publicProfile,
                  message: state.error ?? ProfilePostStrings.publicUnavailable,
                  icon: AppIcons.profile,
                  onRetry: state.canRetry ? retry : null,
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if ((notification is ScrollUpdateNotification ||
                            notification is OverscrollNotification) &&
                        notification.metrics.extentAfter < 200 &&
                        !state.posts.error) {
                      cubit?.loadPosts(next: true);
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SellerProfileContent(
                      profile: profile,
                      onFollow: state.blocking ? null : follow,
                      following: state.following || state.blocking,
                      posts: state.posts,
                      selectedCategoryId: state.selectedCategoryId,
                      onCategorySelected: cubit?.selectCategory,
                      onPostTap: (post) =>
                          openHomePost(context, post, profile.seller),
                      onRetryPosts: () => cubit?.loadPosts(
                        next:
                            state.posts.page > 0 && !state.posts.failedRefresh,
                      ),
                      categories: state.categories,
                      categoryMessage: state.categoriesLoading
                          ? ProfilePostStrings.publicCategoriesLoading
                          : state.categoriesError,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PublicUserProfile.normalizeUsername(username) == null) {
      return _screen(
        context,
        const SellerProfileState(
          error: ProfilePostStrings.publicIdentityMissing,
          canRetry: false,
        ),
      );
    }
    return BlocProvider(
      key: ValueKey((username, expectedUserId)),
      create: (context) =>
          SellerProfileCubit(context.read<ApiPublicProfileRepository>())
            ..load(username, expectedUserId: expectedUserId),
      child: Builder(
        builder: (context) {
          final cubit = context.read<SellerProfileCubit>();
          Widget view = BlocConsumer<SellerProfileCubit, SellerProfileState>(
            listenWhen: (previous, current) =>
                previous.profile != current.profile ||
                previous.followError != current.followError,
            listener: (context, state) {
              if (state.followError != null) {
                AppToast.error(context, state.followError!);
              }
              final profile = state.profile;
              if (profile != null && _isOwn(context, profile)) {
                onOwnProfilePressed?.call();
              }
            },
            builder: (context, state) => _screen(
              context,
              state,
              retry: () => cubit.load(username, expectedUserId: expectedUserId),
              follow: () {
                final session = context.read<SessionCubit?>();
                final initial = session?.state;
                bool current() =>
                    session != null &&
                    !session.isClosed &&
                    session.state.status == SessionStatus.authenticated &&
                    !session.state.isLoggingOut &&
                    !session.state.logoutCleanupRequired &&
                    session.state.userId == initial?.userId &&
                    session.state.accountRevision == initial?.accountRevision;
                if (cubit.state.profile?.isFollowing == true) {
                  cubit.unfollow(
                    accountId: initial?.userId,
                    isCurrentAccount: current,
                  );
                } else {
                  cubit.follow(
                    accountId: initial?.userId,
                    isCurrentAccount: current,
                  );
                }
              },
              cubit: cubit,
            ),
          );
          final session = context.read<SessionCubit?>();
          if (session != null) {
            view = BlocListener<SessionCubit, SessionState>(
              bloc: session,
              listenWhen: (previous, current) =>
                  previous.userId != current.userId ||
                  previous.accountRevision != current.accountRevision,
              listener: (_, _) => cubit.invalidate(),
              child: view,
            );
          }
          return view;
        },
      ),
    );
  }
}
