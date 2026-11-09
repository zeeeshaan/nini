import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:nini/shared/models/local_identity.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';

class LocalUserProfileRepository implements UserProfileRepository {
  LocalUserProfileRepository({
    Future<Directory> Function()? directoryProvider,
    this.profileId = localProfileId,
  }) : _directoryProvider = directoryProvider ?? _documents;

  final Future<Directory> Function() _directoryProvider;
  final String profileId;
  Future<void> _pending = Future.value();

  static Future<Directory> _documents() async => Platform.isIOS
      ? Directory(p.join(Directory.systemTemp.parent.path, 'Documents'))
      : getApplicationDocumentsDirectory();

  Future<Directory> _folder() async {
    final documents = await _directoryProvider();
    return Directory(
      p.join(documents.path, 'nini_profile', Uri.encodeComponent(profileId)),
    ).create(recursive: true);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<UserProfile> _read(Directory folder) async {
    final index = File(p.join(folder.path, 'profile.json'));
    if (!await index.exists()) return const UserProfile();
    final data = jsonDecode(await index.readAsString()) as Map<String, dynamic>;
    if (data['version'] != 1 || data['profileId'] != profileId) {
      throw const FormatException('Unsupported local profile');
    }
    return UserProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map),
    );
  }

  @override
  Future<UserProfile> load() => _serialize(() async => _read(await _folder()));

  Future<void> _discard(String path, Directory folder) async {
    if (!p.isWithin(folder.path, path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cleanup must not turn an already committed profile into a failed save.
    }
  }

  @override
  Future<UserProfile> save(
    UserProfile profile, {
    Uint8List? photo,
  }) => _serialize(() async {
    final folder = await _folder();
    final previous = await _read(folder);
    final index = File(p.join(folder.path, 'profile.json'));
    final temporary = File('${index.path}.tmp');
    var saved = profile.withAvatar(previous.avatarPath);
    String? newPhoto;
    var committed = false;
    try {
      if (photo != null) {
        if (photo.isEmpty) throw const FormatException('Empty profile photo');
        final extension =
            photo.length > 3 && photo[0] == 0x89 && photo[1] == 0x50
            ? 'png'
            : 'jpg';
        newPhoto = p.join(
          folder.path,
          'avatar_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}.$extension',
        );
        await File(newPhoto).writeAsBytes(photo, flush: true);
        saved = saved.withAvatar(newPhoto);
      }
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'profileId': profileId,
          'profile': saved.toJson(),
        }),
        flush: true,
      );
      await temporary.rename(index.path);
      committed = true;
      if (previous.avatarPath != saved.avatarPath) {
        await _discard(previous.avatarPath, folder);
      }
      return saved;
    } finally {
      if (!committed && newPhoto != null) await _discard(newPhoto, folder);
      await _discard(temporary.path, folder);
    }
  });
}
