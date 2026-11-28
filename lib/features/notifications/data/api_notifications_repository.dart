import 'package:dio/dio.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Authenticated notification REST client (Swagger Notifications).
///
/// Includes device registration (`POST`/`DELETE /notifications/devices`).
/// Account-scoped via [isCurrentAccount]; stale responses after logout /
/// switch are rejected.
class ApiNotificationsRepository {
  ApiNotificationsRepository(
    this._apiClient,
    this._tokenStore, {
    required this.isCurrentAccount,
    required this.onUnauthorized,
  });

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;
  final bool Function() isCurrentAccount;
  final Future<void> Function() onUnauthorized;

  Future<String> _token() async {
    if (!isCurrentAccount()) {
      throw const FormatException('An authenticated session is required.');
    }
    final token = (await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    if (!isCurrentAccount() ||
        token == null ||
        token.isEmpty ||
        token.contains(RegExp(r'[\r\n]'))) {
      if (isCurrentAccount()) await onUnauthorized();
      throw const FormatException('An authenticated session is required.');
    }
    return token;
  }

  Future<T> _request<T>(Future<T> Function(String token) send) async {
    if (!isCurrentAccount()) {
      throw const FormatException('An authenticated session is required.');
    }
    try {
      final token = await _token();
      final result = await send(token);
      if (!isCurrentAccount()) {
        throw const FormatException('The account changed.');
      }
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 && isCurrentAccount()) {
        await onUnauthorized();
      }
      rethrow;
    }
  }

  /// `GET /notifications` — newest first; optional page `unreadCount`.
  Future<BackendNotificationsPage> list({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    if (page < 1 || limit < 1 || limit > 50) {
      throw const FormatException('Invalid notifications page filter.');
    }
    final query = Uri(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (unreadOnly != null) 'unreadOnly': unreadOnly ? 'true' : 'false',
      },
    ).query;
    final response = await _request(
      (token) => _apiClient.get('notifications?$query', token: token),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid notifications page response.');
    }
    return BackendNotificationsPage.fromJson(data);
  }

  /// `GET /notifications/unread-count` — never fabricates zero on failure.
  Future<int> unreadCount() async {
    final response = await _request(
      (token) => _apiClient.get('notifications/unread-count', token: token),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid unread-count response.');
    }
    final count = data['count'];
    if (count is! int || count < 0) {
      throw const FormatException('Invalid unread-count response.');
    }
    return count;
  }

  /// `POST /notifications/read` — send [ids] and/or [markAll].
  Future<MarkNotificationsReadResult> markRead({
    List<String>? ids,
    bool markAll = false,
  }) async {
    if (markAll) {
      if (ids != null && ids.isNotEmpty) {
        throw const FormatException(
          'Provide either notification ids or markAll, not both.',
        );
      }
      return _markReadBody(const {'all': true});
    }

    if (ids == null || ids.isEmpty) {
      throw const FormatException(
        'Provide notification ids or markAll to mark as read.',
      );
    }
    if (ids.length > 100) {
      throw const FormatException('At most 100 notification ids are allowed.');
    }
    final unique = <String>{};
    for (final id in ids) {
      if (!ProfileCategory.isBackendId(id) || !unique.add(id)) {
        throw const FormatException('Invalid notification id.');
      }
    }
    return _markReadBody({'ids': List<String>.from(unique)});
  }

  Future<MarkNotificationsReadResult> _markReadBody(
    Map<String, dynamic> body,
  ) async {
    final response = await _request(
      (token) =>
          _apiClient.post('notifications/read', token: token, data: body),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Mark-as-read was not confirmed.');
    }
    return MarkNotificationsReadResult.fromJson(data);
  }

  /// `POST /notifications/devices` — traditional FCM registration token.
  Future<DeviceRegistrationResult> registerDevice({
    required String fcmToken,
    required String platform,
    String locale = NotificationDeviceLocale.fa,
  }) async {
    final token = fcmToken.trim();
    if (token.isEmpty || token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid FCM registration token.');
    }
    if (!NotificationDevicePlatform.known.contains(platform)) {
      throw const FormatException('Invalid notification device platform.');
    }
    if (!NotificationDeviceLocale.known.contains(locale)) {
      throw const FormatException('Invalid notification device locale.');
    }
    final response = await _request(
      (auth) => _apiClient.post(
        'notifications/devices',
        token: auth,
        data: {'token': token, 'platform': platform, 'locale': locale},
      ),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Device registration was not confirmed.');
    }
    return DeviceRegistrationResult.fromJson(data);
  }

  /// `DELETE /notifications/devices` — stop push for this FCM token.
  Future<DeviceRemovalResult> unregisterDevice({
    required String fcmToken,
  }) async {
    final token = fcmToken.trim();
    if (token.isEmpty || token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid FCM registration token.');
    }
    final response = await _request(
      (auth) => _apiClient.delete(
        'notifications/devices',
        token: auth,
        data: {'token': token},
      ),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Device removal was not confirmed.');
    }
    return DeviceRemovalResult.fromJson(data);
  }
}
