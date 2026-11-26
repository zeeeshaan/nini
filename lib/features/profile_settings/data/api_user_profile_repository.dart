import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hywork/core/localization/strings/profile_edit_strings.dart';
import 'package:hywork/core/media/media_compressor/media_compressor.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';

import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import '../domain/profile_limits.dart';

class ApiUserProfileRepository implements UserProfileRepository {
  ApiUserProfileRepository(
    this._apiClient,
    this._tokenStore, {
    required this.userId,
    required this.onUnauthorized,
  });

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;
  final String userId;
  final Future<void> Function() onUnauthorized;
  UserProfile? _profile;

  Future<T> _request<T>(Future<T> Function(String token) send) async {
    if (userId.isEmpty) {
      throw const UserProfileException(ProfileEditStrings.sessionExpired);
    }
    final token = (await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    if (token == null || token.isEmpty) {
      await onUnauthorized();
      throw const UserProfileException(ProfileEditStrings.sessionExpired);
    }
    if (token.contains(RegExp(r'[\r\n]'))) {
      throw const UserProfileException(ProfileEditStrings.sessionExpired);
    }
    try {
      return await send(token);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) await onUnauthorized();
      rethrow;
    }
  }

  Map<String, dynamic> _user(Map<String, dynamic> response) {
    final data = response['data'];
    final user = data is Map ? data['user'] ?? data : null;
    if (response['success'] != true ||
        user is! Map<String, dynamic> ||
        userId.isEmpty ||
        user['id'] != userId) {
      throw const FormatException('Profile response was not confirmed.');
    }
    return user;
  }

  UserProfile _parse(Map<String, dynamic> user, {UserProfile? previous}) {
    String text(String key, [String fallback = '']) {
      if (!user.containsKey(key)) return fallback;
      final value = user[key];
      if (value == null) return '';
      if (value is String) return value;
      throw const FormatException('Invalid profile field.');
    }

    final name = text('name', previous?.displayName ?? '').trim();
    final separator = name.indexOf(' ');
    final birth = text('birthDate', _date(previous?.birthDate) ?? '');
    final date = _parseDate(birth);
    final avatar = text('avatarUrl', previous?.avatarPath ?? '');
    final avatarUri = Uri.tryParse(avatar);
    if (avatar.isNotEmpty &&
        (avatarUri == null ||
            avatarUri.host.isEmpty ||
            !const ['http', 'https'].contains(avatarUri.scheme))) {
      throw const FormatException('Invalid backend avatar URL.');
    }
    return UserProfile(
      id: userId,
      firstName: separator < 0 ? name : name.substring(0, separator),
      lastName: separator < 0 ? '' : name.substring(separator + 1).trim(),
      username: text('username', previous?.username ?? ''),
      email: text('email', previous?.email ?? ''),
      nationality: text('nationality', previous?.nationality ?? ''),
      businessType: text('businessType', previous?.businessType ?? ''),
      bio: text('bio', previous?.bio ?? ''),
      city: text('city', previous?.city ?? ''),
      gender: text('gender', previous?.gender ?? ''),
      birthDate: date,
      avatarPath: avatar,
    );
  }

  @override
  Future<UserProfile> load() async {
    final response = await _request(
      (token) => _apiClient.get('auth/me', token: token),
    );
    return _profile = _parse(_user(response), previous: _profile);
  }

