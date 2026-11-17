import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _installationChannel = MethodChannel('hywork/installation');
  static const _installationKey = 'auth_installation';
  final FlutterSecureStorage _storage;
  Future<void>? _installationReady;

  Future<void> _ensureInstallation() => _installationReady ??=
      _initializeInstallation().onError<Object>((error, stack) {
        _installationReady = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _initializeInstallation() async {
    if (kIsWeb ||
        !const [
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return;
    }
    final installation = await _installationChannel.invokeMethod<String>(
      'getInstallationId',
    );
    if (installation == null || installation.isEmpty) {
      throw const FormatException('Installation identity is unavailable.');
    }
    final previous = await _storage.read(key: _installationKey);
    if (previous == installation) return;
    // Keychain or restored credentials must never authenticate a new install.
    await _storage.delete(key: 'auth_token');
    await _storage.write(key: _installationKey, value: installation);
  }

  Future<void> saveToken(String token) async {
    await _ensureInstallation();
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    await _ensureInstallation();
    return _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _ensureInstallation();
    await _storage.delete(key: 'auth_token');
  }
}
