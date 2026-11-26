import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Firebase Cloud Messaging bootstrap.
///
/// Designed so push setup can never block or crash app launch:
/// - [bindBackgroundHandler] is sync and cheap (call before [runApp])
/// - [initialize] never throws; call it without awaiting after [runApp]
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
  static String? _registrationId;

  static bool get isReady => _ready;
  static String? get registrationId => _registrationId;

  /// Must run before [runApp]. Safe to call more than once.
  static void bindBackgroundHandler() {
    if (kIsWeb || _backgroundBound) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _backgroundBound = true;
  }

  /// Configures permissions, local notifications, and FCM registration.
  /// Never throws. Safe to call without awaiting.
  static Future<void> initialize() async {
    if (kIsWeb || _ready || _initializing) return;
    _initializing = true;

    try {
      bindBackgroundHandler();
      await _setupLocalNotifications();
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
        return;
      }

      _messaging.onRegistered.listen((id) => _registrationId = id);
      await _registerSafely();
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _ready = true;
    } catch (error, stack) {
      debugPrint('PushNotifications.initialize failed: $error\n$stack');
    } finally {
      _initializing = false;
    }
  }

  static Future<void> _setupLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    if (!Platform.isAndroid) return;
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _registerSafely() async {
    try {
      await _messaging.register();
    } catch (error, stack) {
      // Common on iOS Simulator / missing APNs key in Firebase Console.
      debugPrint('PushNotifications.register skipped: $error\n$stack');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      await _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.isEmpty ? null : message.data.toString(),
      );
    } catch (error, stack) {
      debugPrint('PushNotifications.show failed: $error\n$stack');
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep lightweight; the OS / FCM plugin delivers the system notification.
}
