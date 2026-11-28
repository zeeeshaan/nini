import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hywork/features/create_post/models/gallery_attachment.dart';

class DeviceChatCamera {
  Future<GalleryAttachment?> takePhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return photo == null
        ? null
        : GalleryAttachment.fromFile(CameraPhotoFile(photo));
  }
}

/// Bridges a camera capture to the gallery's existing streaming file pipeline.
final class CameraPhotoFile extends PlatformFile {
  CameraPhotoFile(this.xFile);
  @override
  final XFile xFile;
  @override
  String get name => xFile.name;
  @override
  Uri get uri => Uri.file(xFile.path);
  @override
  int? lengthSync() => null;
  @override
  Future<int?> length() => xFile.length();
  @override
  Future<Uint8List> readAsBytes() => xFile.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() async* {
    await for (final chunk in xFile.openRead()) {
      yield Uint8List.fromList(chunk);
    }
  }
}
