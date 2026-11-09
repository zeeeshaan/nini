import 'dart:io';

import 'package:flutter/widgets.dart';

/// Local profile photos use durable files; bundled seller images remain assets.
ImageProvider? profileImageProvider(String? path) {
  final value = path?.trim() ?? '';
  if (value.isEmpty) return null;
  return value.startsWith('assets/')
      ? AssetImage(value)
      : FileImage(File(value));
}
