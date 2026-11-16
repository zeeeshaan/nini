import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repo.dart';

enum SessionStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
  failure,
}

class SessionState {
  const SessionState(this.status, {this.userId});

  final SessionStatus status;
  final String? userId;
}

/// One startup check shared by phone and email authentication.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository)
    : super(const SessionState(SessionStatus.initial));

  final AuthRepository _repository;
  Future<void>? _pending;

  Future<void> restore() {
    if (isClosed || state.status == SessionStatus.authenticated) {
      return Future.value();
    }
    if (state.status == SessionStatus.checking) {
      return _pending ?? Future.value();
    }
    return _pending = _restore().whenComplete(() => _pending = null);
  }

  Future<void> _restore() async {
    emit(const SessionState(SessionStatus.checking));
    try {
      final userId = await _repository.restoreSession();
      if (isClosed) return;
      emit(
        userId == null
            ? const SessionState(SessionStatus.unauthenticated)
            : SessionState(SessionStatus.authenticated, userId: userId),
      );
    } catch (_) {
      if (!isClosed) emit(const SessionState(SessionStatus.failure));
    }
  }
}
