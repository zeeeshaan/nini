import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Swagger `POST /reports` targetType enum.
abstract final class ReportTargetType {
  static const post = 'post';
  static const user = 'user';
  static const comment = 'comment';
  static const message = 'message';
  static const values = {post, user, comment, message};
}

/// Swagger `POST /reports` reason enum.
abstract final class ReportReason {
  static const spam = 'spam';
  static const abusive = 'abusive';
  static const inappropriateContent = 'inappropriate_content';
  static const fraud = 'fraud';
  static const prohibitedItem = 'prohibited_item';
  static const other = 'other';
  static const values = {
    spam,
    abusive,
    inappropriateContent,
    fraud,
    prohibitedItem,
    other,
  };
}

class ReportReceipt {
  const ReportReceipt({
    required this.id,
    required this.status,
    required this.createdAt,
  });
  final String id;
  final String status;
  final DateTime createdAt;
}

/// Backend-only reporting client. No UI callers in Phase 1.
class ApiReportsRepository {
  ApiReportsRepository(
    this._apiClient,
    this._tokenStore, {
    required this.isCurrentAccount,
  });

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;
  final bool Function() isCurrentAccount;
  final Set<String> _inFlight = {};

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
      throw const FormatException('An authenticated session is required.');
    }
    return token;
  }

  /// `POST /reports` — returns the server receipt; never fabricates success.
  Future<ReportReceipt> submit({
    required String targetType,
    required String targetId,
    required String reason,
    String? note,
  }) async {
    if (!ReportTargetType.values.contains(targetType)) {
      throw const FormatException('Unsupported report target type.');
    }
    if (!ProfileCategory.isBackendId(targetId)) {
      throw const FormatException('A backend target UUID is required.');
    }
    if (!ReportReason.values.contains(reason)) {
      throw const FormatException('Unsupported report reason.');
    }
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.runes.length > 1000) {
      throw const FormatException('Report note is too long.');
    }

    final key = '$targetType:$targetId';
    if (!_inFlight.add(key)) {
      throw const FormatException('A report is already being submitted.');
    }
    try {
      final token = await _token();
      final response = await _apiClient.post(
        'reports',
        token: token,
        data: {
          'targetType': targetType,
          'targetId': targetId,
          'reason': reason,
          if (trimmedNote != null && trimmedNote.isNotEmpty)
            'note': trimmedNote,
        },
      );
      if (!isCurrentAccount()) {
        throw const FormatException('The account changed.');
      }
      final data = response['data'];
      if (response['success'] != true || data is! Map<String, dynamic>) {
        throw const FormatException('Report was not confirmed.');
      }
      final id = data['id'];
      final status = data['status'];
      final createdAt = data['createdAt'];
      if (id is! String ||
          !ProfileCategory.isBackendId(id) ||
          status is! String ||
          status.trim().isEmpty ||
          createdAt is! String) {
        throw const FormatException('Report was not confirmed.');
      }
      final at = DateTime.tryParse(createdAt);
      if (at == null) {
        throw const FormatException('Report was not confirmed.');
      }
      return ReportReceipt(id: id, status: status, createdAt: at);
    } finally {
      _inFlight.remove(key);
    }
  }
}
