import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryAttachment {
  const GalleryAttachment.fromAsset(AssetEntity value)
    : asset = value,
      file = null,
      preparedFile = null,
      remoteUrl = null,
      _remoteId = null;

  const GalleryAttachment.fromFile(PlatformFile value)
    : asset = null,
      file = value,
      preparedFile = null,
      remoteUrl = null,
      _remoteId = null;

  /// Existing post media shown on the create-style edit screen.
  const GalleryAttachment.fromRemote({
    required String url,
    required String id,
  }) : asset = null,
       file = null,
       preparedFile = null,
       remoteUrl = url,
       _remoteId = id;

  const GalleryAttachment._(
    this.asset,
    this.file,
    this.preparedFile, [
    this.remoteUrl,
    this._remoteId,
  ]);

  final AssetEntity? asset;
  final PlatformFile? file;
  final PlatformFile? preparedFile;
  final String? remoteUrl;
  final String? _remoteId;

  GalleryAttachment withPreparedFile(PlatformFile value) =>
      GalleryAttachment._(asset, file, value, remoteUrl, _remoteId);

  String get id {
    if (remoteUrl != null) {
      return 'remote:${_remoteId ?? remoteUrl}';
    }
    if (asset != null) {
      return 'asset:${asset!.id}';
    }

    return 'file:${file!.path ?? file!.name}';
  }

  bool get isFile => file != null;
  bool get isRemote => remoteUrl != null;
}
