import 'package:nini/shared/widgets/app_back_button/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/presentation/pages/conversation_screen.dart';
import 'package:nini/features/team/data/in_memory_teams_repository.dart';
import 'package:nini/features/team/presentation/cubit/teams_cubit.dart';
import 'package:nini/features/team/presentation/pages/team_people_screen.dart';
import 'package:nini/features/team/presentation/widgets/conversation/team_chat_members_bar.dart';
import 'package:nini/features/team/presentation/widgets/conversation/team_chat_title.dart';

class TeamChatScreen extends StatelessWidget {
  const TeamChatScreen({
    super.key,
    required this.teamId,
    required this.repository,
  });
  final String teamId;
  final InMemoryTeamsRepository repository;

  void _people(BuildContext context) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TeamPeopleScreen(teamId: teamId, repository: repository),
    ),
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TeamsCubit(repository),
    child: BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final team = state.teams.where((team) => team.id == teamId).firstOrNull;
        if (team == null) {
          return Scaffold(
            appBar: AppBar(
              actions: [const AppBackButton()],

              automaticallyImplyLeading: false,
            ),
            body: const Center(child: Text('Team unavailable')),
          );
        }
        return ConversationScreen(
          key: ValueKey(team.conversationId),
          conversation: ChatConversation(
            id: team.conversationId,
            name: team.name,
            lastMessage: '',
            lastMessageAt: team.createdAt,
          ),
          repository: repository.chats,
          headerTitle: TeamChatTitle(
            name: team.name,
            onTap: () => _people(context),
          ),
          headerBottom: TeamChatMembersBar(
            members: team.members,
            onTap: () => _people(context),
          ),
          allowBlocking: false,
          onLatestMessageChanged: (_) => repository.refresh(),
        );
      },
    ),
  );
}
