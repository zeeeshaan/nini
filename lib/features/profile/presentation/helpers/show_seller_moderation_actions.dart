import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/report_strings.dart';
import 'package:nini/features/chat/presentation/widgets/conversation/chat_action_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/posts/presentation/widgets/actions/post_owner_action_tile.dart';
import 'package:nini/features/profile/presentation/cubit/seller_profile_cubit.dart';
import 'package:nini/features/reports/data/api_reports_repository.dart';
import 'package:nini/features/reports/presentation/helpers/open_report_sheet.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

enum _SellerModerationAction { report, block, unblock }

Future<void> showSellerModerationActions(BuildContext context) async {
  final cubit = context.read<SellerProfileCubit>();
  final profile = cubit.state.profile;
  if (profile == null || profile.isMe == true) return;

  final session = context.read<SessionCubit?>();
  final initial = session?.state;
  if (session == null ||
      initial == null ||
      initial.status != SessionStatus.authenticated ||
      initial.userId == null) {
    AppToast.warning(context, ReportStrings.signInRequired);
    return;
  }
  if (profile.seller.id == initial.userId) return;

  final blocked = profile.isBlocked == true;
  final action = await showAppBottomSheet<_SellerModerationAction>(
    context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PostOwnerActionTile(
              label: ReportStrings.reportUser,
              icon: Icons.flag_outlined,
              onTap: () =>
                  Navigator.of(sheetContext)
                      .pop(_SellerModerationAction.report),
            ),
            PostOwnerActionTile(
              label: blocked
                  ? AppStrings.unblockPerson
                  : AppStrings.blockPerson,
              icon: blocked ? Icons.lock_open_outlined : Icons.block_outlined,
              destructive: !blocked,
              onTap: () => Navigator.of(sheetContext).pop(
                blocked
                    ? _SellerModerationAction.unblock
                    : _SellerModerationAction.block,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  bool current() =>
      !session.isClosed &&
      session.state.status == SessionStatus.authenticated &&
      !session.state.isLoggingOut &&
      !session.state.logoutCleanupRequired &&
      session.state.userId == initial.userId &&
      session.state.accountRevision == initial.accountRevision;

  switch (action) {
    case _SellerModerationAction.report:
      await openReportSheet(
        context,
        title: ReportStrings.reportUser,
        targetType: ReportTargetType.user,
        targetId: profile.seller.id,
      );
      return;
    case _SellerModerationAction.block:
      final confirmed = await confirmChatAction(
        context,
        title: AppStrings.blockQuestion,
        description: AppStrings.blockHelp,
        confirmLabel: AppStrings.blockPerson,
      );
      if (!context.mounted || !confirmed || !current()) return;
      await cubit.block(
        currentUserId: initial.userId!,
        isCurrentAccount: current,
      );
      if (!context.mounted) return;
      final error = cubit.state.blockError;
      if (error != null) {
        AppToast.error(context, error);
      } else if (cubit.state.profile?.isBlocked == true) {
        AppToast.success(context, AppStrings.personBlocked);
      }
      return;
    case _SellerModerationAction.unblock:
      await cubit.unblock(
        currentUserId: initial.userId!,
        isCurrentAccount: current,
      );
      if (!context.mounted) return;
      final error = cubit.state.blockError;
      if (error != null) {
        AppToast.error(context, error);
      } else if (cubit.state.profile?.isBlocked == false) {
        AppToast.success(context, AppStrings.unblockPerson);
      }
  }
}
