import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/create_post_strings.dart';

import '../../domain/models/post_options.dart';

class PostFeaturesState {
  const PostFeaturesState(this.features, {this.editing, this.error});
  final List<PostFeature> features;
  final int? editing;
  final String? error;
}

class PostFeaturesCubit extends Cubit<PostFeaturesState> {
  PostFeaturesCubit(List<PostFeature> features)
    : super(PostFeaturesState(List.unmodifiable(features)));
  bool save(String name, String value) {
    name = name.trim();
    value = value.trim();
    String? error;
    if (name.isEmpty || value.isEmpty) {
      error = CreatePostStrings.featureAndValueRequired;
    } else if (state.features.indexed.any(
      (entry) =>
          entry.$1 != state.editing &&
          entry.$2.name.toLowerCase() == name.toLowerCase(),
    )) {
      error = CreatePostStrings.featureExists;
    }
    if (error != null) {
      emit(
        PostFeaturesState(state.features, editing: state.editing, error: error),
      );
      return false;
    }
    final features = [...state.features];
    final feature = PostFeature(name: name, value: value);
    if (state.editing == null) {
      features.add(feature);
    } else {
      features[state.editing!] = feature;
    }
    emit(PostFeaturesState(List.unmodifiable(features)));
    return true;
  }

  void remove(int index) {
    final features = [...state.features]..removeAt(index);
    emit(PostFeaturesState(List.unmodifiable(features), error: state.error));
  }

  void edit(int index) => emit(
    PostFeaturesState(state.features, editing: index, error: state.error),
  );
}
