import 'package:nini/shared/widgets/app_back_button/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/team/data/in_memory_teams_repository.dart';
import 'package:nini/features/team/presentation/cubit/teams_cubit.dart';
import 'package:nini/features/team/presentation/helpers/add_team_people.dart';
import 'package:nini/features/team/presentation/widgets/common/team_search_field.dart';
import 'package:nini/features/team/presentation/widgets/people/team_person_card.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class TeamPeopleScreen extends StatelessWidget {
  const TeamPeopleScreen({
    super.key,
    required this.teamId,
    required this.repository,
  });
  final String teamId;
  final InMemoryTeamsRepository repository;

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
            body: const Center(
              child: Text(
                "تیم در دسترس نیست",
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          );
        }
        final query = state.query.trim().toLowerCase();
        final people = team.members.where((person) {
          final selection = team.providers
              .where((entry) => entry.provider.id == person.id)
              .firstOrNull;
          return '${person.name} ${selection?.post.title ?? "مدیر تیم"}'
              .toLowerCase()
              .contains(query);
        }).toList();
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: "افزودن افراد",
              onPressed: () => addTeamPeople(context, team, repository),
              icon: const AppIcon(AppIcons.add, size: 26),
            ),
            title: const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "اعضا",
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
            actions: [
              IconButton(
                tooltip: "بازگشت",
                onPressed: () => Navigator.of(context).pop(),
                icon: const RotatedBox(
                  quarterTurns: 2,
                  child: AppIcon(AppIcons.back, size: 20),
                ),
              ),
            ],
          ),
          body: AppResponsiveBuilder(
            builder: (context, responsive) {
              final padding = responsive.horizontalPadding;
              final width = responsive.width.clamp(0.0, 720.0) - padding * 2;
              final columns = responsive.width < 360
                  ? 2
                  : responsive.isCompact
                  ? 3
                  : 4;
              final cardWidth = (width - (columns - 1) * 16) / columns;
              final avatarSize = cardWidth.clamp(48.0, 88.0);
              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          TeamSearchField(
                            onChanged: context.read<TeamsCubit>().search,
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: people.isEmpty
                                ? const Center(
                                    child: Text(
                                      "فردی مطابق جستجوی شما یافت نشد",
                                      textAlign: TextAlign.right,
                                      style: AppTextStyles.bodyText,
                                      textDirection: TextDirection.rtl,
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Wrap(
                                        textDirection: TextDirection.rtl,
                                        spacing: 16,
                                        runSpacing: 24,
                                        children: [
                                          for (final person in people)
                                            SizedBox(
                                              width: cardWidth,
                                              child: TeamPersonCard(
                                                person: person,
                                                avatarSize: avatarSize,
                                                selection: team.providers
                                                    .where(
                                                      (entry) =>
                                                          entry.provider.id ==
                                                          person.id,
                                                    )
                                                    .firstOrNull,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
