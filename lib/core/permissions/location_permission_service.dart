import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationAccessChoice { once, whileUsing, always, deny }

/// Native permission handling only. This service never reads/tracks location.
class LocationPermissionService {
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> hasAccess() => Permission.locationWhenInUse.isGranted;

  Future<void> request(LocationAccessChoice choice) async {
    if (!isSupported || choice == LocationAccessChoice.deny) return;
    var status = await Permission.locationWhenInUse.status;
    if (status.isRestricted) return;
    if (status.isPermanentlyDenied) {
      await _openSettings();
      return;
    }

    // Both foreground choices open the OS selector. The device controls whether
    // the grant is one-time or while-in-use; a custom button cannot set that.
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (!status.isGranted || choice != LocationAccessChoice.always) return;
    if (await Permission.locationAlways.isGranted) return;

    // Request background access separately, after foreground has been granted.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _openSettings();
    } else {
      await Permission.locationAlways.request();
    }
  }

  Future<void> _openSettings() async {
    if (!await openAppSettings()) {
      throw StateError('Could not open location permission settings');
    }
  }
}
