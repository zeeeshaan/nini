import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/post_analytics.dart';

class AnalyticsControlsState {
  const AnalyticsControlsState({
    this.period = AnalyticsPeriod.halfYear,
    this.selected,
    this.first = true,
    this.second = true,
    this.inspecting = false,
    this.tooltip = true,
  });
  final AnalyticsPeriod period;
  final int? selected;
  final bool first, second, inspecting, tooltip;
  AnalyticsControlsState copyWith({
    AnalyticsPeriod? period,
    int? selected,
    bool? first,
    bool? second,
    bool? inspecting,
    bool? tooltip,
  }) => AnalyticsControlsState(
    period: period ?? this.period,
    selected: selected ?? this.selected,
    first: first ?? this.first,
    second: second ?? this.second,
    inspecting: inspecting ?? this.inspecting,
    tooltip: tooltip ?? this.tooltip,
  );
}

class AnalyticsControlsCubit extends Cubit<AnalyticsControlsState> {
  AnalyticsControlsCubit() : super(const AnalyticsControlsState());
  void changePeriod(AnalyticsPeriod period, {bool resetSelection = false}) =>
      emit(
        state.copyWith(
          period: period,
          selected: resetSelection ? 0 : null,
          inspecting: resetSelection ? false : null,
        ),
      );
  void select(int index) =>
      emit(state.copyWith(selected: index, inspecting: true));
  void next(int count) => select(((state.selected ?? 0) + 1) % count);
  void toggleFirst() => emit(state.copyWith(first: !state.first));
  void toggleSecond() => emit(state.copyWith(second: !state.second));
  void toggleTooltip() => emit(state.copyWith(tooltip: !state.tooltip));
}
