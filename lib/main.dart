import 'package:flutter/material.dart';

import 'package:nini/app/app.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ResponsiveConfig(child: MyApp()));
}