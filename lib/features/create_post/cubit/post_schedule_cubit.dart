import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';

import 'package:hywork/features/create_post/models/post_options.dart';

class PostScheduleState {
  const PostScheduleState({
    required this.date,
    required this.from,
    required this.to,
    this.editingFrom = true,
    this.tab = 1,
    this.error,
  });
  final DateTime date;
  final TimeOfDay from, to;
  final bool editingFrom;
  final int tab;
  final String? error;
  PostScheduleState copyWith({
    DateTime? date,
    TimeOfDay? from,
    TimeOfDay? to,
    bool? editingFrom,
    int? tab,
    String? error,
    bool clearError = false,
  }) => PostScheduleState(
    date: date ?? this.date,
    from: from ?? this.from,
    to: to ?? this.to,
    editingFrom: editingFrom ?? this.editingFrom,
    tab: tab ?? this.tab,
    error: clearError ? null : error ?? this.error,
  );
}

class PostScheduleCubit extends Cubit<PostScheduleState> {
  PostScheduleCubit(PostSchedule? initial, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(_initial(initial, clock ?? DateTime.now));
  final DateTime Function() _clock;
  static PostScheduleState _initial(
    PostSchedule? initial,
    DateTime Function() clock,
  ) {
    final nextHour = clock().add(const Duration(hours: 1));
    final start = initial != null && initial.startsAt.isAfter(clock())
        ? initial.startsAt
        : nextHour;
    return PostScheduleState(
      date: DateUtils.dateOnly(start),
      from: TimeOfDay.fromDateTime(start),
      to: TimeOfDay.fromDateTime(
        initial != null && initial.endsAt.isAfter(start)
            ? initial.endsAt
            : start.add(const Duration(hours: 1)),
      ),
    );
  }

  void changeTab(int tab) {
    if (state.tab != tab) emit(state.copyWith(tab: tab));
  }

  void editFrom(bool from) => emit(state.copyWith(editingFrom: from));
  void changeDate(DateTime date) =>
      emit(state.copyWith(date: date, clearError: true));
  void changeTime(DateTime date, {required bool from}) {
    final time = TimeOfDay.fromDateTime(date);
    emit(
      state.copyWith(
        from: from ? time : null,
        to: from ? null : time,
        clearError: true,
      ),
    );
  }

  PostSchedule? save() {
    final date = state.date;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      state.from.hour,
      state.from.minute,
    );
    var end = DateTime(
      date.year,
      date.month,
      date.day,
      state.to.hour,
      state.to.minute,
    );
    if (state.from == state.to) {
      emit(state.copyWith(error: CreatePostStrings.differentTimesRequired));
      return null;
    }
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    if (!start.isAfter(_clock())) {
      emit(state.copyWith(error: CreatePostStrings.futureTimeRequired));
      return null;
    }
    return PostSchedule(startsAt: start, endsAt: end);
  }
}
