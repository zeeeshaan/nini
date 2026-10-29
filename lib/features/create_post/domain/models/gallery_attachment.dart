import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryAttachment {
  const GalleryAttachment.fromAsset(AssetEntity value)
    : asset = value,
      file = null;

  const GalleryAttachment.fromFile(PlatformFile value)
    : asset = null,
      file = value;

  final AssetEntity? asset;
  final PlatformFile? file;

  String get id {
    if (asset != null) {
      return 'asset:${asset!.id}';
    }

    return 'file:${file!.path ?? file!.name}';
  }

  bool get isFile => file != null;
}
