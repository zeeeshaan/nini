import 'dart:async';

import 'package:hywork/features/team/domain/team_request.dart';
import 'package:hywork/features/team/domain/team_workspace.dart';

/// Session-only team previews. No disk or network operations.
class InMemoryTeamsRepository {
  InMemoryTeamsRepository();
  static final instance = InMemoryTeamsRepository();

  final _teams = <String, TeamWorkspace>{};
  final _changes = StreamController<List<TeamWorkspace>>.broadcast();
  String? _accountId;
  final _accounts = <String, Map<String, TeamWorkspace>>{};

  void useAccount(String? accountId) {
    if (_accountId == accountId) return;
    final previous = _accountId;
    if (previous != null) _accounts[previous] = Map.of(_teams);
    _teams.clear();
    _teams.addAll(_accounts.remove(accountId) ?? {});
    _accountId = accountId;
    _changes.add(teams);
  }

  List<TeamWorkspace> get teams =>
      List.unmodifiable(_teams.values.toList().reversed);
  Stream<List<TeamWorkspace>> get changes => _changes.stream;
  TeamWorkspace? find(String id) => _teams[id];

  void addPaid(TeamWorkspace team) {
    if (team.request.status != TeamRequestStatus.paid ||
        team.request.paymentId == null) {
      return;
    }
    _teams.putIfAbsent(team.id, () => team);
    _changes.add(teams);
  }

  void update(TeamWorkspace team) {
    if (!_teams.containsKey(team.id)) return;
    _teams[team.id] = team;
    _changes.add(teams);
  }

  void delete(String id) {
    _teams.remove(id);
    _changes.add(teams);
  }

  void refresh() => _changes.add(teams);

  Future<void> dispose() => _changes.close();
}
