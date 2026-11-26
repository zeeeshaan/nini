import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/features/posts/domain/profile_categories_repository.dart';
import 'package:hywork/features/posts/domain/validation/profile_category_validator.dart';

import 'profile_categories_state.dart';

export 'profile_categories_state.dart';

/// Shared by the profile, tab manager, and existing profile-category selectors.
class ProfileCategoriesCubit extends Cubit<ProfileCategoriesState> {
  ProfileCategoriesCubit(this.repository)
    : super(const ProfileCategoriesState());
  final ProfileCategoriesRepository repository;

  Future<void>? _loading;
  bool _loaded = false;
  bool _closing = false;

  Future<void> load({bool refresh = false}) {
    if (_closing || isClosed || state.saving) return Future.value();
    if (_loading != null) return _loading!;
    if (_loaded && !refresh) return Future.value();
    return _loading = _load().whenComplete(() => _loading = null);
  }

  void clearError() {
    if (_closing || isClosed || state.error == null || state.loadFailed) return;
    emit(state.copyWith(clearError: true));
  }

  Future<void> _load() async {
    emit(state.copyWith(loading: true, loadFailed: false, clearError: true));
    try {
      final result = await repository.load();
      if (_closing || isClosed) return;
      _loaded = true;
      _showCatalog(result);
    } catch (error) {
      if (_closing || isClosed) return;
      _loaded = false;
      _fail(error, loadFailed: true);
    }
  }

  void select(String? id) {
    if (_closing || isClosed || (id != null && state.find(id) == null)) return;
    emit(state.copyWith(selectedId: id, clearSelection: id == null));
  }

  Future<bool> create(String name) => _mutate(() async {
    final error = ProfileCategoryValidator.validateName(name, state.categories);
    if (error != null) throw ProfileCategoryException(error);
    if (state.categories.length >= ProfileCategoryValidator.maxCategories) {
      throw const ProfileCategoryException(ProfilePostStrings.categoryLimit);
    }
    final category = await repository.create(name.trim());
    // A confirmed response must never append the same backend ID twice.
    final existing = state.find(category.id);
    if (existing != null) {
      if (existing.name != category.name) {
        throw const FormatException('Conflicting category identity.');
      }
      return _snapshot([
        for (final item in state.categories)
          if (item.id == category.id) category else item,
      ]);
    }
    return _snapshot([...state.categories, category]);
  });

  ProfileCategoryList _snapshot(List<ProfileCategory> items) =>
      ProfileCategoryList(
        items: List.unmodifiable(items),
        allCount: state.allCount,
        uncategorizedCount: state.uncategorizedCount,
      );

  ProfileCategory _requireCategory(String id) {
    final category = state.find(id);
    if (!ProfileCategory.isBackendId(id) || category == null) {
      throw const ProfileCategoryException(
        ProfilePostStrings.categoryUnavailable,
      );
    }
    return category;
  }

  Future<bool> rename(String id, String name) => _mutate(() async {
    final previous = _requireCategory(id);
    final error = ProfileCategoryValidator.validateName(
      name,
      state.categories,
      excludingId: id,
    );
    if (error != null) throw ProfileCategoryException(error);
    final category = await repository.rename(id, name);
    final updated = ProfileCategory(
      id: category.id,
      name: category.name,
      position: category.position ?? previous.position,
      postsCount: category.postsCount ?? previous.postsCount,
      createdAt: category.createdAt ?? previous.createdAt,
    );
    return _snapshot([
      for (final item in state.categories)
        if (item.id == id) updated else item,
    ]);
  });

  Future<bool> delete(String id) => _mutate(() async {
    _requireCategory(id);
    final moved = await repository.delete(id);
    return ProfileCategoryList(
      items: List.unmodifiable(state.categories.where((item) => item.id != id)),
      allCount: state.allCount,
      uncategorizedCount: moved == null || state.uncategorizedCount == null
          ? null
          : state.uncategorizedCount! + moved,
    );
  });

