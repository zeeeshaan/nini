import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/team/data/in_memory_teams_repository.dart';
import 'package:nini/features/team/presentation/cubit/teams_cubit.dart';
import 'package:nini/features/team/presentation/helpers/manage_team.dart';
import 'package:nini/features/team/presentation/pages/team_chat_screen.dart';
import 'package:nini/features/team/presentation/widgets/common/team_search_field.dart';
import 'package:nini/features/team/presentation/widgets/my_teams/my_teams_header.dart';
import 'package:nini/features/team/presentation/widgets/my_teams/team_card.dart';
import 'package:nini/features/team/presentation/widgets/my_teams/team_empty_state.dart';

import 'create_team.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({
    super.key,
    this.onCreateTeam,
    this.onSearchChanged,
    this.emptyImageAsset = 'assets/teamimg.png',
    this.repository,
  });
  final VoidCallback? onCreateTeam;
  final ValueChanged<String>? onSearchChanged;
  final String emptyImageAsset;
  final InMemoryTeamsRepository? repository;

  void _openCreateTeam(
    BuildContext context,
    InMemoryTeamsRepository repository,
  ) {
    if (onCreateTeam != null) {
      onCreateTeam!();
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CreateTeamScreen(teamsRepository: repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = repository ?? InMemoryTeamsRepository.instance;
    return BlocProvider(
      create: (_) => TeamsCubit(teams),
      child: Scaffold(
        appBar: MyTeamsHeader(onCreate: () => _openCreateTeam(context, teams)),
        body: AppResponsiveBuilder(
          builder: (context, responsive) => BlocBuilder<TeamsCubit, TeamsState>(
            builder: (context, state) {
              final visible = state.visibleTeams;
              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalPadding,
                      ),
                      children: [
                        const SizedBox(height: 16),
                        TeamSearchField(
                          onChanged: (value) {
                            context.read<TeamsCubit>().search(value);
                            onSearchChanged?.call(value);
                          },
                        ),
                        const SizedBox(height: 24),
                        if (visible.isEmpty)
                          TeamEmptyState(
                            imageAsset: emptyImageAsset,
                            imageWidth: responsive.adaptive(
                              compact: 210.0,
                              medium: 250.0,
                              expanded: 280.0,
                            ),
                            searching: state.query.trim().isNotEmpty,
                          )
                        else
                          for (final team in visible)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TeamCard(
                                team: team,
                                messageCount:
                                    teams.chats
                                        .existingMessages(team.conversationId)
                                        ?.length ??
                                    0,
                                onTap: () => Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => TeamChatScreen(
                                      teamId: team.id,
                                      repository: teams,
                                    ),
                                  ),
                                ),
                                onMore: () => manageTeam(
                                  context,
                                  team,
                                  teams,
                                  onChat: () =>
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) => TeamChatScreen(
                                            teamId: team.id,
                                            repository: teams,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
