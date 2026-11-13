import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';

import '../cubit/blocked_contacts_cubit.dart';
import '../widgets/blocked/blocked_contacts_list.dart';
import '../widgets/common/settings_page.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key, this.repository});
  final InMemoryChatRepository? repository;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        BlockedContactsCubit(repository ?? InMemoryChatRepository.instance),
    child: const SettingsPage(
      title: ProfileSettingsStrings.blocked,
      child: BlockedContactsList(),
    ),
  );
}
