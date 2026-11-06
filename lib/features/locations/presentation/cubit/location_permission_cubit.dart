import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/location_strings.dart';
import 'package:nini/core/permissions/location_permission_service.dart';

class LocationPermissionState {
  const LocationPermissionState({this.busy = false, this.error});
  final bool busy;
  final String? error;
}

class LocationPermissionCubit extends Cubit<LocationPermissionState> {
  LocationPermissionCubit() : super(const LocationPermissionState());
  Future<bool> request(
    LocationPermissionService service,
    LocationAccessChoice choice,
  ) async {
    if (state.busy) return false;
    emit(const LocationPermissionState(busy: true));
    try {
      await service.request(choice);
      return true;
    } catch (_) {
      if (!isClosed) {
        emit(
          const LocationPermissionState(
            error: LocationStrings.permissionUnavailable,
          ),
        );
      }
      return false;
    }
  }
}
