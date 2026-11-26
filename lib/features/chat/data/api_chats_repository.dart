import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/features/profile_settings/domain/profile_limits.dart';
import 'package:path/path.dart' as p;

/// Authenticated Chat REST client (Swagger Chat, v0.18.0).
///
/// No WebSockets here — Cubits own Phase 3 REST polling / focus refresh.
/// Image uploads reuse `ApiClient.postMultipart` with `purpose=chat`.
class ApiChatsRepository {
  ApiChatsRepository(
    this._apiClient,
    this._tokenStore, {
    required this.isCurrentAccount,
    required this.onUnauthorized,
  });

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;
  final bool Function() isCurrentAccount;
  final Future<void> Function() onUnauthorized;

  final Set<String> _sendInFlight = {};
  final Set<String> _openInFlight = {};
  final Set<String> _deleteInFlight = {};
  final Set<String> _readInFlight = {};

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

  void _requireChatId(String id) {
    if (!ProfileCategory.isBackendId(id)) {
      throw const FormatException('Invalid chat ID.');
    }
  }

  /// `GET /chats` — newest first; optional name/username search [q].
  Future<BackendChatsPage> list({
    int page = 1,
    int limit = 20,
    String? q,
  }) async {
    if (page < 1 || limit < 1 || limit > 50) {
      throw const FormatException('Invalid chats page filter.');
    }
    final query = q?.trim();
    final path = Uri(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (query != null && query.isNotEmpty) 'q': query,
      },
    ).query;
    final response = await _request(
      (token) => _apiClient.get('chats?$path', token: token),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid chats page response.');
    }
    return BackendChatsPage.fromJson(data);
  }

  /// `POST /chats` — open/create the single chat for [userId].
  Future<BackendChatDetail> openChat(String userId) async {
    if (!ProfileCategory.isBackendId(userId)) {
      throw const FormatException('Invalid user ID.');
    }
    if (!_openInFlight.add(userId)) {
      throw const FormatException('A chat is already being opened.');
    }
    try {
      final response = await _request(
        (token) =>
            _apiClient.post('chats', token: token, data: {'userId': userId}),
      );
      final data = response['data'];
      if (response['success'] != true || data is! Map<String, dynamic>) {
        throw const FormatException('Chat open was not confirmed.');
      }
      return BackendChatDetail.fromJson(data);
    } finally {
      _openInFlight.remove(userId);
    }
  }

  /// `GET /chats/unread-count` — never fabricates zeros on failure.
  Future<BackendChatUnreadCount> unreadCount() async {
    final response = await _request(
      (token) => _apiClient.get('chats/unread-count', token: token),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid chat unread-count response.');
    }
    return BackendChatUnreadCount.fromJson(data);
  }

  /// `GET /chats/{id}`.
  Future<BackendChatDetail> getChat(String chatId) async {
    _requireChatId(chatId);
    final response = await _request(
      (token) =>
          _apiClient.get('chats/${Uri.encodeComponent(chatId)}', token: token),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid chat detail response.');
    }
    final detail = BackendChatDetail.fromJson(data);
    if (detail.id != chatId) {
      throw const FormatException('Invalid chat detail response.');
    }
    return detail;
  }

  /// `GET /chats/{id}/messages` — newest first; page older with [before].
  Future<BackendChatMessagesPage> listMessages(
    String chatId, {
    String? before,
    int limit = 30,
  }) async {
    _requireChatId(chatId);
    if (limit < 1 || limit > 100) {
      throw const FormatException('Invalid messages page filter.');
    }
    if (before != null &&
        before.isNotEmpty &&
        !ProfileCategory.isBackendId(before)) {
      throw const FormatException('Invalid messages page filter.');
    }
    final query = Uri(
      queryParameters: {
        'limit': '$limit',
        if (before != null && before.isNotEmpty) 'before': before,
      },
    ).query;
    final response = await _request(
      (token) => _apiClient.get(
        'chats/${Uri.encodeComponent(chatId)}/messages?$query',
        token: token,
      ),
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid chat messages response.');
    }
    final page = BackendChatMessagesPage.fromJson(data);
    for (final message in page.items) {
      if (message.conversationId != chatId) {
        throw const FormatException('Invalid chat messages response.');
      }
    }
    return page;
  }

  /// `POST /chats/{id}/messages` — text and/or imageUrl; no auto-retry.
  Future<BackendChatMessage> sendMessage(
    String chatId, {
    String? text,
    String? imageUrl,
  }) async {
    _requireChatId(chatId);
    final trimmed = text?.trim();
    final image = imageUrl?.trim();
    if ((trimmed == null || trimmed.isEmpty) &&
        (image == null || image.isEmpty)) {
      throw const FormatException('A message text or imageUrl is required.');
    }
    if (trimmed != null && trimmed.runes.length > 2000) {
      throw const FormatException('Message text is too long.');
    }
    if (image != null && image.isNotEmpty) {
      final uri = Uri.tryParse(image);
      if (uri == null ||
          uri.host.isEmpty ||
          !const ['http', 'https'].contains(uri.scheme)) {
        throw const FormatException('Invalid chat image URL.');
      }
    }

    final key = '$chatId|${trimmed ?? ''}|${image ?? ''}';
    if (!_sendInFlight.add(key)) {
      throw const FormatException('A message is already being sent.');
    }
    try {
      final response = await _request(
        (token) => _apiClient.post(
          'chats/${Uri.encodeComponent(chatId)}/messages',
          token: token,
          data: {
            if (trimmed != null && trimmed.isNotEmpty) 'text': trimmed,
            if (image != null && image.isNotEmpty) 'imageUrl': image,
          },
        ),
      );
      final data = response['data'];
      if (response['success'] != true || data is! Map<String, dynamic>) {
        throw const FormatException('Message send was not confirmed.');
      }
      final message = BackendChatMessage.fromJson(data);
      if (message.conversationId != chatId) {
        throw const FormatException('Message send was not confirmed.');
      }
      return message;
    } finally {
      _sendInFlight.remove(key);
    }
  }

  /// Upload a chat photo via existing multipart client (`purpose=chat`).
  Future<BackendChatUpload> uploadChatImage(File file) async {
    if (!await file.exists()) {
      throw const FormatException('Chat photo file is missing.');
    }
    final length = await file.length();
    if (length <= 0 || length > ProfileLimits.photoBytes) {
      throw const FormatException('Chat photo exceeds the 5 MB limit.');
    }
    final name = p.basename(file.path);
    final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) {
      throw const FormatException('Only JPG, PNG or WebP photos are allowed.');
    }
    final format = ext == 'jpg' ? 'jpeg' : ext;

    final response = await _request((token) async {
      final multipart = await MultipartFile.fromFile(
        file.path,
        filename: name,
        contentType: DioMediaType('image', format),
      );
      return _apiClient.postMultipart(
        'uploads?purpose=chat',
        token: token,
        data: FormData.fromMap({'file': multipart}),
      );
    });
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Chat photo upload was not confirmed.');
    }
    return BackendChatUpload.fromJson(data);
  }

  /// Upload then send an image message. Upload success alone is not delivery.
  Future<BackendChatMessage> sendImageMessage(
    String chatId,
    File file, {
    String? text,
  }) async {
    final upload = await uploadChatImage(file);
    return sendMessage(chatId, text: text, imageUrl: upload.url);
  }

  /// `POST /chats/{id}/read`.
  Future<MarkChatReadResult> markRead(String chatId) async {
    _requireChatId(chatId);
    if (!_readInFlight.add(chatId)) {
      throw const FormatException('Chat is already being marked read.');
    }
    try {
      final response = await _request(
        (token) => _apiClient.post(
          'chats/${Uri.encodeComponent(chatId)}/read',
          token: token,
        ),
      );
      final data = response['data'];
      if (response['success'] != true || data is! Map<String, dynamic>) {
        throw const FormatException('Mark chat read was not confirmed.');
      }
      return MarkChatReadResult.fromJson(data);
    } finally {
      _readInFlight.remove(chatId);
    }
  }

  /// `DELETE /chats/{id}/messages/{messageId}` — soft-delete own message.
  Future<void> deleteMessage(String chatId, String messageId) async {
    _requireChatId(chatId);
    if (!ProfileCategory.isBackendId(messageId)) {
      throw const FormatException('Invalid message ID.');
    }
    final key = '$chatId|$messageId';
    if (!_deleteInFlight.add(key)) {
      throw const FormatException('Message deletion is already in progress.');
    }
    try {
      final response = await _request(
        (token) => _apiClient.delete(
          'chats/${Uri.encodeComponent(chatId)}/messages/${Uri.encodeComponent(messageId)}',
          token: token,
        ),
      );
      if (response['success'] != true) {
        throw const FormatException('Message deletion was not confirmed.');
      }
    } finally {
      _deleteInFlight.remove(key);
    }
  }
}
