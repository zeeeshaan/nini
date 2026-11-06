import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/location_strings.dart';

class LocationsState {
  const LocationsState({
    this.labels = LocationStrings.initialLabels,
    this.selected,
  });
  final List<String> labels;
  final String? selected;
}

class LocationsCubit extends Cubit<LocationsState> {
  LocationsCubit() : super(const LocationsState());
  void add(String name) {
    if (name.isEmpty) return;
    final labels = state.labels.contains(name)
        ? state.labels
        : List<String>.unmodifiable([...state.labels, name]);
    emit(LocationsState(labels: labels, selected: name));
  }

  void select(String name) =>
      emit(LocationsState(labels: state.labels, selected: name));
}
