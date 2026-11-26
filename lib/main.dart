import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:hywork/app/app.dart';
import 'package:hywork/core/notifications/push_notifications.dart';
import 'package:hywork/core/responsiveness/responsive_config/config.dart';
import 'package:hywork/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Required by Firebase before runApp; never blocks UI.
  PushNotifications.bindBackgroundHandler();

  runApp(const ResponsiveConfig(child: MyApp()));

  // After first frame path is open: push setup cannot freeze splash/white screen.
  unawaited(PushNotifications.initialize());
}
