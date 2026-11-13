import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// A private, prepared copy with the same streaming API as picker files.
final class PreparedGalleryFile extends PlatformFile {
  PreparedGalleryFile(
    this._file, {
    required this.name,
    required this.sizeBytes,
  });

  final File _file;
  final int sizeBytes;
  @override
  final String name;
  @override
  Uri get uri => _file.uri;
  @override
  XFile get xFile => XFile(_file.path, name: name);
  @override
  int lengthSync() => sizeBytes;
  @override
  Future<int> length() => _file.length();
  @override
  Future<Uint8List> readAsBytes() => _file.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() async* {
    await for (final chunk in _file.openRead()) {
      yield Uint8List.fromList(chunk);
    }
  }
}
