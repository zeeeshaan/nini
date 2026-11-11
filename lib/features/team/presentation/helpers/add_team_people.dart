import 'package:flutter/material.dart';
import 'package:nini/features/team/data/in_memory_teams_repository.dart';
import 'package:nini/features/team/domain/team_workspace.dart';
import 'package:nini/features/team/presentation/cubit/team_form_cubit.dart';
import 'package:nini/features/team/presentation/helpers/select_team_members.dart';

Future<void> addTeamPeople(
  BuildContext context,
  TeamWorkspace team,
  InMemoryTeamsRepository repository,
) async {
  final form = TeamFormCubit();
  try {
    for (final selection in team.providers) {
      form.toggleProvider(selection);
    }
    final confirmed = await selectTeamMembers(context, form);
    final current = repository.find(team.id);
    if (confirmed == true && current != null) {
      repository.update(
        current.copyWith(providers: form.state.memberServices.values.toList()),
      );
    }
  } finally {
    await form.close();
  }
}
