import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_option_selection.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/address_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/features_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_form_option_tile.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/preparation_time_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/schedule_post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/tags_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/unit_dialog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostOptionsSection extends StatelessWidget {
  const PostOptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final draftCubit = context.read<CreatePostCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocSelector<CreatePostCubit, PostDraft, PreparationTime>(
          selector: (state) => state.preparationTime,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.preparationTime,
            value: CreatePostStrings.optionLabel(value),
            trailing: const AppIcon(AppIcons.clock, size: 18),
            onTap: () => choosePostOption<PreparationTime>(
              context,
              PreparationTimeDialog(selected: draftCubit.state.preparationTime),
              draftCubit.selectPreparationTime,
            ),
          ),
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, PostUnit>(
          selector: (state) => state.unit,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.unit,
            value: CreatePostStrings.optionLabel(value),
            onTap: () => choosePostOption<PostUnit>(
              context,
              UnitDialog(selected: draftCubit.state.unit),
              draftCubit.selectUnit,
            ),
          ),
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, PostSchedule?>(
          selector: (state) => state.schedule,
          builder: (context, schedule) {
            final scheduleLabel = schedule == null
                ? null
                : '${MaterialLocalizations.of(context).formatMediumDate(schedule.startsAt)} · ${TimeOfDay.fromDateTime(schedule.startsAt).format(context)} – ${TimeOfDay.fromDateTime(schedule.endsAt).format(context)}';
            return PostFormOptionTile(
              label: CreatePostStrings.scheduledPosts,
              value: scheduleLabel,
              trailing: const AppIcon(AppIcons.calendar, size: 18),
              onTap: () => choosePostOption<ScheduleSelection>(
                context,
                SchedulePostDialog(initial: schedule),
                (result) => draftCubit.setSchedule(result.schedule),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, PostAddress?>(
          selector: (state) => state.address,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.location,
            value: value?.address,
            trailing: const AppIcon(AppIcons.location, size: 18),
            onTap: () => choosePostOption<AddressSelection>(
              context,
              AddressDialog(
                allowManualEntry: true,
                initial: draftCubit.state.address,
                saved: draftCubit.state.savedAddresses,
              ),
              draftCubit.setAddress,
            ),
          ),
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, List<PostFeature>>(
          selector: (state) => state.features,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.featuresHeading,
            value: value.isEmpty
                ? null
                : CreatePostStrings.featureCount(value.length),
            trailing: const AppIcon(AppIcons.features, size: 18),
            onTap: () => choosePostOption<List<PostFeature>>(
              context,
              FeaturesDialog(initial: draftCubit.state.features),
              draftCubit.setFeatures,
            ),
          ),
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, List<String>>(
          selector: (state) => state.tags,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.tagsKeywords,
            value: value.isEmpty ? null : value.map((tag) => '#$tag').join(' '),
            onTap: () => choosePostOption<List<String>>(
              context,
              TagsDialog(initial: draftCubit.state.tags),
              draftCubit.setTags,
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
