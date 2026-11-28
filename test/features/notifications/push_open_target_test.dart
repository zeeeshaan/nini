import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/features/notifications/presentation/helpers/push_open_target.dart';

void main() {
  const chatId = '11111111-1111-4111-8111-111111111111';
  const postId = '22222222-2222-4222-8222-222222222222';
  const notificationId = '33333333-3333-4333-8333-333333333333';

  test('parses chat FCM data preferring conversationId', () {
    final target = PushOpenTarget.fromData({
      'type': 'chat.message',
      'targetType': 'chat',
      'targetId': chatId,
      'conversationId': chatId,
      'messageId': '44444444-4444-4444-8444-444444444444',
      'notificationId': notificationId,
    });
    expect(target.chatId, chatId);
    expect(target.postId, isNull);
    expect(target.notificationId, notificationId);
    expect(target.hasDestination, isTrue);
  });

  test('parses post FCM data from targetType/targetId', () {
    final target = PushOpenTarget.fromData({
      'type': 'post.approved',
      'targetType': 'post',
      'targetId': postId,
      'notificationId': notificationId,
    });
    expect(target.postId, postId);
    expect(target.chatId, isNull);
    expect(target.hasDestination, isTrue);
  });

  test('round-trips local notification payload JSON', () {
    final original = PushOpenTarget.fromData({
      'targetType': 'chat',
      'targetId': chatId,
      'conversationId': chatId,
      'notificationId': notificationId,
    });
    final restored = PushOpenTarget.fromPayload(original.toPayload());
    expect(restored.chatId, chatId);
    expect(restored.notificationId, notificationId);
  });

  test('ignores malformed local payloads without inventing destinations', () {
    expect(PushOpenTarget.fromPayload('not-json').hasDestination, isFalse);
    expect(PushOpenTarget.fromPayload(null).hasDestination, isFalse);
  });

  test('infers user destination from type when targetType is omitted', () {
    final target = PushOpenTarget.fromData({
      'type': 'user.followed',
      'targetId': postId,
    });
    expect(target.userId, postId);
    expect(target.hasDestination, isTrue);
  });

  test('infers order destination from type', () {
    final target = PushOpenTarget.fromData({
      'type': 'order.shipped',
      'targetType': 'order',
      'targetId': postId,
    });
    expect(target.isOrder, isTrue);
    expect(target.hasDestination, isTrue);
  });
}
