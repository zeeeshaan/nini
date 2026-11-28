import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

/// Share the plugin's process-wide observer across overlapping gallery routes.
/// This also catches limited-selection changes on iOS 14, whose picker returns
/// before its native selection UI closes.
abstract final class GalleryLibraryChanges {
  static int _listeners = 0;
  static Future<void> _pending = Future.value();

  static VoidCallback listen(VoidCallback onChanged) {
    void callback(MethodCall _) => onChanged();
    PhotoManager.addChangeCallback(callback);
    if (_listeners++ == 0) _setEnabled(true);
    var active = true;
    return () {
      if (!active) return;
      active = false;
      PhotoManager.removeChangeCallback(callback);
      if (--_listeners == 0) _setEnabled(false);
    };
  }

  static void _setEnabled(bool enabled) {
    _pending = _pending.then((_) async {
      try {
        if (enabled) {
          await PhotoManager.startChangeNotify();
        } else {
          await PhotoManager.stopChangeNotify();
        }
      } catch (_) {
        // Resume/manual refresh still works when native notifications fail.
      }
    });
  }
}
