import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/team_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/chat/widgets/chat_message_composer/chat_message_composer.dart';
import 'package:hywork/features/team/data/in_memory_teams_repository.dart';
import 'package:hywork/features/team/presentation/cubit/teams_cubit.dart';
import 'package:hywork/features/team/presentation/pages/team_people_screen.dart';
import 'package:hywork/features/team/presentation/widgets/conversation/team_chat_members_bar.dart';
import 'package:hywork/features/team/presentation/widgets/conversation/team_chat_title.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/shared/widgets/app_back_button/app_back_button.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

/// Team conversation shell.
///
/// Backend peer Chat APIs are one-to-one only. Group/team messaging has no
/// supported contract yet, so this screen keeps the existing Team chat chrome
/// and blocks simulated local sends.
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
              actions: const [AppBackButton()],
              automaticallyImplyLeading: false,
            ),
            body: const Center(
              child: Text(
                'Team unavailable',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          );
        }

        return _TeamChatUnavailableView(
          teamName: team.name,
          members: team.members,
          onPeople: () => _people(context),
        );
      },
    ),
  );
}

class _TeamChatUnavailableView extends StatefulWidget {
  const _TeamChatUnavailableView({
    required this.teamName,
    required this.members,
    required this.onPeople,
  });

  final String teamName;
  final List<PostSeller> members;
  final VoidCallback onPeople;

  @override
  State<_TeamChatUnavailableView> createState() =>
      _TeamChatUnavailableViewState();
}

class _TeamChatUnavailableViewState extends State<_TeamChatUnavailableView> {
  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _unavailable() {
    AppToast.warning(context, TeamStrings.messagingUnavailable);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toolbarHeight =
        (MediaQuery.textScalerOf(context).scale(15) * 1.4 +
                MediaQuery.textScalerOf(context).scale(11) * 1.4 +
                8)
            .clamp(70, double.infinity)
            .toDouble();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: toolbarHeight,
          centerTitle: false,
          titleSpacing: 0,
          title: Align(
            alignment: Alignment.centerRight,
            child: TeamChatTitle(name: widget.teamName, onTap: widget.onPeople),
          ),
          bottom: TeamChatMembersBar(
            members: widget.members,
            onTap: widget.onPeople,
          ),
          actions: const [AppBackButton()],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    TeamStrings.messagingUnavailable,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.comfortableBody.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _unavailable,
              child: IgnorePointer(
                child: ChatMessageComposer(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  enabled: false,
                  onSend: () {},
                  onEmojiPressed: () {},
                  onAttachmentPressed: () {},
                  onPhotosPressed: () {},
                  onRecord: () {},
                  onKeyboardRequested: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
