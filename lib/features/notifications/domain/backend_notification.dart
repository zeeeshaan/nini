import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Swagger `Notification.target.type` values.
abstract final class NotificationTargetType {
  static const post = 'post';
  static const order = 'order';
  static const chat = 'chat';
  static const user = 'user';
  static const known = {post, order, chat, user};
}

/// Navigation destination on a backend notification. Separate from record [id].
class NotificationTarget {
  const NotificationTarget({required this.type, required this.id});

  final String type;
  final String id;

  bool get isKnownType => NotificationTargetType.known.contains(type);

  factory NotificationTarget.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final id = json['id'];
    if (type is! String ||
        type.trim().isEmpty ||
        id is! String ||
        id.trim().isEmpty) {
      throw const FormatException('Invalid notification target.');
    }
    return NotificationTarget(type: type, id: id);
  }
}

/// Swagger `Notification` record from `GET /notifications`.
class BackendNotification {
  const BackendNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.titleFa,
    required this.bodyFa,
    required this.isRead,
    required this.createdAt,
    this.target,
    this.data = const {},
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String titleFa;
  final String bodyFa;
  final NotificationTarget? target;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  factory BackendNotification.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final title = json['title'];
    final body = json['body'];
    final titleFa = json['titleFa'];
    final bodyFa = json['bodyFa'];
    final isRead = json['isRead'];
    final createdRaw = json['createdAt'];
    final readRaw = json['readAt'];
    final targetRaw = json['target'];
    final dataRaw = json['data'];

    if (id is! String ||
        !ProfileCategory.isBackendId(id) ||
        type is! String ||
        type.trim().isEmpty ||
        title is! String ||
        body is! String ||
        titleFa is! String ||
        bodyFa is! String ||
        isRead is! bool ||
        createdRaw is! String) {
      throw const FormatException('Invalid notification response.');
    }

    final createdAt = DateTime.tryParse(createdRaw);
    if (createdAt == null) {
      throw const FormatException('Invalid notification response.');
    }

    DateTime? readAt;
    if (readRaw != null) {
      if (readRaw is! String) {
        throw const FormatException('Invalid notification response.');
      }
      readAt = DateTime.tryParse(readRaw);
      if (readAt == null) {
        throw const FormatException('Invalid notification response.');
      }
    }

    NotificationTarget? target;
    if (targetRaw != null) {
      if (targetRaw is! Map<String, dynamic>) {
        throw const FormatException('Invalid notification target.');
      }
      target = NotificationTarget.fromJson(targetRaw);
    }

    final data = <String, dynamic>{};
    if (dataRaw != null) {
      if (dataRaw is! Map) {
        throw const FormatException('Invalid notification response.');
      }
      dataRaw.forEach((key, value) {
        if (key is! String) {
          throw const FormatException('Invalid notification response.');
        }
        data[key] = value;
      });
    }

    return BackendNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      titleFa: titleFa,
      bodyFa: bodyFa,
      target: target,
      data: Map.unmodifiable(data),
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt,
    );
  }
}

/// Paginated `GET /notifications` payload (includes optional `unreadCount`).
class BackendNotificationsPage {
  const BackendNotificationsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    this.unreadCount,
  });

  final List<BackendNotification> items;
  final int total;
  final int page;
  final int limit;
  final int? unreadCount;

  factory BackendNotificationsPage.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final total = json['total'];
    final page = json['page'];
    final limit = json['limit'];
    final unread = json['unreadCount'];

    if (itemsRaw is! List ||
        total is! int ||
        total < 0 ||
        page is! int ||
        page < 1 ||
        limit is! int ||
        limit < 1 ||
        limit > 50 ||
        (unread != null && unread is! int) ||
        (unread is int && unread < 0)) {
      throw const FormatException('Invalid notifications page response.');
    }

    final ids = <String>{};
    final items = <BackendNotification>[];
    for (final item in itemsRaw) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid notification response.');
      }
      final notification = BackendNotification.fromJson(item);
      if (!ids.add(notification.id)) {
        throw const FormatException('Duplicate notification ID.');
      }
      items.add(notification);
    }

    return BackendNotificationsPage(
      items: List.unmodifiable(items),
      total: total,
      page: page,
      limit: limit,
      unreadCount: unread as int?,
    );
  }
}

/// Confirmed `POST /notifications/read` result.
class MarkNotificationsReadResult {
  const MarkNotificationsReadResult({
    required this.updated,
    required this.unreadCount,
  });

  final int updated;
  final int unreadCount;

  factory MarkNotificationsReadResult.fromJson(Map<String, dynamic> json) {
    final updated = json['updated'];
    final unreadCount = json['unreadCount'];
    if (updated is! int ||
        updated < 0 ||
        unreadCount is! int ||
        unreadCount < 0) {
      throw const FormatException('Mark-as-read was not confirmed.');
    }
    return MarkNotificationsReadResult(
      updated: updated,
      unreadCount: unreadCount,
    );
  }
}

/// Swagger `platform` values for `POST /notifications/devices`.
abstract final class NotificationDevicePlatform {
  static const android = 'android';
  static const ios = 'ios';
  static const web = 'web';
  static const known = {android, ios, web};
}

/// Swagger `locale` values for `POST /notifications/devices`.
abstract final class NotificationDeviceLocale {
  static const fa = 'fa';
  static const en = 'en';
  static const known = {fa, en};
}

/// Confirmed `POST /notifications/devices` result.
class DeviceRegistrationResult {
  const DeviceRegistrationResult({
    required this.registered,
    required this.platform,
    required this.locale,
  });

  final bool registered;
  final String platform;
  final String locale;

  factory DeviceRegistrationResult.fromJson(Map<String, dynamic> json) {
    final registered = json['registered'];
    final platform = json['platform'];
    final locale = json['locale'];
    if (registered is! bool ||
        platform is! String ||
        !NotificationDevicePlatform.known.contains(platform) ||
        locale is! String ||
        !NotificationDeviceLocale.known.contains(locale)) {
      throw const FormatException('Device registration was not confirmed.');
    }
    return DeviceRegistrationResult(
      registered: registered,
      platform: platform,
      locale: locale,
    );
  }
}

/// Confirmed `DELETE /notifications/devices` result.
class DeviceRemovalResult {
  const DeviceRemovalResult({required this.removed});

  final int removed;

  factory DeviceRemovalResult.fromJson(Map<String, dynamic> json) {
    final removed = json['removed'];
    if (removed is! int || removed < 0) {
      throw const FormatException('Device removal was not confirmed.');
    }
    return DeviceRemovalResult(removed: removed);
  }
}
