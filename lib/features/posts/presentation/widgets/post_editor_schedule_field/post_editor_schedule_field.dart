import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
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
  late DateTime? _start = _original?.startsAt, _end = _original?.endsAt;
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
    if (_start == null && _end == null) return null;
    // Existing historical schedules may be retained when editing another field.
    if (_start == _original?.startsAt && _end == _original?.endsAt) return null;
    return _start == null ||
            _end == null ||
            !_start!.isAfter(DateTime.now()) ||
            !_end!.isAfter(_start!)
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
  Widget build(BuildContext context) => FormField<bool>(
    validator: _validate,
    onSaved: (_) => context.read<CreatePostCubit>().setSchedule(
      _start == null || _end == null
          ? null
          : PostSchedule(startsAt: _start!, endsAt: _end!),
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
            final value = await _pick(_start);
            if (value != null && mounted) {
              setState(() => _start = value);
              field.didChange(true);
            }
          },
          child: Text(
            _label(context, ProfilePostStrings.start, _start),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
        OutlinedButton(
          onPressed: () async {
            final value = await _pick(_end ?? _start);
            if (value != null && mounted) {
              setState(() => _end = value);
              field.didChange(true);
            }
          },
          child: Text(
            _label(context, ProfilePostStrings.end, _end),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
        if (_start != null || _end != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _start = null;
                  _end = null;
                });
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
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
      ],
    ),
  );
}
