import 'package:dio/dio.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';

import '../domain/models/profile_category.dart';
import '../domain/profile_categories_repository.dart';
import '../domain/validation/profile_category_validator.dart';

class ApiProfileCategoriesRepository implements ProfileCategoriesRepository {
  ApiProfileCategoriesRepository(
    this._client,
    this._tokens, {
    required this.isCurrentAccount,
    required this.onUnauthorized,
  });
  final ApiClient _client;
  final SecureTokenStore _tokens;
  final bool Function() isCurrentAccount;
  final Future<void> Function() onUnauthorized;

  void _checkAccount() {
    if (!isCurrentAccount()) {
      throw const ProfileCategoryException(
        ProfilePostStrings.categoryAccountChanged,
        sessionExpired: true,
      );
    }
  }

  Future<Map<String, dynamic>> _request(
    Future<Map<String, dynamic>> Function(String token) send,
  ) async {
    _checkAccount();
    final token = (await _tokens.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    _checkAccount();
    if (token == null || token.isEmpty || token.contains(RegExp(r'[\r\n]'))) {
      await onUnauthorized();
      throw const ProfileCategoryException(
        ProfilePostStrings.categorySessionExpired,
        sessionExpired: true,
      );
    }
    try {
      final response = await send(token);
      _checkAccount();
      return response;
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      if (isCurrentAccount()) await onUnauthorized();
      throw const ProfileCategoryException(
        ProfilePostStrings.categorySessionExpired,
        sessionExpired: true,
      );
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile categories response.');
    }
    return data;
  }

  @override
  Future<ProfileCategoryList> load() async => ProfileCategoryList.fromApiJson(
    _data(
      await _request(
        (token) => _client.get('users/me/categories', token: token),
      ),
    ),
  );

  @override
  Future<ProfileCategory> create(String name) async {
    final error = ProfileCategoryValidator.validateName(name, const []);
    if (error != null) throw ProfileCategoryException(error);
    final category = ProfileCategory.fromApiJson(
      _data(
        await _request(
          (token) => _client.post(
            'users/me/categories',
            data: {'name': name.trim()},
            token: token,
          ),
        ),
      ),
    );
    if (category.name.trim().toLowerCase() != name.trim().toLowerCase()) {
      throw const FormatException('Created category was not confirmed.');
    }
    return category;
  }

  @override
  Future<ProfileCategory> rename(String id, String name) async {
    _validateId(id);
    final error = ProfileCategoryValidator.validateName(name, const []);
    if (error != null) throw ProfileCategoryException(error);
    final category = ProfileCategory.fromApiJson(
      _data(
        await _request(
          (token) => _client.patch(
            'users/me/categories/${Uri.encodeComponent(id)}',
            data: {'name': name.trim()},
            token: token,
          ),
        ),
      ),
    );
    if (category.id != id ||
        category.name.trim().toLowerCase() != name.trim().toLowerCase()) {
      throw const FormatException('Renamed category was not confirmed.');
    }
    return category;
  }

  @override
  Future<int?> delete(String id) async {
    _validateId(id);
    final data = _data(
      await _request(
        (token) => _client.delete(
          'users/me/categories/${Uri.encodeComponent(id)}',
          token: token,
        ),
      ),
    );
    final moved = data['postsMoved'];
    if (data['id'] != id ||
        data['deleted'] != true ||
        (moved != null && (moved is! int || moved < 0))) {
      throw const FormatException('Category deletion was not confirmed.');
    }
    return moved as int?;
  }

  @override
  Future<ProfileCategoryList> reorder(List<String> ids) async {
    if (ids.toSet().length != ids.length ||
        ids.any((id) => !ProfileCategory.isBackendId(id))) {
      throw const ProfileCategoryException(
        ProfilePostStrings.categoryOrderInvalid,
      );
    }
    final result = ProfileCategoryList.fromApiJson(
      _data(
        await _request(
          (token) => _client.put(
            'users/me/categories/order',
            data: {'ids': ids},
            token: token,
          ),
        ),
      ),
    );
    if (result.items.length != ids.length ||
        result.items.indexed.any((entry) => entry.$2.id != ids[entry.$1])) {
      throw const FormatException('Category order was not confirmed.');
    }
    return result;
  }

  void _validateId(String id) {
    if (!ProfileCategory.isBackendId(id)) {
      throw const ProfileCategoryException(
        ProfilePostStrings.categoryLegacyUnavailable,
      );
    }
  }
}
