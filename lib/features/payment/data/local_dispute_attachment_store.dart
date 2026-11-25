import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nini/features/payment/domain/models/dispute_attachment.dart';
import 'package:nini/core/media/media_compressor/media_compressor.dart';

/// Owns copies of selected evidence, never the user's picker originals.
class LocalDisputeAttachmentStore {
  Future<Directory> _root() async {
    final documents = Platform.isIOS
        ? Directory(p.join(Directory.systemTemp.parent.path, 'Documents'))
        : await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, 'nini_dispute_attachments'))
        .create(recursive: true);
  }

  Future<DisputeAttachment> copy({
    required String path,
    required String name,
    required bool isImage,
  }) async {
    final root = await _root();
    final safeName = p.basename(name).replaceAll(RegExp(r'[^\w. -]'), '_');
    var target = p.join(
      root.path,
      '${DateTime.now().microsecondsSinceEpoch}-$safeName',
    );
    try {
      await File(path).copy(target);
      final optimized = await MediaCompressor().compressOwnedFile(File(target));
      target = optimized.path;
      return DisputeAttachment(
        path: target,
        name: p.extension(target) == p.extension(path)
            ? name
            : p.setExtension(name, p.extension(target)),
        isImage: isImage,
      );
    } catch (_) {
      final file = File(target);
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<void> discard(Iterable<DisputeAttachment> attachments) async {
    final String root;
    try {
      root = p.normalize(p.absolute((await _root()).path));
    } catch (_) {
      return;
    }
    for (final attachment in attachments) {
      final path = p.normalize(p.absolute(attachment.path));
      if (!p.isWithin(root, path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Abandoned copies can be cleaned later; never remove picker sources.
      }
    }
  }
}
