import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hywork/core/notifications/push_notifications.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';

/// Uploads the traditional FCM token to `POST /notifications/devices`.
///
/// App-wide Firebase transport stays in [PushNotifications]. This class only
/// performs authenticated API sync and never blocks login or startup.
class PushDeviceSync {
  PushDeviceSync._();

  static final PushDeviceSync instance = PushDeviceSync._();

  ApiNotificationsRepository? _repository;
  bool Function()? _isCurrentAccount;
  String? _userId;
  int? _accountRevision;
  String? _confirmedToken;
  String? _confirmedUserId;
  int? _confirmedRevision;
  Future<void>? _registerInFlight;
  String? _registerInFlightKey;
  StreamSubscription<String>? _tokenSub;
  int _backoffAttempt = 0;
  int _generation = 0;
  bool _logoutInProgress = false;
  Timer? _retryTimer;

  /// Binds the account-scoped repository after authentication.
  void attach({
    required ApiNotificationsRepository repository,
    required bool Function() isCurrentAccount,
    required String userId,
    required int accountRevision,
  }) {
    _logoutInProgress = false;
    _repository = repository;
    _isCurrentAccount = isCurrentAccount;
    _userId = userId;
    _accountRevision = accountRevision;
    _tokenSub ??= PushNotifications.onToken.listen((_) {
      unawaited(sync());
    });
    unawaited(sync());
  }

  /// Drops account-owned pending registration state (after logout/switch).
  void detach({required int accountRevision}) {
    if (_accountRevision != null && _accountRevision != accountRevision) {
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _repository = null;
    _isCurrentAccount = null;
    _userId = null;
    _accountRevision = null;
    _confirmedToken = null;
    _confirmedUserId = null;
    _confirmedRevision = null;
    _registerInFlight = null;
    _registerInFlightKey = null;
    _backoffAttempt = 0;
    _logoutInProgress = false;
  }

  /// Registers the current FCM token for the attached account when needed.
  Future<void> sync() {
    if (!_canRegister) return Future.value();
    final token = PushNotifications.fcmToken?.trim();
    if (token == null || token.isEmpty) return Future.value();

    final userId = _userId!;
    final revision = _accountRevision!;
    final key = '$revision|$userId|$token';
    if (_confirmedToken == token &&
        _confirmedUserId == userId &&
        _confirmedRevision == revision) {
      return Future.value();
    }
    if (_registerInFlight != null && _registerInFlightKey == key) {
      return _registerInFlight!;
    }

    final future = _register(token: token, userId: userId, revision: revision);
    _registerInFlight = future;
    _registerInFlightKey = key;
    return future.whenComplete(() {
      if (identical(_registerInFlight, future)) {
        _registerInFlight = null;
        _registerInFlightKey = null;
      }
    });
  }

  Future<void> _register({
    required String token,
    required String userId,
    required int revision,
  }) async {
    final repository = _repository;
    final current = _isCurrentAccount;
    if (repository == null || current == null || !current()) return;
    final generation = _generation;

    try {
      final result = await repository.registerDevice(
        fcmToken: token,
        platform: _platform,
        locale: NotificationDeviceLocale.fa,
      );
      if (_logoutInProgress ||
          generation != _generation ||
          !current() ||
          _userId != userId ||
          _accountRevision != revision ||
          PushNotifications.fcmToken?.trim() != token) {
        return;
      }
      if (!result.registered) {
        throw const FormatException('Device registration was not confirmed.');
      }
      _confirmedToken = token;
      _confirmedUserId = userId;
      _confirmedRevision = revision;
      _backoffAttempt = 0;
      _retryTimer?.cancel();
      _retryTimer = null;
    } catch (error, stack) {
      if (_logoutInProgress || generation != _generation) return;
      debugPrint('PushDeviceSync.register failed: $error\n$stack');
      _scheduleRetry(error);
    }
  }

  void _scheduleRetry(Object error) {
    if (!_canRegister) return;
    if (error is FormatException) return;
    if (error is DioException && error.response?.statusCode == 401) return;
    if (error is DioException &&
        error.response != null &&
        error.response!.statusCode != null &&
        error.response!.statusCode! >= 400 &&
        error.response!.statusCode! < 500) {
      return;
    }
    if (_backoffAttempt >= 4) return;
    _retryTimer?.cancel();
    final delay = Duration(seconds: 1 << _backoffAttempt);
    _backoffAttempt += 1;
    _retryTimer = Timer(delay, () {
      if (_canRegister) unawaited(sync());
    });
  }

  /// Best-effort `DELETE /notifications/devices` before auth invalidation.
  ///
  /// Failures never trap the user in a logged-in session. Call
  /// [onLogoutAborted] if session logout fails after this runs so registration
  /// can resume. The next authenticated [registerDevice] must re-associate the
  /// token; that ownership transfer is a backend contract (live-verify).
  Future<void> unregisterBestEffort() async {
    _logoutInProgress = true;
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    final pending = _registerInFlight;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    final token = PushNotifications.fcmToken?.trim();
    final repository = _repository;
    final current = _isCurrentAccount;
    _confirmedToken = null;
    _confirmedUserId = null;
    _confirmedRevision = null;
    _registerInFlight = null;
    _registerInFlightKey = null;
    if (token == null ||
        token.isEmpty ||
        repository == null ||
        current == null ||
        !current()) {
      return;
    }
    try {
      await repository.unregisterDevice(fcmToken: token);
    } catch (error, stack) {
      debugPrint('PushDeviceSync.unregister skipped: $error\n$stack');
    }
  }

  /// Clears the logout registration guard when logout aborts after
  /// [unregisterBestEffort] (user remains authenticated).
  void onLogoutAborted() {
    _logoutInProgress = false;
    if (_canRegister) unawaited(sync());
  }

  bool get _canRegister {
    final current = _isCurrentAccount;
    return !_logoutInProgress &&
        !kIsWeb &&
        PushNotifications.remotePushSupported &&
        _repository != null &&
        _userId != null &&
        _accountRevision != null &&
        current != null &&
        current();
  }

  /// Test-only platform override for registration body.
  @visibleForTesting
  static String? debugPlatform;

  static String get _platform {
    final override = debugPlatform;
    if (override != null) return override;
    if (Platform.isIOS) return NotificationDevicePlatform.ios;
    if (Platform.isAndroid) return NotificationDevicePlatform.android;
    return NotificationDevicePlatform.web;
  }

  /// Test-only reset between cases.
  @visibleForTesting
  void debugReset() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _tokenSub?.cancel();
    _tokenSub = null;
    _repository = null;
    _isCurrentAccount = null;
    _userId = null;
    _accountRevision = null;
    _confirmedToken = null;
    _confirmedUserId = null;
    _confirmedRevision = null;
    _registerInFlight = null;
    _registerInFlightKey = null;
    _backoffAttempt = 0;
    _generation = 0;
    _logoutInProgress = false;
  }
}
