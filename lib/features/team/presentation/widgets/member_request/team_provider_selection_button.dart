import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/team_strings.dart';
import 'package:hywork/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:hywork/features/team/domain/team_provider_selection.dart';
import 'package:hywork/features/team/presentation/cubit/team_form_cubit.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class TeamProviderSelectionButton extends StatelessWidget {
  const TeamProviderSelectionButton({
    super.key,
    required this.form,
    required this.post,
    required this.provider,
  });

  final TeamFormCubit form;
  final PostItem post;
  final PostSeller provider;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TeamFormCubit, TeamFormState>(
        bloc: form,
        builder: (context, state) {
          final selected = state.hasMember(provider.id);
          final colors = Theme.of(context).colorScheme;
          return IconButton(
            tooltip: selected
                ? TeamStrings.removeMember(provider.name)
                : TeamStrings.addMember(provider.name),
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerHighest,
              foregroundColor: colors.onSurface,
              shape: const CircleBorder(),
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => form.toggleProvider(
              TeamProviderSelection(
                post: post,
                provider: provider,
                quantity: context.read<PostDetailCubit>().state.quantity,
              ),
            ),
            icon: AppIcon(
              selected ? AppIcons.check : AppIcons.addPerson,
              size: 26,
            ),
          );
        },
      );
}
