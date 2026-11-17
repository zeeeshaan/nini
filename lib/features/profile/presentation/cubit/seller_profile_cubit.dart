import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';

import '../../data/api_public_profile_repository.dart';
import '../../domain/public_user_profile.dart';

class SellerProfileState {
  const SellerProfileState({
    this.profile,
    this.loading = false,
    this.error,
    this.canRetry = true,
  });
  final PublicUserProfile? profile;
  final bool loading, canRetry;
  final String? error;
}

class SellerProfileCubit extends Cubit<SellerProfileState> {
  SellerProfileCubit(this._repository) : super(const SellerProfileState());
  final ApiPublicProfileRepository _repository;
  int _request = 0;
  String? _key;
  Future<void>? _pending;

  Future<void> load(String username, {String? expectedUserId}) {
    if (isClosed) return Future.value();
    final key =
        '${PublicUserProfile.normalizeUsername(username)}:$expectedUserId';
    if (state.loading && key == _key && _pending != null) return _pending!;
    _key = key;
    final request = ++_request;
    emit(const SellerProfileState(loading: true));
    return _pending = _load(username, expectedUserId, request).whenComplete(() {
      if (request == _request) _pending = null;
    });
  }

  Future<void> _load(String username, String? id, int request) async {
    if (PublicUserProfile.normalizeUsername(username) == null) {
      emit(
        const SellerProfileState(
          error: ProfilePostStrings.publicIdentityMissing,
          canRetry: false,
        ),
      );
      return;
    }
    try {
      final profile = await _repository.load(username, expectedUserId: id);
      if (!isClosed && request == _request) {
        emit(SellerProfileState(profile: profile));
      }
    } catch (error) {
      if (isClosed || request != _request) return;
      final status = error is DioException ? error.response?.statusCode : null;
      emit(SellerProfileState(error: _message(error), canRetry: status != 404));
    }
  }

  String _message(Object error) {
    if (error is TimeoutException) return ProfilePostStrings.publicTimeout;
    if (error is! DioException) return ProfilePostStrings.publicLoadFailed;
    if (error.response?.statusCode == 404) {
      return ProfilePostStrings.publicUnavailable;
    }
    if (error.response?.statusCode == 401) {
      return ProfilePostStrings.publicSessionFailed;
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ProfilePostStrings.publicTimeout,
      DioExceptionType.connectionError =>
        ProfilePostStrings.publicConnectionFailed,
      _ => ProfilePostStrings.publicLoadFailed,
    };
  }

  void invalidate() {
    if (isClosed) return;
    _request++;
    _pending = null;
    emit(
      const SellerProfileState(error: ProfilePostStrings.publicSessionChanged),
    );
  }

  @override
  Future<void> close() {
    _request++;
    return super.close();
  }
}
