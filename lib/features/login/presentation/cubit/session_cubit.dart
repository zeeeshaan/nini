import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/features/notifications/data/push_device_sync.dart';

import '../../data/auth_repo.dart';

enum SessionStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
  failure,
}

class SessionState {
  const SessionState(
    this.status, {
    this.userId,
    this.isLoggingOut = false,
    this.logoutError,
    this.logoutCleanupRequired = false,
    this.accountRevision = 0,
  });

  final SessionStatus status;
  final String? userId;
  final bool isLoggingOut;
  final String? logoutError;
  final bool logoutCleanupRequired;
  final int accountRevision;
}

/// One startup check shared by phone and email authentication.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository)
    : super(const SessionState(SessionStatus.initial));

  final AuthRepository _repository;
  Future<void>? _pending;
  Future<void>? _logoutPending;

  Future<void> restore() {
    if (_logoutPending != null) return _logoutPending!;
    if (state.logoutCleanupRequired) return Future.value();
    if (isClosed || state.status == SessionStatus.authenticated) {
      return Future.value();
    }
    if (state.status == SessionStatus.checking) {
      return _pending ?? Future.value();
    }
    return _pending = _restore().whenComplete(() => _pending = null);
  }

  Future<void> logout() {
    if (isClosed) return Future.value();
    return _logoutPending ??= _logout().whenComplete(
      () => _logoutPending = null,
    );
  }

  Future<void> _logout() async {
    // Serialize startup validation and logout so a late /auth/me result cannot
    // save a replacement credential or reopen Dashboard after logout.
    await _pending;
    if (isClosed) return;
    final previous = state;

    // Remove this device association while isCurrentAccount is still true.
    // Failures never block logout; the next register upserts the token.
    await PushDeviceSync.instance.unregisterBestEffort();
    if (isClosed) return;

    emit(
      SessionState(
        previous.status,
        userId: previous.userId,
        isLoggingOut: true,
        logoutCleanupRequired: previous.logoutCleanupRequired,
        accountRevision: previous.accountRevision,
      ),
    );
    try {
      await _repository.logout();
      if (isClosed) return;
      PushDeviceSync.instance.detach(accountRevision: previous.accountRevision);
      emit(
        SessionState(
          SessionStatus.unauthenticated,
          accountRevision: previous.accountRevision + 1,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      // Unregister may have already cleared the device; resume push sync while
      // the session remains authenticated.
      PushDeviceSync.instance.onLogoutAborted();
      final cleanupRequired = error is LogoutCleanupException;
      emit(
        SessionState(
          previous.status,
          userId: previous.userId,
          logoutCleanupRequired: cleanupRequired,
          logoutError: _logoutError(error),
          accountRevision: previous.accountRevision,
        ),
      );
    }
  }

  String _logoutError(Object error) {
    if (error is LogoutCleanupException) {
      return ProfileSettingsStrings.logoutCleanupFailed;
    }
    if (error is TimeoutException) {
      return ProfileSettingsStrings.logoutTimeout;
    }
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ProfileSettingsStrings.logoutTimeout;
        case DioExceptionType.connectionError:
          return ProfileSettingsStrings.logoutConnectionFailed;
        default:
          return ProfileSettingsStrings.logoutServerFailed;
      }
    }
    return ProfileSettingsStrings.logoutFailed;
  }

  Future<void> _restore() async {
    final revision = state.accountRevision;
    emit(SessionState(SessionStatus.checking, accountRevision: revision));
    try {
      final userId = await _repository.restoreSession();
      if (isClosed) return;
      if (userId == null) {
        emit(
          SessionState(
            SessionStatus.unauthenticated,
            accountRevision: revision,
          ),
        );
        return;
      }
      // Bump revision when entering an authenticated account so account-scoped
      // providers/cubits are recreated with this userId. Otherwise cubits built
      // during splash (userId == null) keep an isCurrentAccount closure that
      // never matches after login, and notifications/chat badges never load.
      emit(
        SessionState(
          SessionStatus.authenticated,
          userId: userId,
          accountRevision: revision + 1,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(SessionState(SessionStatus.failure, accountRevision: revision));
      }
    }
  }
}
