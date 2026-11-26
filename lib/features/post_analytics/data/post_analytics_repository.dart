import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:hywork/features/post_analytics/domain/post_analytics.dart';

abstract class PostAnalyticsRepository {
  Future<List<PostAnalyticsEvent>> load();
  Future<void> save(List<PostAnalyticsEvent> events);
}

class LocalPostAnalyticsRepository implements PostAnalyticsRepository {
  LocalPostAnalyticsRepository({
    Future<Directory> Function()? directoryProvider,
  }) : _provider = directoryProvider ?? _documents;
  final Future<Directory> Function() _provider;
  static Future<Directory> _documents() async => Platform.isIOS
      ? Directory(p.join(Directory.systemTemp.parent.path, 'Documents'))
      : getApplicationDocumentsDirectory();
  Future<File> _file() async {
    final root = await _provider();
    await root.create(recursive: true);
    return File(p.join(root.path, 'post_analytics.json'));
  }

  @override
  Future<List<PostAnalyticsEvent>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unsupported analytics version');
    }
    return (json['events'] as List)
        .map(
          (event) => PostAnalyticsEvent.fromJson(
            Map<String, dynamic>.from(event as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(List<PostAnalyticsEvent> events) async {
    final target = await _file();
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(
      jsonEncode({
        'version': 1,
        'events': events.map((event) => event.toJson()).toList(),
      }),
      flush: true,
    );
    await temp.rename(target.path);
  }
}

/// Useful for previews and widget tests that have no native file storage.
class MemoryPostAnalyticsRepository implements PostAnalyticsRepository {
  List<PostAnalyticsEvent> events = [];
  @override
  Future<List<PostAnalyticsEvent>> load() async => List.of(events);
  @override
  Future<void> save(List<PostAnalyticsEvent> value) async {
    events = List.of(value);
  }
}
