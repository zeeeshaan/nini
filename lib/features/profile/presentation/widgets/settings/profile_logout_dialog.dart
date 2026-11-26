import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';

class ProfileLogoutDialog extends StatelessWidget {
  const ProfileLogoutDialog({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SessionCubit, SessionState>(
    builder: (context, session) => PopScope(
      canPop: !session.isLoggingOut && !session.logoutCleanupRequired,
      child: AlertDialog(
        title: const Text(ProfileSettingsStrings.logoutTitle),
        content: Text(
          session.logoutError ?? ProfileSettingsStrings.logoutConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: session.isLoggingOut || session.logoutCleanupRequired
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text(ProfileScreenStrings.cancel),
          ),
          FilledButton(
            onPressed: session.isLoggingOut
                ? null
                : () => context.read<SessionCubit>().logout(),
            child: Text(
              session.isLoggingOut
                  ? ProfileSettingsStrings.loggingOut
                  : ProfileSettingsStrings.logout,
            ),
          ),
        ],
      ),
    ),
  );
}
