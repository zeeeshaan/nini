import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoCubit extends Cubit<Uint8List?> {
  ProfilePhotoCubit({Future<XFile?> Function()? imagePicker})
    : _imagePicker = imagePicker ?? _pickImage,
      super(null);
  final Future<XFile?> Function() _imagePicker;
  static Future<XFile?> _pickImage() => ImagePicker().pickImage(
    source: ImageSource.gallery,
    requestFullMetadata: false,
  );
  bool _picking = false;
  Future<bool> pick({
    required Future<Uint8List?> Function(String path) cropPhoto,
  }) async {
    if (_picking) return true;
    _picking = true;
    try {
      final file = await _imagePicker();
      if (isClosed || file == null) return true;
      final bytes = await cropPhoto(file.path);
      if (bytes != null && bytes.isEmpty) {
        throw const FormatException('Empty cropped photo');
      }
      if (!isClosed && bytes != null) emit(bytes);
      return true;
    } catch (_) {
      return false;
    } finally {
      _picking = false;
    }
  }
}
