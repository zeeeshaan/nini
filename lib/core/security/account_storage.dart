import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Namespaces existing repositories by the server-validated user ID, never a token.
class AccountStorage {
  const AccountStorage(this.userId);

  final String userId;

  Future<Directory> directory() async {
    if (userId.isEmpty) {
      throw StateError('An authenticated account is required.');
    }
    final documents = Platform.isIOS
        ? Directory(p.join(Directory.systemTemp.parent.path, 'Documents'))
        : await getApplicationDocumentsDirectory();
    final key = base64Url.encode(utf8.encode(userId)).replaceAll('=', '');
    return Directory(p.join(documents.path, 'nini_accounts', 'account_$key'))
        .create(recursive: true);
  }
}
