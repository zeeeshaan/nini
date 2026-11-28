// dart format width=100
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/cart_snapshot.dart';
import 'cart_repository.dart';

class LocalCartRepository implements CartRepository {
  LocalCartRepository({Future<Directory> Function()? directoryProvider})
    : _directory = directoryProvider ?? _documents;
  final Future<Directory> Function() _directory;
  static Future<Directory> _documents() async => Platform.isIOS
      ? Directory(p.join(Directory.systemTemp.parent.path, 'Documents'))
      : getApplicationDocumentsDirectory();
  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File(p.join(directory.path, 'cart.json'));
  }

  @override
  Future<CartSnapshot?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return CartSnapshot.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
  }

  @override
  Future<void> save(CartSnapshot snapshot) async {
    final target = await _file();
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
    await temp.rename(target.path);
  }
}
