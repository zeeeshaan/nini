import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/team_strings.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/search/presentation/pages/search_screen.dart';
import 'package:nini/features/team/presentation/cubit/team_form_cubit.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_provider_selection_button.dart';

Future<bool?> selectTeamMembers(
  BuildContext context,
  TeamFormCubit form,
) async {
  return Navigator.of(context).push<bool>(
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
                  onPressed: () => Navigator.of(searchContext).pop(true),
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
                    purchaseTrailing: TeamProviderSelectionButton(
                      form: form,
                      post: post,
                      provider: seller,
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
