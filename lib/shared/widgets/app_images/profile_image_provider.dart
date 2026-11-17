import 'dart:io';

import 'package:flutter/widgets.dart';

/// Supports backend avatars, durable local photos and bundled seller images.
ImageProvider? profileImageProvider(String? path) {
  final value = path?.trim() ?? '';
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri != null &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'https' || uri.scheme == 'http')) {
    return NetworkImage(value);
  }
  return value.startsWith('assets/')
      ? AssetImage(value)
      : FileImage(File(value));
}
