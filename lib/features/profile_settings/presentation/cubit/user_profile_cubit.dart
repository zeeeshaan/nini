import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_edit_strings.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

import '../../domain/user_profile.dart';
import '../../domain/user_profile_repository.dart';
import 'user_profile_state.dart';

export 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this.repository, {String userId = ''})
    : super(UserProfileState(profile: UserProfile(id: userId)));

  final UserProfileRepository repository;
  Future<void>? _loading;
  Future<bool>? _saving;
  bool _loaded = false, _closing = false;

  PostSeller get seller => state.profile.seller;

  Future<void> load() {
    if (_closing || isClosed || state.saving) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    emit(UserProfileState(profile: state.profile));
    try {
      final profile = await repository.load();
      if (_closing || isClosed) return;
      _loaded = true;
      emit(UserProfileState(profile: profile, loading: false));
    } catch (_) {
      if (_closing || isClosed) return;
      _loaded = false;
      emit(
        UserProfileState(
          profile: state.profile,
          loading: false,
          loadFailed: true,
        ),
      );
    }
  }

  Future<bool> save(UserProfile profile, {Uint8List? photo}) {
    if (_closing || isClosed) return Future.value(false);
    return _saving ??= _save(profile, photo).whenComplete(() => _saving = null);
  }

  Future<bool> _save(UserProfile profile, Uint8List? photo) async {
    if (_loading != null) {
      await _loading;
    } else if (!_loaded) {
      await load();
    }
    if (_closing || isClosed || !_loaded) return false;
    final previous = state.profile;
    emit(UserProfileState(profile: previous, loading: false, saving: true));
    try {
      final saved = await repository.save(profile, photo: photo);
      if (_closing || isClosed) return false;
      emit(UserProfileState(profile: saved, loading: false));
      return true;
    } catch (error) {
      if (_closing || isClosed) return false;
      final confirmed = error is UserProfileException
          ? error.confirmedProfile
          : null;
      emit(
        UserProfileState(
          profile: confirmed != null && confirmed.id == previous.id
              ? confirmed
              : previous,
          loading: false,
          saveFailed: true,
          errorMessage: _saveError(error),
          photoUploadUnavailable:
              error is UserProfileException && error.photoUploadUnavailable,
        ),
      );
      return false;
    }
  }

  String _saveError(Object error) {
    if (error is UserProfileException) return error.message;
    if (error is TimeoutException) return ProfileEditStrings.timeout;
    if (error is! DioException) return ProfileEditStrings.saveFailed;
    switch (error.response?.statusCode) {
      case 400:
        return _validationError(error);
      case 401:
        return ProfileEditStrings.sessionExpired;
      case 409:
        return ProfileEditStrings.usernameTaken;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ProfileEditStrings.timeout;
      case DioExceptionType.connectionError:
        return ProfileEditStrings.connectionFailed;
      default:
        return ProfileEditStrings.saveFailed;
    }
  }

  String _validationError(DioException error) {
    final body = error.response?.data;
    final errors = body is Map ? body['errors'] : null;
    if (errors is! List) return ProfileEditStrings.invalidFields;
    final fields = <String>{};
    for (final item in errors.whereType<Map>()) {
      final path = item['path'];
      String? key;
      if (path is String) {
        key = path.split('.').last;
      } else if (path is List && path.isNotEmpty && path.last is String) {
        key = path.last as String;
      }
      final label = key == null ? null : ProfileEditStrings.fieldLabel(key);
      if (label != null) fields.add(label);
    }
    return fields.isEmpty
        ? ProfileEditStrings.invalidFields
        : ProfileEditStrings.validationFields(fields);
  }

  @override
  Future<void> close() async {
    _closing = true;
    await _loading;
    await _saving;
    await super.close();
  }
}