  String? _date(DateTime? value) {
    if (value == null) return null;
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    final validPrefix = RegExp(r'^\d{4}-\d{2}-\d{2}(?:$|[T ])').hasMatch(value);
    if (!validPrefix || DateTime.tryParse(value) == null) {
      throw const FormatException('Invalid profile date.');
    }
    final year = int.parse(value.substring(0, 4));
    final month = int.parse(value.substring(5, 7));
    final day = int.parse(value.substring(8, 10));
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw const FormatException('Invalid profile date.');
    }
    return date;
  }

  Map<String, Object?> _editableFields(UserProfile profile) => {
    'name': profile.displayName,
    'username': profile.username.trim(),
    'email': profile.email.trim(),
    'nationality': profile.nationality.trim(),
    'businessType': profile.businessType.trim(),
    'bio': profile.bio.trim(),
    'city': profile.city.trim(),
    'birthDate': _date(profile.birthDate),
    'gender': profile.gender.trim(),
    'avatarUrl': profile.avatarPath.trim(),
  };

  bool _needsPhotoUpload(UserProfile profile, UserProfile previous) {
    final avatar = profile.avatarPath.trim();
    final uri = Uri.tryParse(avatar);
    return avatar != previous.avatarPath.trim() &&
        avatar.isNotEmpty &&
        (uri == null ||
            uri.host.isEmpty ||
            !const ['http', 'https'].contains(uri.scheme));
  }

  void _validateChanges(UserProfile profile, Map<String, dynamic> changes) {
    final name = profile.displayName;
    final username = profile.username.trim();
    final bio = profile.bio.trim();
    final gender = profile.gender.trim();
    if (changes.containsKey('name') &&
        name.length > ProfileLimits.profileName) {
      throw const UserProfileException(ProfileEditStrings.invalidName);
    }
    if (changes.containsKey('username') &&
        !RegExp(r'^[a-z0-9_.]{3,30}$').hasMatch(username)) {
      throw const UserProfileException(ProfileEditStrings.invalidUsername);
    }
    if (changes.containsKey('bio') && bio.length > ProfileLimits.bio) {
      throw const UserProfileException(ProfileEditStrings.invalidBio);
    }
    if (changes.containsKey('gender') &&
        gender.isNotEmpty &&
        !const ['male', 'female', 'other'].contains(gender)) {
      throw const UserProfileException(ProfileEditStrings.invalidGender);
    }
    if (changes.containsKey('city') &&
        profile.city.trim().length > ProfileLimits.city) {
      throw const UserProfileException(ProfileEditStrings.invalidCity);
    }
    final businessType = profile.businessType.trim();
    if (changes.containsKey('businessType') &&
        businessType.isNotEmpty &&
        (businessType.length < 2 ||
            businessType.length > ProfileLimits.businessType)) {
      throw const UserProfileException(ProfileEditStrings.invalidBusinessType);
    }
  }

  String _photoFormat(Uint8List bytes) {
    bool startsWith(List<int> signature) =>
        bytes.length >= signature.length &&
        signature.asMap().entries.every(
          (entry) => bytes[entry.key] == entry.value,
        );
    if (startsWith([0xff, 0xd8, 0xff])) return 'jpeg';
    if (startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
      return 'png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'webp';
    }
    throw const UserProfileException(ProfileEditStrings.invalidPhoto);
  }

  Future<String> _uploadPhoto(Uint8List photo, String token) async {
    if (photo.isEmpty) {
      throw const UserProfileException(ProfileEditStrings.invalidPhoto);
    }
    final bytes = await MediaCompressor().compressProfilePhoto(photo);
    if (bytes.length > ProfileLimits.photoBytes) {
      throw const UserProfileException(ProfileEditStrings.photoTooLarge);
    }
    final format = _photoFormat(bytes);
    final Map<String, dynamic> response;
    try {
      response = await _apiClient.postMultipart(
        'uploads?purpose=avatar',
        token: token,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: 'avatar.$format',
            contentType: DioMediaType('image', format),
          ),
        }),
      );
    } on DioException catch (error) {
      switch (error.response?.statusCode) {
        case 404:
          throw const UserProfileException(
            ProfileEditStrings.photoUploadUnavailable,
            photoUploadUnavailable: true,
          );
        case 400:
          throw const UserProfileException(
            ProfileEditStrings.photoUploadFailed,
          );
        case 413:
          throw const UserProfileException(ProfileEditStrings.photoTooLarge);
        case 415:
          throw const UserProfileException(ProfileEditStrings.invalidPhoto);
        case 429:
          throw const UserProfileException(
            ProfileEditStrings.photoUploadLimited,
          );
        default:
          rethrow;
      }
    } on FormatException {
      throw const UserProfileException(ProfileEditStrings.photoUploadFailed);
    }
    final data = response['data'];
    final url = data is Map ? data['url'] : null;
    final uri = url is String ? Uri.tryParse(url) : null;
    if (response['success'] != true ||
        uri == null ||
        uri.host.isEmpty ||
        !const ['http', 'https'].contains(uri.scheme) ||
        (data is Map &&
            data.containsKey('purpose') &&
            data['purpose'] != 'avatar')) {
      throw const UserProfileException(ProfileEditStrings.photoUploadFailed);
    }
    return url as String;
  }

  Set<String> _unconfirmedFields(
    Map<String, dynamic> evidence,
    UserProfile profile,
    Map<String, dynamic> changes,
  ) {
    final values = _editableFields(profile);
    return changes.keys
        .where(
          (key) => !evidence.containsKey(key) || values[key] != changes[key],
        )
        .toSet();
  }

  UserProfileException _unconfirmedSave(
    Map<String, dynamic> evidence,
    Map<String, dynamic> changes,
    Set<String> unconfirmed, {
    required UserProfile previous,
    bool verificationFailed = false,
  }) {
    final confirmed = changes.keys
        .where((key) => !unconfirmed.contains(key))
        .toList();
    final confirmedEvidence = Map<String, dynamic>.of(evidence)
      ..removeWhere((key, _) => unconfirmed.contains(key));
    final confirmedProfile = _parse(confirmedEvidence, previous: previous);
    _profile = confirmedProfile;
    return UserProfileException(
      ProfileEditStrings.fieldsNotConfirmed(
        unconfirmed.map(ProfileEditStrings.fieldLabel).whereType<String>(),
        confirmed: confirmed
            .map(ProfileEditStrings.fieldLabel)
            .whereType<String>(),
        verificationFailed: verificationFailed,
      ),
      confirmedProfile: confirmed.isEmpty ? null : confirmedProfile,
    );
  }

  Future<UserProfile> _confirmedProfile(
    Map<String, dynamic> response,
    Map<String, dynamic> changes,
    UserProfile previous,
    String token,
  ) async {
    if (response['success'] != true) {
      throw const FormatException('Profile update was not confirmed.');
    }
    final data = response['data'];
    final candidate = data is Map ? data['user'] ?? data : null;
    var evidence = <String, dynamic>{};
    var saved = previous;
    if (candidate is Map && candidate.containsKey('id')) {
      evidence = _user(response);
      saved = _parse(evidence, previous: previous);
    }
    var unconfirmed = _unconfirmedFields(evidence, saved, changes);
    final verifyByReadBack = {
      'avatarUrl',
      'birthDate',
      'businessType',
    }.intersection(changes.keys.toSet());
    unconfirmed.addAll(verifyByReadBack);
    if (unconfirmed.isNotEmpty) {
      try {
        final refreshed = _user(await _apiClient.get('auth/me', token: token));
        evidence = {...evidence, ...refreshed};
        for (final key in verifyByReadBack) {
          if (!refreshed.containsKey(key)) evidence.remove(key);
        }
        saved = _parse(evidence, previous: previous);
        unconfirmed = _unconfirmedFields(evidence, saved, changes);
      } on DioException catch (error) {
        if (error.response?.statusCode == 401 ||
            error.type == DioExceptionType.badCertificate) {
          rethrow;
        }
        throw _unconfirmedSave(
          evidence,
          changes,
          unconfirmed,
          previous: previous,
          verificationFailed: true,
        );
      } on TimeoutException {
        throw _unconfirmedSave(
          evidence,
          changes,
          unconfirmed,
          previous: previous,
          verificationFailed: true,
        );
      } on FormatException {
        throw _unconfirmedSave(
          evidence,
          changes,
          unconfirmed,
          previous: previous,
          verificationFailed: true,
        );
      }
    }
    if (unconfirmed.isNotEmpty) {
      throw _unconfirmedSave(
        evidence,
        changes,
        unconfirmed,
        previous: previous,
      );
    }
    return _profile = saved;
  }

  @override
  Future<UserProfile> save(UserProfile profile, {Uint8List? photo}) async {
    final previous = _profile;
    if (previous == null || profile.id != userId) {
      throw const UserProfileException(ProfileEditStrings.saveFailed);
    }
    if (photo == null && _needsPhotoUpload(profile, previous)) {
      throw const UserProfileException(ProfileEditStrings.invalidPhoto);
    }
    final original = _editableFields(previous);
    final changes = <String, dynamic>{
      for (final field in _editableFields(profile).entries)
        if (field.value != original[field.key]) field.key: field.value,
    };
    if (changes.isEmpty && photo == null) return previous;
    _validateChanges(profile, changes);
    return _request((token) async {
      if (photo != null) {
        changes['avatarUrl'] = await _uploadPhoto(photo, token);
      }
      final response = await _apiClient.patch(
        'users/me',
        data: changes,
        token: token,
      );
      return _confirmedProfile(response, changes, previous, token);
    });
  }
}
