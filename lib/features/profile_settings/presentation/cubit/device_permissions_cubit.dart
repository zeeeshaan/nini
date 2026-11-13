import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/device_permissions_repository.dart';

class DevicePermissionsState {
  const DevicePermissionsState({
    this.values = const {},
    this.loading = false,
    this.failed = false,
    this.opening = false,
    this.settingsFailed = false,
  });
  final Map<DeviceAccess, DeviceAccessStatus> values;
  final bool loading, failed, opening, settingsFailed;
}

class DevicePermissionsCubit extends Cubit<DevicePermissionsState> {
  DevicePermissionsCubit(this.repository)
    : super(const DevicePermissionsState());
  final DevicePermissionsRepository repository;

  Future<void> load() async {
    if (isClosed || state.loading) {
      return;
    }
    emit(DevicePermissionsState(values: state.values, loading: true));
    try {
      final values = await repository.read();
      if (!isClosed) {
        emit(DevicePermissionsState(values: Map.unmodifiable(values)));
      }
    } catch (_) {
      if (!isClosed) {
        emit(DevicePermissionsState(values: state.values, failed: true));
      }
    }
  }

  Future<void> openSettings() async {
    if (state.opening || isClosed) {
      return;
    }
    emit(DevicePermissionsState(values: state.values, opening: true));
    var opened = false;
    try {
      opened = await repository.openSettings();
    } catch (_) {
      /* Report below. */
    }
    if (!isClosed) {
      emit(
        DevicePermissionsState(values: state.values, settingsFailed: !opened),
      );
    }
  }
}
