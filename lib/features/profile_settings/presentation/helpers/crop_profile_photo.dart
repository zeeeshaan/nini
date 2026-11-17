import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/profile_edit_strings.dart';
import 'package:path/path.dart' as p;

Future<Uint8List?> cropProfilePhoto(BuildContext context, String path) async {
  final colors = Theme.of(context).colorScheme;
  final light = Theme.of(context).brightness == Brightness.light;
  final transparent = const {
    '.png',
    '.webp',
  }.contains(p.extension(path).toLowerCase());
  final cropped = await ImageCropper().cropImage(
    sourcePath: path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    maxWidth: 1024,
    maxHeight: 1024,
    // Keep crop quality until the upload contract defines compression needs.
    compressQuality: 100,
    compressFormat: transparent
        ? ImageCompressFormat.png
        : ImageCompressFormat.jpg,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: ProfileEditStrings.cropPhoto,
        toolbarColor: colors.surface,
        toolbarWidgetColor: colors.onSurface,
        backgroundColor: colors.surface,
        activeControlsWidgetColor: colors.onSurface,
        statusBarLight: light,
        navBarLight: light,
        lockAspectRatio: true,
        cropStyle: CropStyle.circle,
      ),
      IOSUiSettings(
        title: ProfileEditStrings.cropPhoto,
        doneButtonTitle: AppStrings.done,
        cancelButtonTitle: AppStrings.cancel,
        aspectRatioLockEnabled: true,
        aspectRatioPickerButtonHidden: true,
        resetAspectRatioEnabled: false,
        cropStyle: CropStyle.circle,
      ),
    ],
  );
  if (cropped == null) return null;
  final file = File(cropped.path);
  try {
    return await file.readAsBytes();
  } finally {
    if (await file.exists()) await file.delete();
  }
}
