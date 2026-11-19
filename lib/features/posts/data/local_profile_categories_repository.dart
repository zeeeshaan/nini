import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/validation/profile_category_validator.dart';

/// Versioned local adapter. Writes replace the index atomically and are
/// serialized so rapid mutations cannot overwrite each other.
class LocalProfileCategoriesRepository implements ProfileCategoriesRepository {
  LocalProfileCategoriesRepository({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? _documents;
  final Future<Directory> Function() _directoryProvider;
  Future<void> _pending = Future.value();

  static Future<Directory> _documents() async => Platform.isIOS
      ? Directory(p.join(Directory.systemTemp.parent.path, 'Documents'))
      : getApplicationDocumentsDirectory();

  static const _initial = [
    ProfileCategory(id: 'web-development', name: 'Web Development'),
    ProfileCategory(id: 'electrical-wiring', name: 'Electrical Wiring'),
    ProfileCategory(id: 'products', name: 'Products'),
    ProfileCategory(id: 'photography', name: 'Photography'),
  ];

  Future<File> _index() async {
    final documents = await _directoryProvider();
    final folder = await Directory(
      p.join(documents.path, 'nini_profile_categories'),
    ).create(recursive: true);
    return File(p.join(folder.path, 'categories.json'));
  }

  Future<List<ProfileCategory>> _read() async {
    final index = await _index();
    if (!await index.exists()) return List.of(_initial);
    final data = jsonDecode(await index.readAsString()) as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw const FormatException('Unsupported category storage version');
    }
    return (data['categories'] as List)
        .map(
          (value) =>
              ProfileCategory.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
  }

  Future<void> _write(List<ProfileCategory> categories) async {
    final index = await _index();
    final temporary = File('${index.path}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'categories': categories.map((item) => item.toJson()).toList(),
        }),
        flush: true,
      );
      await temporary.rename(index.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<ProfileCategoryList> load() async {
    await _pending;
    return ProfileCategoryList(items: List.unmodifiable(await _read()));
  }

  @override
  Future<ProfileCategory> create(String name) => _serialize(() async {
    final categories = await _read();
    final error = ProfileCategoryValidator.validateName(name, categories);
    if (error != null) throw ProfileCategoryException(error);
    final category = ProfileCategory(
      id: 'category_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      name: name.trim(),
    );
    await _write([...categories, category]);
    return category;
  });

  @override
  Future<ProfileCategory> rename(String id, String name) =>
      _serialize(() async {
        final categories = await _read();
        if (!categories.any((item) => item.id == id)) {
          throw const ProfileCategoryException(ProfilePostStrings.loadFailed);
        }
        final error = ProfileCategoryValidator.validateName(
          name,
          categories,
          excludingId: id,
        );
        if (error != null) throw ProfileCategoryException(error);
        final category = ProfileCategory(id: id, name: name.trim());
        await _write([
          for (final item in categories)
            if (item.id == id) category else item,
        ]);
        return category;
      });

  @override
  Future<int?> delete(String id) => _serialize(() async {
    final categories = await _read();
    await _write(categories.where((item) => item.id != id).toList());
    return null;
  });

  @override
  Future<ProfileCategoryList> reorder(List<String> ids) async =>
      throw const ProfileCategoryException(
        ProfilePostStrings.categoryLegacyUnavailable,
      );
}
