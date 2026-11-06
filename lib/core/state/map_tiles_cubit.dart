import 'package:flutter_bloc/flutter_bloc.dart';

class MapTilesState {
  const MapTilesState({this.failed = false, this.attempt = 0});
  final bool failed;
  final int attempt;
}

class MapTilesCubit extends Cubit<MapTilesState> {
  MapTilesCubit() : super(const MapTilesState());
  void fail() {
    if (!state.failed) {
      emit(MapTilesState(failed: true, attempt: state.attempt));
    }
  }

  void retry() => emit(MapTilesState(attempt: state.attempt + 1));
}
