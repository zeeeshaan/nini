import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Optimizes supported documents while retaining their original file format.
class DocumentCompressor {
  static const _channel = MethodChannel('hywork/document_compression');
  Future<void> compress(File source, File target) async {
    final extension = p.extension(source.path).toLowerCase();
    if (extension == '.pdf') {
      await _channel.invokeMethod<bool>('compressPdf', {
        'source': source.path,
        'target': target.path,
      });
    } else if (const {'.docx', '.xlsx', '.pptx'}.contains(extension)) {
      await Isolate.run(() => _office(source.path, target.path));
    }
  }

  static void _office(String source, String target) {
    final input = InputFileStream(source);
    Archive? original;
    try {
      original = ZipDecoder().decodeStream(input);
      // Inspect declared lengths before inflating any entries.
      if (original.isEmpty || original.length > 4096) return;
      var total = 0;
      for (final entry in original) {
        total += entry.size;
        if (entry.size < 0 || total > 128 * 1024 * 1024) return;
        if (entry.isSymbolicLink ||
            entry.name.toLowerCase().contains('_xmlsignatures/')) {
          return;
        }
      }
      if (!original.any((entry) => entry.name == '[Content_Types].xml')) {
        return;
      }
      final optimized = Archive();
      try {
        for (final entry in original) {
          // A fresh entry forces re-deflation instead of copying compressed data.
          final copy = ArchiveFile.bytes(entry.name, entry.content)
            ..isFile = entry.isFile
            ..mode = entry.mode
            ..lastModTime = entry.lastModTime
            ..compression = CompressionType.deflate;
          optimized.add(copy);
        }
        final output = OutputFileStream(target);
        try {
          ZipEncoder().encodeStream(optimized, output, level: 9);
        } finally {
          output.closeSync();
        }
        // The package contents must remain byte-for-byte identical.
        final verified = ZipDecoder().decodeBytes(
          File(target).readAsBytesSync(),
          verify: true,
        );
        try {
          if (verified.length != optimized.length) {
            throw const FormatException('Office entries changed');
          }
          for (var index = 0; index < verified.length; index++) {
            final expected = optimized[index];
            final actual = verified[index];
            if (expected.name != actual.name ||
                expected.size != actual.size ||
                getCrc32(expected.content) != getCrc32(actual.content)) {
              throw const FormatException('Office contents changed');
            }
          }
        } finally {
          verified.clearSync();
        }
      } finally {
        optimized.clearSync();
      }
    } finally {
      original?.clearSync();
      input.closeSync();
    }
  }
}
