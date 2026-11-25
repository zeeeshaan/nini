import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:nini/shared/widgets/app_loader/app_loader.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

import '../../cubit/blocked_users_cubit.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_notice.dart';

class BlockedContactsList extends StatelessWidget {
  const BlockedContactsList({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: AppLoader());
          }
          if (state.items.isEmpty) {
            return SettingsEmptyState(
              textAlign: TextAlign.center,
              title: ProfileSettingsStrings.noBlocked,
              message: state.error ?? ProfileSettingsStrings.blockedHelp,
              icon: AppIcons.profile,
              onRetry: state.error != null
                  ? () => context.read<BlockedUsersCubit>().load()
                  : null,
            );
          }
          return Column(
            children: [
              const SettingsNotice(text: ProfileSettingsStrings.sessionBlocks),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < 200 &&
                        !state.loading) {
                      context.read<BlockedUsersCubit>().load(next: true);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: state.items.length + (state.loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: AppLoader()),
                        );
                      }
                      final contact = state.items[index];
                      final busy = state.unblockingId == contact.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      await context
                                          .read<BlockedUsersCubit>()
                                          .unblock(contact.id);
                                      if (!context.mounted) return;
                                      final error = context
                                          .read<BlockedUsersCubit>()
                                          .state
                                          .error;
                                      if (error == null) {
                                        AppToast.success(
                                          context,
                                          ProfileSettingsStrings.unblockSuccess,
                                        );
                                      }
                                    },
                              child: Text(
                                busy
                                    ? ProfileSettingsStrings.unblock
                                    : ProfileSettingsStrings.unblock,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                contact.name ??
                                    ProfileSettingsStrings.blockedConversation,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.body,
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SellerAvatar(
                              asset: contact.avatar ?? '',
                              name:
                                  contact.name ??
                                  ProfileSettingsStrings.blockedConversation,
                              size: 40,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      );
}
