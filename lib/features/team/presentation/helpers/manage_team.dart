import 'package:flutter/material.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/team/data/in_memory_teams_repository.dart';
import 'package:nini/features/team/domain/team_workspace.dart';
import 'package:nini/features/team/presentation/widgets/my_teams/team_edit_sheet.dart';
import 'package:nini/features/team/presentation/widgets/my_teams/team_options_sheet.dart';

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
            "حذف تیم؟",
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          content: const Text(
            "این تیم از نشست فعلی حذف شود؟",
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "انصراف",
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "حذف",
                textDirection: TextDirection.rtl,
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
