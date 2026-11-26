import 'package:hywork/shared/widgets/app_back_button/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/team_strings.dart';
import 'package:hywork/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:hywork/features/search/presentation/pages/search_screen.dart';
import 'package:hywork/features/team/presentation/cubit/team_form_cubit.dart';
import 'package:hywork/features/team/presentation/widgets/member_request/team_provider_selection_button.dart';

Future<bool?> selectTeamMembers(
  BuildContext context,
  TeamFormCubit form,
) async {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (searchContext) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Row(
            textDirection: TextDirection.ltr,
            children: [
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
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  TeamStrings.selectMembers,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
          actions: const [AppBackButton()],
        ),
        body: SafeArea(
          top: false,
          child: SearchScreen(
            emptyStateTextAlign: TextAlign.center,
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
