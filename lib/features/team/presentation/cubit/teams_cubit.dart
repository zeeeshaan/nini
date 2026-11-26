import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/team/data/in_memory_teams_repository.dart';
import 'package:hywork/features/team/domain/team_workspace.dart';

class TeamsState {
  const TeamsState({required this.teams, this.query = ''});
  final List<TeamWorkspace> teams;
  final String query;

  List<TeamWorkspace> get visibleTeams => teams
      .where(
        (team) => '${team.name} ${team.description}'.toLowerCase().contains(
          query.trim().toLowerCase(),
        ),
      )
      .toList();
}

class TeamsCubit extends Cubit<TeamsState> {
  TeamsCubit(this.repository) : super(TeamsState(teams: repository.teams)) {
    _subscription = repository.changes.listen((teams) {
      if (!isClosed) emit(TeamsState(teams: teams, query: state.query));
    });
  }
  final InMemoryTeamsRepository repository;
  late final StreamSubscription<List<TeamWorkspace>> _subscription;

  void search(String value) =>
      emit(TeamsState(teams: state.teams, query: value));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
