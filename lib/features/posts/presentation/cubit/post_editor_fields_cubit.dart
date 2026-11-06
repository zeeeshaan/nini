import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';

typedef EditablePostFeature = ({int id, String name, String value});

class PostEditorFieldsState {
  const PostEditorFieldsState({
    required this.features,
    this.startsAt,
    this.endsAt,
  });
  final List<EditablePostFeature> features;
  final DateTime? startsAt, endsAt;
}

class PostEditorFieldsCubit extends Cubit<PostEditorFieldsState> {
  PostEditorFieldsCubit(PostDraft draft)
    : _nextId = draft.features.length,
      super(
        PostEditorFieldsState(
          features: List.unmodifiable([
            for (final (index, feature) in draft.features.indexed)
              (id: index, name: feature.name, value: feature.value),
          ]),
          startsAt: draft.schedule?.startsAt,
          endsAt: draft.schedule?.endsAt,
        ),
      );
  int _nextId;
  void _features(List<EditablePostFeature> features) => emit(
    PostEditorFieldsState(
      features: List.unmodifiable(features),
      startsAt: state.startsAt,
      endsAt: state.endsAt,
    ),
  );
  void addFeature() =>
      _features([...state.features, (id: _nextId++, name: '', value: '')]);
  void removeFeature(int id) =>
      _features(state.features.where((feature) => feature.id != id).toList());
  void changeFeature(int id, {String? name, String? value}) => _features([
    for (final feature in state.features)
      if (feature.id == id)
        (id: id, name: name ?? feature.name, value: value ?? feature.value)
      else
        feature,
  ]);
  void start(DateTime value) => emit(
    PostEditorFieldsState(
      features: state.features,
      startsAt: value,
      endsAt: state.endsAt,
    ),
  );
  void end(DateTime value) => emit(
    PostEditorFieldsState(
      features: state.features,
      startsAt: state.startsAt,
      endsAt: value,
    ),
  );
  void clearSchedule() => emit(PostEditorFieldsState(features: state.features));
}
