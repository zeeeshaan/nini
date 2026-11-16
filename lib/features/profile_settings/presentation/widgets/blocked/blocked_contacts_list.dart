import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';

import '../../../domain/blocked_contact.dart';
import '../../cubit/blocked_contacts_cubit.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_notice.dart';

class BlockedContactsList extends StatelessWidget {
  const BlockedContactsList({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BlockedContactsCubit, List<BlockedContact>>(
        builder: (context, contacts) {
          if (contacts.isEmpty) {
            return const SettingsEmptyState(
              title: ProfileSettingsStrings.noBlocked,
              message: ProfileSettingsStrings.blockedHelp,
              icon: AppIcons.profile,
            );
          }
          return Column(
            children: [
              const SettingsNotice(text: ProfileSettingsStrings.sessionBlocks),
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => context
                                .read<BlockedContactsCubit>()
                                .unblock(contact.id),
                            child: const Text(
                              ProfileSettingsStrings.unblock,
                              textDirection: TextDirection.rtl,
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
                              textDirection: TextDirection.rtl,
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
            ],
          );
        },
      );
}
