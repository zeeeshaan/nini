import 'package:flutter/material.dart';
import 'package:hywork/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:hywork/features/team/data/in_memory_teams_repository.dart';
import 'package:hywork/features/team/domain/team_workspace.dart';
import 'package:hywork/features/team/presentation/widgets/my_teams/team_edit_sheet.dart';
import 'package:hywork/features/team/presentation/widgets/my_teams/team_options_sheet.dart';

Future<void> manageTeam(
  BuildContext context,
  TeamWorkspace team,
  InMemoryTeamsRepository repository, {
  required VoidCallback onChat,
}) async {
  final option = await showPostDialog<TeamOption>(
    context,
    const TeamOptionsSheet(),
  );
  if (!context.mounted || repository.find(team.id) == null) return;
  switch (option) {
    case TeamOption.chat:
      onChat();
    case TeamOption.edit:
      final updated = await showPostDialog<TeamWorkspace>(
        context,
        TeamEditSheet(team: repository.find(team.id)!),
      );
      if (updated != null) repository.update(updated);
    case TeamOption.delete:
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Delete team?',
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
          content: const Text(
            'Remove this team from your current session?',
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
      if (confirmed == true) repository.delete(team.id);
    case null:
      break;
  }
}
