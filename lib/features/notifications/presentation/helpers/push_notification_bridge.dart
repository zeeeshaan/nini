import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/notifications/push_notifications.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:hywork/features/notifications/presentation/helpers/open_notification_target.dart';
import 'package:hywork/features/notifications/presentation/helpers/open_notifications.dart';
import 'package:hywork/features/notifications/presentation/helpers/push_open_target.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Wires authenticated FCM foreground refresh and tap handling.
///
/// Swagger 0.20.0 documents FCM `data`: `type`, `targetType`, `targetId`,
/// `notificationId`, and for chat `conversationId` / `messageId`. Taps open
/// that destination when possible; otherwise the notifications inbox.
class PushNotificationBridge extends StatefulWidget {
  const PushNotificationBridge({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<PushNotificationBridge> createState() => _PushNotificationBridgeState();
}

class _PushNotificationBridgeState extends State<PushNotificationBridge>
    with WidgetsBindingObserver {
  Timer? _refreshDebounce;
  bool _opening = false;
  String? _lastHandledOpenKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PushNotifications.onForegroundMessage = _onForeground;
    PushNotifications.onNotificationOpened = _onOpened;
    PushNotifications.onLocalPayloadOpened = _onLocalPayload;
    PushNotifications.flushPendingOpens();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshDebounce?.cancel();
    if (identical(PushNotifications.onForegroundMessage, _onForeground)) {
      PushNotifications.onForegroundMessage = null;
    }
    if (identical(PushNotifications.onNotificationOpened, _onOpened)) {
      PushNotifications.onNotificationOpened = null;
    }
    if (identical(PushNotifications.onLocalPayloadOpened, _onLocalPayload)) {
      PushNotifications.onLocalPayloadOpened = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background FCM delivery does not hit onMessage; refresh badges on resume.
    if (state == AppLifecycleState.resumed) _scheduleRefresh();
  }

  void _onForeground(RemoteMessage message) {
    if (!mounted) return;
    if (!_isAuthenticated) return;
    _scheduleRefresh();
  }

  bool get _isAuthenticated {
    final session = context.read<SessionCubit>().state;
    return session.status == SessionStatus.authenticated &&
        !session.isLoggingOut &&
        !session.logoutCleanupRequired;
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || !_isAuthenticated) return;

      try {
        final notifications = context.read<NotificationsCubit>();
        unawaited(notifications.refreshUnreadCount());
        unawaited(notifications.refresh());
      } catch (_) {}

      try {
        unawaited(context.read<ChatUnreadCubit>().refresh());
      } catch (_) {}

      final refreshConversation = PushNotifications.refreshActiveConversation;
      if (refreshConversation != null) unawaited(refreshConversation());
    });
  }

  void _onOpened(RemoteMessage message) {
    final target = PushOpenTarget.fromData(message.data);
    final key = message.messageId?.trim().isNotEmpty == true
        ? message.messageId!.trim()
        : target.toPayload();
    unawaited(_openAfterAuth(target, dedupeKey: key));
  }

  void _onLocalPayload(String payload) {
    final target = PushOpenTarget.fromPayload(payload);
    unawaited(_openAfterAuth(target, dedupeKey: payload));
  }

  Future<void> _openAfterAuth(
    PushOpenTarget target, {
    required String dedupeKey,
  }) async {
    if (dedupeKey.isNotEmpty && dedupeKey == _lastHandledOpenKey) return;
    if (_opening) return;
    _opening = true;
    _lastHandledOpenKey = dedupeKey;
    try {
      for (var i = 0; i < 40; i++) {
        if (!mounted) return;
        final session = context.read<SessionCubit>().state;
        if (session.status == SessionStatus.authenticated &&
            !session.isLoggingOut &&
            !session.logoutCleanupRequired) {
          break;
        }
        if (session.status == SessionStatus.unauthenticated ||
            session.status == SessionStatus.failure) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!mounted || !_isAuthenticated) return;

      final navContext = widget.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;

      _scheduleRefresh();

      final notificationId = target.notificationId?.trim();
      if (notificationId != null &&
          notificationId.isNotEmpty &&
          ProfileCategory.isBackendId(notificationId)) {
        try {
          unawaited(
            navContext.read<NotificationsCubit>().markReadFromPush(
              notificationId,
            ),
          );
        } catch (_) {}
      }

      final opened = await openPushOpenTarget(navContext, target);
      if (!navContext.mounted) return;
      if (!opened) {
        openNotifications(navContext);
      }
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
