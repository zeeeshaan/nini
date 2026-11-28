import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';

/// Captures the authenticated account at creation time and validates that the
/// same user/revision is still active.
///
/// Pending chat requests and route callbacks must refuse to run against a
/// newly logged-in account after logout or account switch.
class ChatAccountScope {
  ChatAccountScope.capture(SessionCubit session)
    : _session = session,
      _userId = session.state.userId,
      _accountRevision = session.state.accountRevision;

  final SessionCubit _session;
  final String? _userId;
  final int _accountRevision;

  /// Whether [session] still matches the account captured at construction.
  bool isCurrent() {
    if (_session.isClosed) return false;
    final state = _session.state;
    return state.status == SessionStatus.authenticated &&
        !state.isLoggingOut &&
        !state.logoutCleanupRequired &&
        state.userId != null &&
        state.userId == _userId &&
        state.accountRevision == _accountRevision;
  }

  /// Current user id when [isCurrent] is true; otherwise `null`.
  String? currentUserId() => isCurrent() ? _session.state.userId : null;
}

/// Optional session binding for screens that also accept test overrides.
ChatAccountScope? captureChatAccountScope(SessionCubit? session) {
  if (session == null) return null;
  return ChatAccountScope.capture(session);
}