  Future<bool> reorder(List<String> ids) {
    final order = List<String>.unmodifiable(ids);
    if (!state.loading &&
        !state.loadFailed &&
        !state.saving &&
        order.length == state.categories.length &&
        order.indexed.every(
          (entry) => state.categories[entry.$1].id == entry.$2,
        )) {
      return Future.value(true);
    }
    return _mutate(() async {
      final expected = state.categories.map((item) => item.id).toSet();
      if (order.length != expected.length ||
          order.toSet().length != order.length ||
          !order.every(
            (id) => ProfileCategory.isBackendId(id) && expected.contains(id),
          )) {
        throw const ProfileCategoryException(
          ProfilePostStrings.categoryOrderInvalid,
        );
      }
      final result = await repository.reorder(order);
      return ProfileCategoryList(
        items: result.items,
        allCount: result.allCount ?? state.allCount,
        uncategorizedCount:
            result.uncategorizedCount ?? state.uncategorizedCount,
      );
    }, reloadOnFailure: true);
  }

  Future<bool> _mutate(
    Future<ProfileCategoryList> Function() operation, {
    bool reloadOnFailure = false,
  }) async {
    if (_closing ||
        isClosed ||
        state.loading ||
        state.saving ||
        state.loadFailed) {
      return false;
    }
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final result = await operation();
      if (_closing || isClosed) return false;
      _showCatalog(result);
      return true;
    } catch (error) {
      if (_closing || isClosed) return false;
      if (reloadOnFailure && error is! ProfileCategoryException) {
        await _recoverOrder(error);
      } else {
        _fail(error);
      }
      return false;
    }
  }

  Future<void> _recoverOrder(Object failure) async {
    try {
      final result = await repository.load();
      if (_closing || isClosed) return;
      _showCatalog(result, error: _message(failure, loading: false));
    } catch (error) {
      if (_closing || isClosed) return;
      _loaded = false;
      _fail(
        error is ProfileCategoryException && error.sessionExpired
            ? error
            : failure,
        loadFailed: true,
      );
    }
  }

  void _showCatalog(ProfileCategoryList result, {String? error}) => emit(
    ProfileCategoriesState(
      categories: List.unmodifiable(result.items),
      allCount: result.allCount,
      uncategorizedCount: result.uncategorizedCount,
      selectedId: result.items.any((item) => item.id == state.selectedId)
          ? state.selectedId
          : null,
      loading: false,
      error: error,
    ),
  );

  void _fail(Object error, {bool loadFailed = false}) {
    final expired =
        (error is ProfileCategoryException && error.sessionExpired) ||
        (error is DioException && error.response?.statusCode == 401);
    if (expired) _loaded = false;
    final previous = expired ? const ProfileCategoriesState() : state;
    emit(
      previous.copyWith(
        loading: false,
        saving: false,
        loadFailed: loadFailed || expired,
        error: _message(error, loading: loadFailed),
      ),
    );
  }

  String _message(Object error, {required bool loading}) {
    if (error is ProfileCategoryException) return error.message;
    if (error is TimeoutException) return ProfilePostStrings.categoryTimeout;
    if (error is FormatException) {
      return ProfilePostStrings.categoryResponseInvalid;
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) return ProfilePostStrings.categorySessionExpired;
      if (status == 404) return ProfilePostStrings.categoryUnavailable;
      if (status == 400) return ProfilePostStrings.categoryInvalid;
      if (status == 409) {
        final body = error.response?.data;
        return body is Map &&
                body['message'] == 'You already have a category with this name'
            ? ProfilePostStrings.duplicateName
            : ProfilePostStrings.categoryConflict;
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ProfilePostStrings.categoryTimeout;
        case DioExceptionType.connectionError:
          return ProfilePostStrings.categoryConnectionFailed;
        default:
          break;
      }
    }
    return loading
        ? ProfilePostStrings.loadFailed
        : ProfilePostStrings.saveFailed;
  }

  @override
  Future<void> close() {
    _closing = true;
    return super.close();
  }
}
