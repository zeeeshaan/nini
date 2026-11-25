import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/profile/data/api_public_profile_repository.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

import '../cubit/blocked_users_cubit.dart';
import '../widgets/blocked/blocked_contacts_list.dart';
import '../widgets/common/settings_page.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit?>();
    final initial = session?.state;
    bool current() =>
        session != null &&
        !session.isClosed &&
        session.state.status == SessionStatus.authenticated &&
        !session.state.isLoggingOut &&
        !session.state.logoutCleanupRequired &&
        session.state.userId != null &&
        session.state.userId == initial?.userId &&
        session.state.accountRevision == initial?.accountRevision;

    return BlocProvider(
      create: (context) => BlockedUsersCubit(
        context.read<ApiPublicProfileRepository>(),
        isCurrentAccount: current,
      ),
      child: BlocListener<BlockedUsersCubit, BlockedUsersState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) {
          if (state.error != null) AppToast.error(context, state.error!);
        },
        child: const SettingsPage(
          title: ProfileSettingsStrings.blocked,
          child: BlockedContactsList(),
        ),
      ),
    );
  }
}
