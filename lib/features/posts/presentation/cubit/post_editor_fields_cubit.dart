import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/create_post/models/post_draft.dart';

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
    : _original = {
        for (final (index, feature) in draft.features.indexed) index: feature,
      },
      _nextId = draft.features.length,
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
  final Map<int, PostFeature> _original;

  List<PostFeature> toFeatures() => [
    for (final entry in state.features) _feature(entry),
  ];

  PostFeature _feature(EditablePostFeature entry) {
    final original = _original[entry.id];
    if (original != null &&
        entry.name == original.name &&
        entry.value == original.value)
      return original;
    final unchangedValue = original != null && entry.value == original.value;
    final text = unchangedValue ? original.value : entry.value.trim();
    Object? typed =
        original?.apiValue ?? (unchangedValue ? original.value : null);
    if (original != null && !unchangedValue && typed != null) {
      if (typed is bool) {
        if (text != 'true' && text != 'false')
          throw const FormatException('Enter true or false for this feature.');
        typed = text == 'true';
      } else if (typed is int) {
        typed = int.tryParse(text);
        if (typed == null)
          throw const FormatException('Enter a whole number for this feature.');
      } else if (typed is num) {
        typed = double.tryParse(text);
        if (typed == null || !(typed as double).isFinite)
          throw const FormatException('Enter a valid number for this feature.');
      }
    }
    return PostFeature(
      name: entry.name.trim(),
      value: text,
      apiValue: typed,
      unit: original?.unit,
    );
  }

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
