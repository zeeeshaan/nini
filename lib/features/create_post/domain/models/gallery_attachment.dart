import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryAttachment {
  const GalleryAttachment.fromAsset(AssetEntity value)
    : asset = value,
      file = null,
      preparedFile = null;

  const GalleryAttachment.fromFile(PlatformFile value)
    : asset = null,
      file = value,
      preparedFile = null;

  const GalleryAttachment._(this.asset, this.file, this.preparedFile);

  final AssetEntity? asset;
  final PlatformFile? file;
  final PlatformFile? preparedFile;

  GalleryAttachment withPreparedFile(PlatformFile value) =>
      GalleryAttachment._(asset, file, value);

  String get id {
    if (asset != null) {
      return 'asset:${asset!.id}';
    }

    return 'file:${file!.path ?? file!.name}';
  }

  bool get isFile => file != null;
}
