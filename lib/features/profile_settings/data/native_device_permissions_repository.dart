import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../domain/device_permissions_repository.dart';

/// Reads access only. Changes are made by the user in OS settings, preserving
/// the permission requests already owned by Gallery, Chat and location picking.
class NativeDevicePermissionsRepository implements DevicePermissionsRepository {
  DeviceAccessStatus _status(PermissionStatus status) {
    if (status.isGranted) {
      return DeviceAccessStatus.granted;
    }
    if (status.isLimited || status.isProvisional) {
      return DeviceAccessStatus.limited;
    }
    if (status.isRestricted) {
      return DeviceAccessStatus.restricted;
    }
    return DeviceAccessStatus.denied;
  }

  @override
  Future<Map<DeviceAccess, DeviceAccessStatus>> read() async {
    final values = await Future.wait([
      Permission.camera.status,
      Permission.microphone.status,
      Permission.locationWhenInUse.status,
    ]);
    final photos = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: false,
        ),
      ),
    );
    return Map.unmodifiable({
      DeviceAccess.camera: _status(values[0]),
      DeviceAccess.microphone: _status(values[1]),
      DeviceAccess.location: _status(values[2]),
      DeviceAccess.photos: photos == PermissionState.authorized
          ? DeviceAccessStatus.granted
          : photos == PermissionState.limited
          ? DeviceAccessStatus.limited
          : photos == PermissionState.restricted
          ? DeviceAccessStatus.restricted
          : DeviceAccessStatus.denied,
    });
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
