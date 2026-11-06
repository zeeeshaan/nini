import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoCubit extends Cubit<Uint8List?> {
  ProfilePhotoCubit() : super(null);
  bool _picking = false;
  Future<bool> pick() async {
    if (_picking) return true;
    _picking = true;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );
      final bytes = await file?.readAsBytes();
      if (!isClosed && bytes != null) emit(bytes);
      return true;
    } catch (_) {
      return false;
    } finally {
      _picking = false;
    }
  }
}
