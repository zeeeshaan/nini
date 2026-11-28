import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';

/// Owns app-lifecycle and session hooks for [RealtimeSocketClient].
///
/// No feature UI — Phase B infrastructure only.
class RealtimeSocketBinder extends StatefulWidget {
  const RealtimeSocketBinder({super.key, required this.child});

  final Widget child;

  @override
  State<RealtimeSocketBinder> createState() => _RealtimeSocketBinderState();
}

class _RealtimeSocketBinderState extends State<RealtimeSocketBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final client = _client;
    if (client == null) return;
    if (state == AppLifecycleState.resumed) {
      client.setAppForeground(true);
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      client.setAppForeground(false);
    }
  }

  RealtimeSocketClient? get _client {
    try {
      return context.read<RealtimeSocketClient>();
    } catch (_) {
      return null;
    }
  }

  void _sync() {
    if (!mounted) return;
    final session = context.read<SessionCubit>().state;
    final client = _client;
    if (client == null) return;
    if (session.status == SessionStatus.authenticated &&
        !session.isLoggingOut &&
        !session.logoutCleanupRequired) {
      unawaited(client.connect());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) =>
              current.status == SessionStatus.authenticated &&
              !current.isLoggingOut &&
              (previous.status != SessionStatus.authenticated ||
                  previous.userId != current.userId),
          listener: (context, _) {
            final client = _client;
            if (client != null) unawaited(client.connect());
          },
        ),
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) =>
              current.isLoggingOut && !previous.isLoggingOut,
          listener: (context, _) {
            final client = _client;
            if (client != null) unawaited(client.disconnect());
          },
        ),
      ],
      child: widget.child,
    );
  }
}
