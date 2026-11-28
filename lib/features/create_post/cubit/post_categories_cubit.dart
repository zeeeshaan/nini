import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';

import 'package:hywork/features/create_post/data/api_categories_repository.dart';
import 'package:hywork/features/create_post/models/post_category.dart';

class PostCategoriesState {
  const PostCategoriesState({
    this.categories = const [],
    this.loading = true,
    this.error,
  });
  final List<PostCategory> categories;
  final bool loading;
  final String? error;

  PostCategory? find(String? key) {
    for (final category in categories) {
      if (category.key == key) return category;
    }
    return null;
  }
}

/// Owned by the gallery flow so back/forward navigation retains one catalog.
class PostCategoriesCubit extends Cubit<PostCategoriesState> {
  PostCategoriesCubit(this._repository) : super(const PostCategoriesState());
  final ApiCategoriesRepository _repository;
  Future<void>? _pending;
  bool _loaded = false;

  Future<void> load({bool refresh = false}) {
    if (isClosed) return Future.value();
    if (_pending != null) return _pending!;
    if (_loaded && !refresh) return Future.value();
    return _pending = _load().whenComplete(() => _pending = null);
  }

  Future<void> _load() async {
    emit(const PostCategoriesState());
    try {
      final categories = await _repository.load();
      if (isClosed) return;
      _loaded = true;
      emit(PostCategoriesState(categories: categories, loading: false));
    } catch (error) {
      if (isClosed) return;
      _loaded = false;
      emit(PostCategoriesState(loading: false, error: _message(error)));
    }
  }

  String _message(Object error) {
    if (error is TimeoutException) return CreatePostStrings.categoriesTimeout;
    if (error is FormatException) return CreatePostStrings.categoriesInvalid;
    if (error is! DioException) return CreatePostStrings.categoriesLoadFailed;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => CreatePostStrings.categoriesTimeout,
      DioExceptionType.connectionError =>
        CreatePostStrings.categoriesConnectionFailed,
      _ => CreatePostStrings.categoriesLoadFailed,
    };
  }
}
