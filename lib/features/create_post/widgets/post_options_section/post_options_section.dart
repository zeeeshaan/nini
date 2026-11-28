import 'package:hywork/shared/widgets/calendar/app_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/models/post_draft.dart';
import 'package:hywork/features/create_post/cubit/create_post_cubit.dart';
import 'package:hywork/features/create_post/utils/post_option_selection.dart';
import 'package:hywork/features/create_post/widgets/address_dialog/address_dialog.dart';
import 'package:hywork/features/create_post/widgets/features_dialog/features_dialog.dart';
import 'package:hywork/features/create_post/widgets/post_form_option_tile/post_form_option_tile.dart';
import 'package:hywork/features/create_post/widgets/preparation_time_dialog/preparation_time_dialog.dart';
import 'package:hywork/features/create_post/widgets/schedule_post_dialog/schedule_post_dialog.dart';
import 'package:hywork/features/create_post/widgets/tags_dialog/tags_dialog.dart';
import 'package:hywork/features/create_post/widgets/unit_dialog/unit_dialog.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

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
            value: value == PreparationTime.none
                ? null
                : CreatePostStrings.optionLabel(value),
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
                : '${formatSolarDate(schedule.startsAt)} · ${TimeOfDay.fromDateTime(schedule.startsAt).format(context)} – ${TimeOfDay.fromDateTime(schedule.endsAt).format(context)}';
            return PostFormOptionTile(
              label: CreatePostStrings.scheduledPosts,
              value: scheduleLabel,
              trailing: const AppIcon(AppIcons.calendarDays, size: 18),
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
          builder: (context, value) {
            final address = value?.address.trim();
            final hasAddress = address != null && address.isNotEmpty;
            return PostFormOptionTile(
              label: hasAddress ? address : CreatePostStrings.location,
              trailing: const AppIcon(AppIcons.mapWithPin, size: 18),
              onTap: () => choosePostOption<AddressSelection>(
                context,
                AddressDialog(
                  allowManualEntry: true,
                  initial: draftCubit.state.address,
                  saved: draftCubit.state.savedAddresses,
                ),
                draftCubit.setAddress,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, List<PostFeature>>(
          selector: (state) => state.features,
          builder: (context, _) => PostFormOptionTile(
            label: CreatePostStrings.featuresHeading,
            trailing: const AppIcon(AppIcons.form, size: 18),
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
          builder: (context, value) {
            final theme = Theme.of(context);
            return PostFormOptionTile(
              label: CreatePostStrings.tagsKeywords,
              trailing: Text(
                '#',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              footer: value.isEmpty
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        textDirection: TextDirection.rtl,
                        children: [
                          for (final tag in value)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: .06,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
              onTap: () => choosePostOption<List<String>>(
                context,
                TagsDialog(initial: draftCubit.state.tags),
                draftCubit.setTags,
              ),
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
