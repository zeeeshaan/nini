import 'package:nini/features/posts/presentation/cubit/post_editor_fields_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/shared/models/post/post_attributes.dart';

class PostEditorScheduleField extends StatefulWidget {
  const PostEditorScheduleField({super.key});
  @override
  State<PostEditorScheduleField> createState() =>
      _PostEditorScheduleFieldState();
}

class _PostEditorScheduleFieldState extends State<PostEditorScheduleField> {
  late final _original = context.read<CreatePostCubit>().state.schedule;
  PostEditorFieldsCubit get _fields => context.read<PostEditorFieldsCubit>();
  Future<DateTime?> _pick(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String? _validate(bool? _) {
    if (_fields.state.startsAt == null && _fields.state.endsAt == null) {
      return null;
    }
    // Existing historical schedules may be retained when editing another field.
    if (_fields.state.startsAt == _original?.startsAt &&
        _fields.state.endsAt == _original?.endsAt) {
      return null;
    }
    return _fields.state.startsAt == null ||
            _fields.state.endsAt == null ||
            !_fields.state.startsAt!.isAfter(DateTime.now()) ||
            !_fields.state.endsAt!.isAfter(_fields.state.startsAt!)
        ? ProfilePostStrings.invalidSchedule
        : null;
  }

  String _label(BuildContext context, String title, DateTime? value) {
    if (value == null) return title;
    return AppStrings.persianDigits(
      '$title: ${MaterialLocalizations.of(context).formatMediumDate(value)} · ${TimeOfDay.fromDateTime(value).format(context)}',
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PostEditorFieldsCubit, PostEditorFieldsState>(
    bloc: _fields,
    builder: (context, state) => FormField<bool>(
      validator: _validate,
      onSaved: (_) => context.read<CreatePostCubit>().setSchedule(
        _fields.state.startsAt == null || _fields.state.endsAt == null
            ? null
            : PostSchedule(
                startsAt: _fields.state.startsAt!,
                endsAt: _fields.state.endsAt!,
              ),
      ),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ProfilePostStrings.schedule,
            style: Theme.of(context).textTheme.titleMedium,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final value = await _pick(_fields.state.startsAt);
              if (value != null && mounted) {
                _fields.start(value);
                field.didChange(true);
              }
            },
            child: Text(
              _label(context, ProfilePostStrings.start, _fields.state.startsAt),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final value = await _pick(
                _fields.state.endsAt ?? _fields.state.startsAt,
              );
              if (value != null && mounted) {
                _fields.end(value);
                field.didChange(true);
              }
            },
            child: Text(
              _label(context, ProfilePostStrings.end, _fields.state.endsAt),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
          if (_fields.state.startsAt != null || _fields.state.endsAt != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _fields.clearSchedule();
                  field.didChange(true);
                },
                child: const Text(
                  ProfilePostStrings.clearSchedule,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          if (field.hasError)
            Text(
              field.errorText!,
              style: AppTextStyles.inherit.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
        ],
      ),
    ),
  );
}
