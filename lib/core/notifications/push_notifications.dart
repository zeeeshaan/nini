import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Firebase Cloud Messaging bootstrap (traditional FCM registration token).
///
/// Swagger `POST /notifications/devices` requires `FirebaseMessaging.getToken()`.
/// Do not mix this with FID `register()` / `onRegistered`.
///
/// Designed so push setup can never block or crash app launch:
/// - [bindBackgroundHandler] is sync and cheap (call before [runApp])
/// - [initialize] never throws; call it without awaiting after [runApp]
/// - iOS remote push stays deferred until APNs / paid Apple team is ready
class PushNotifications {
  PushNotifications._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'hywork_default',
        'HYWORK',
        description: 'HYWORK alerts and messages',
        importance: Importance.high,
      );

  static bool _backgroundBound = false;
  static bool _initializing = false;
  static bool _ready = false;
  static String? _fcmToken;
  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<RemoteMessage>? _openedSub;
  static final StreamController<String> _tokenController =
      StreamController<String>.broadcast();
  static final List<RemoteMessage> _pendingOpens = [];
  static final Set<String> _recentMessageKeys = {};
  static void Function(RemoteMessage message)? onForegroundMessage;
  static void Function(RemoteMessage message)? onNotificationOpened;

  /// Local tray tap with JSON payload of documented FCM `data` fields.
  static void Function(String payload)? onLocalPayloadOpened;
  static String? activeConversationId;
  static Future<void> Function()? refreshActiveConversation;

  static bool get isReady => _ready;
  static String? get fcmToken => _fcmToken;
  static Stream<String> get onToken => _tokenController.stream;

  /// Remote device registration is production-ready on Android only for now.
  static bool get remotePushSupported =>
      debugRemotePushSupported ?? (!kIsWeb && Platform.isAndroid);

  /// Test-only override for [remotePushSupported].
  @visibleForTesting
  static bool? debugRemotePushSupported;

  /// Test-only FCM token injection (never logs the value).
  @visibleForTesting
  static void debugSetToken(String? token) {
    final value = token?.trim();
    if (value == null || value.isEmpty) {
      _fcmToken = null;
      return;
    }
    _setToken(value);
  }

  /// Must run before [runApp]. Safe to call more than once.
  static void bindBackgroundHandler() {
    if (kIsWeb || _backgroundBound) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _backgroundBound = true;
  }

  /// Configures permissions, local notifications, and FCM token listeners.
  /// Never throws. Safe to call without awaiting.
  static Future<void> initialize() async {
    if (kIsWeb || _ready || _initializing) return;
    _initializing = true;

    try {
      bindBackgroundHandler();
      await _setupLocalNotifications();

      if (!remotePushSupported) {
        // iOS: keep Firebase Core + local notifications; skip APNs/FCM token.
        _ready = true;
        return;
      }

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _ready = true;
        return;
      }

      // Swagger 0.20.0 POST /notifications/devices requires the traditional FCM
      // registration token from getToken(), not the FID from register().
      // ignore: deprecated_member_use
      _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(_setToken);
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null && token.trim().isNotEmpty) {
        _setToken(token.trim());
      }

      _foregroundSub ??= FirebaseMessaging.onMessage.listen(_onForeground);
      _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _onOpened(initial);

      _ready = true;
    } catch (error, stack) {
      debugPrint('PushNotifications.initialize failed: $error\n$stack');
    } finally {
      _initializing = false;
    }
  }

  static void _setToken(String token) {
    final value = token.trim();
    if (value.isEmpty || value == _fcmToken) return;
    _fcmToken = value;
    if (!_tokenController.isClosed) _tokenController.add(value);
  }

  /// Status-bar / small icon: white alpha silhouette (required by Android).
  static const _androidSmallIcon = '@drawable/ic_stat_hywork';

  /// Expanded notification app mark (full-color launcher is fine here).
  static const _androidLargeIcon = DrawableResourceAndroidBitmap(
    '@mipmap/ic_launcher',
  );

  static Future<void> _setupLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_androidSmallIcon),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
    );

    if (!Platform.isAndroid) return;
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_androidChannel);
    // Android 13+ blocks tray/local alerts until POST_NOTIFICATIONS is granted.
    await android?.requestNotificationsPermission();
  }

  static void _onLocalNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final handler = onLocalPayloadOpened;
    if (handler == null) return;
    try {
      handler(payload);
    } catch (error, stack) {
      debugPrint('PushNotifications.localTap handler failed: $error\n$stack');
    }
  }

  static Future<void> _onForeground(RemoteMessage message) async {
    if (!_rememberMessage(message)) return;

    final handler = onForegroundMessage;
    if (handler != null) {
      try {
        handler(message);
      } catch (error, stack) {
        debugPrint(
          'PushNotifications.foreground handler failed: $error\n$stack',
        );
      }
    }

    final notification = message.notification;
    if (notification == null) return;

    final active = activeConversationId?.trim();
    if (active != null &&
        active.isNotEmpty &&
        _looksLikeActiveConversation(message, active)) {
      return;
    }

    try {
      final title = notification.title?.trim();
      final body = notification.body?.trim();
      await _local.show(
        id: notification.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: _androidSmallIcon,
            largeIcon: _androidLargeIcon,
            color: const Color(0xFF111111),
            styleInformation: BigTextStyleInformation(
              body?.isNotEmpty == true ? body! : ' ',
              contentTitle: title,
              summaryText: 'HYWORK',
              htmlFormatBigText: false,
              htmlFormatContentTitle: false,
              htmlFormatSummaryText: false,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _localPayloadFor(message),
      );
    } catch (error, stack) {
      debugPrint('PushNotifications.show failed: $error\n$stack');
    }
  }

  static void _onOpened(RemoteMessage message) {
    final handler = onNotificationOpened;
    if (handler == null) {
      _pendingOpens.add(message);
      return;
    }
    try {
      handler(message);
    } catch (error, stack) {
      debugPrint('PushNotifications.open handler failed: $error\n$stack');
    }
  }

  /// Delivers any cold-start / early taps once a navigation handler is ready.
  static void flushPendingOpens() {
    final handler = onNotificationOpened;
    if (handler == null || _pendingOpens.isEmpty) return;
    final pending = List<RemoteMessage>.from(_pendingOpens);
    _pendingOpens.clear();
    for (final message in pending) {
      try {
        handler(message);
      } catch (error, stack) {
        debugPrint('PushNotifications.flush open failed: $error\n$stack');
      }
    }
  }

  /// Encodes documented FCM `data` so local tray taps can deep-link.
  static String _localPayloadFor(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      try {
        return jsonEncode(message.data);
      } catch (_) {}
    }
    return message.messageId?.trim() ?? '';
  }

  static bool _rememberMessage(RemoteMessage message) {
    final key = message.messageId?.trim();
    if (key == null || key.isEmpty) return true;
    if (_recentMessageKeys.contains(key)) return false;
    _recentMessageKeys.add(key);
    if (_recentMessageKeys.length > 64) {
      _recentMessageKeys.remove(_recentMessageKeys.first);
    }
    return true;
  }

  /// Only suppresses a local alert when the data map already contains the
  /// active conversation id as a value. Does not invent field names.
  static bool _looksLikeActiveConversation(
    RemoteMessage message,
    String activeId,
  ) {
    for (final value in message.data.values) {
      if (value.toString().trim() == activeId) return true;
    }
    return false;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep lightweight. Notification messages are displayed by the OS/FCM plugin.
  // Do not touch Cubits, BuildContext, or chat polling from this isolate.
}
