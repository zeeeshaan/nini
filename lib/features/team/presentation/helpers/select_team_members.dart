import 'package:nini/shared/widgets/app_back_button/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/team_strings.dart';
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
          automaticallyImplyLeading: false,
          title: const Text(
            TeamStrings.selectMembers,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
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
                    child: Text(
                      TeamStrings.done(state.members.length),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
            ),

            const AppBackButton(),
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
