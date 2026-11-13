enum DeviceAccess { camera, microphone, photos, location }

enum DeviceAccessStatus { granted, denied, restricted, limited, unknown }

abstract class DevicePermissionsRepository {
  Future<Map<DeviceAccess, DeviceAccessStatus>> read();
  Future<bool> openSettings();
}
