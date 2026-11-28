import 'package:flutter/foundation.dart';
import 'package:hywork/core/config/app_config/app_config.dart';

/// Derives the documented Socket.IO origin + path from [AppConfig.apiBaseUrl].
abstract final class RealtimeSocketConfig {
  static const path = '/api/socket.io';

  /// Socket.IO connect URL is the API host origin (no `/api` suffix).
  static String originFromApiBaseUrl([String? apiBaseUrl]) {
    final raw = (apiBaseUrl ?? AppConfig.apiBaseUrl).trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) {
      throw StateError('A valid API base URL is required for realtime.');
    }
    final allowHttp =
        uri.scheme == 'http' && (kDebugMode || AppConfig.allowHttpApi);
    if (uri.scheme != 'https' && !allowHttp) {
      throw StateError('Realtime requires HTTPS (WSS) outside debug builds.');
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  /// True when the configured origin is cleartext HTTP (debug-only allowed).
  static bool get usesInsecureTransport {
    final uri = Uri.tryParse(AppConfig.apiBaseUrl.trim());
    return uri?.scheme == 'http';
  }
}
