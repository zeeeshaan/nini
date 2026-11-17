import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/features/chat/presentation/helpers/open_seller_conversation.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/profile_settings/presentation/widgets/common/settings_empty_state.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/skeleton/profile_skeleton.dart';

import '../../data/api_public_profile_repository.dart';
import '../../domain/public_user_profile.dart';
import '../cubit/seller_profile_cubit.dart';
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
  }) {
    final profile = state.profile;
    return ScreenEntrance(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
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
          child: state.loading
              ? const SingleChildScrollView(child: ProfileSkeleton())
              : profile == null
              ? SettingsEmptyState(
                  title: ProfilePostStrings.publicProfile,
                  message: state.error ?? ProfilePostStrings.publicUnavailable,
                  icon: AppIcons.profile,
                  onRetry: state.canRetry ? retry : null,
                )
              : SingleChildScrollView(
                  child: SellerProfileContent(profile: profile),
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
            listener: (context, state) {
              final profile = state.profile;
              if (profile != null && _isOwn(context, profile)) {
                onOwnProfilePressed?.call();
              }
            },
            builder: (context, state) => _screen(
              context,
              state,
              retry: () => cubit.load(username, expectedUserId: expectedUserId),
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
