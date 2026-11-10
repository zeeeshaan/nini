import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/team_strings.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/search/presentation/pages/search_screen.dart';
import 'package:nini/features/team/presentation/cubit/team_form_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

Future<void> selectTeamMembers(BuildContext context, TeamFormCubit form) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (searchContext) => Scaffold(
        appBar: AppBar(
          title: const Text(
            TeamStrings.selectMembers,
            textAlign: TextAlign.right,
          ),
          actions: [
            BlocBuilder<TeamFormCubit, TeamFormState>(
              bloc: form,
              builder: (context, state) => ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: TextButton(
                  onPressed: () => Navigator.of(searchContext).pop(),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(TeamStrings.done(state.members.length)),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SearchScreen(
            onPostSelected: (post, seller) {
              Navigator.of(searchContext).push<void>(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    post: post,
                    seller: seller,
                    purchaseTrailing: BlocBuilder<TeamFormCubit, TeamFormState>(
                      bloc: form,
                      builder: (context, state) {
                        final selected = state.hasMember(seller.id);
                        final colors = Theme.of(context).colorScheme;
                        return IconButton(
                          tooltip: selected
                              ? TeamStrings.removeMember(seller.name)
                              : TeamStrings.addMember(seller.name),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.surfaceContainerHighest,
                            foregroundColor: colors.onSurface,
                            shape: const CircleBorder(),
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () {
                            form.toggleMember(seller);
                          },
                          icon: AppIcon(
                            selected ? AppIcons.check : AppIcons.addPerson,
                            size: 26,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
