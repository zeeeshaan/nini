import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';

void main() {
  const sample = {
    'id': '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f',
    'type': 'post.approved',
    'title': 'Post approved',
    'body': '“iPhone 13” is now live.',
    'titleFa': 'آگهی تأیید شد',
    'bodyFa': '“iPhone 13” منتشر شد.',
    'target': {'type': 'post', 'id': '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99'},
    'data': {'sku': 'iphone-13'},
    'isRead': false,
    'readAt': null,
    'createdAt': '2026-11-20T09:00:00.000Z',
  };

  test('parses English and Persian content with a post target', () {
    final notification = BackendNotification.fromJson(
      Map<String, dynamic>.from(sample),
    );
    expect(notification.id, sample['id']);
    expect(notification.title, 'Post approved');
    expect(notification.bodyFa, '“iPhone 13” منتشر شد.');
    expect(notification.titleFa, 'آگهی تأیید شد');
    expect(notification.target?.type, NotificationTargetType.post);
    expect(notification.target?.id, '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99');
    expect(notification.target?.isKnownType, isTrue);
    expect(notification.data['sku'], 'iphone-13');
    expect(notification.isRead, isFalse);
    expect(notification.readAt, isNull);
  });

  test('keeps notification id separate from destination id', () {
    final notification = BackendNotification.fromJson(
      Map<String, dynamic>.from(sample),
    );
    expect(notification.id, isNot(notification.target!.id));
  });

  test('accepts a null target', () {
    final json = Map<String, dynamic>.from(sample)..['target'] = null;
    final notification = BackendNotification.fromJson(json);
    expect(notification.target, isNull);
  });

  test('accepts known navigation targets', () {
    for (final type in NotificationTargetType.known) {
      final json = Map<String, dynamic>.from(sample)
        ..['target'] = {
          'type': type,
          'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        };
      final notification = BackendNotification.fromJson(json);
      expect(notification.target!.type, type);
      expect(notification.target!.isKnownType, isTrue);
    }
  });

  test('preserves unknown target types without failing', () {
    final json = Map<String, dynamic>.from(sample)
      ..['target'] = {
        'type': 'warehouse',
        'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      };
    final notification = BackendNotification.fromJson(json);
    expect(notification.target!.type, 'warehouse');
    expect(notification.target!.isKnownType, isFalse);
  });

  test('parses an empty notifications page', () {
    final page = BackendNotificationsPage.fromJson({
      'items': <dynamic>[],
      'total': 0,
      'page': 1,
      'limit': 20,
      'unreadCount': 0,
    });
    expect(page.items, isEmpty);
    expect(page.total, 0);
    expect(page.unreadCount, 0);
  });

  test('rejects invalid notification envelopes', () {
    expect(
      () => BackendNotification.fromJson({...sample, 'id': 'not-a-uuid'}),
      throwsFormatException,
    );
    expect(
      () => BackendNotificationsPage.fromJson({
        'items': 'nope',
        'total': 0,
        'page': 1,
        'limit': 20,
      }),
      throwsFormatException,
    );
    expect(
      () => MarkNotificationsReadResult.fromJson({'updated': 1}),
      throwsFormatException,
    );
  });

  test('parses mark-as-read confirmation', () {
    final result = MarkNotificationsReadResult.fromJson({
      'updated': 2,
      'unreadCount': 1,
    });
    expect(result.updated, 2);
    expect(result.unreadCount, 1);
  });

  test('parses device registration and removal confirmations', () {
    final registered = DeviceRegistrationResult.fromJson({
      'registered': true,
      'platform': 'android',
      'locale': 'fa',
    });
    expect(registered.registered, isTrue);
    expect(registered.platform, NotificationDevicePlatform.android);
    expect(registered.locale, NotificationDeviceLocale.fa);

    expect(
      () => DeviceRegistrationResult.fromJson({
        'registered': true,
        'platform': 'desktop',
        'locale': 'fa',
      }),
      throwsFormatException,
    );

    final removed = DeviceRemovalResult.fromJson({'removed': 1});
    expect(removed.removed, 1);
    expect(
      () => DeviceRemovalResult.fromJson({'removed': -1}),
      throwsFormatException,
    );
  });
}
