
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/shared/models/post/post_attributes.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class TeamFormState {
  const TeamFormState({
    this.name = '',
    this.description = '',
    this.locations = const [],
    this.timeFrame,
    this.attachments = const [],
    this.members = const [],
  });

  final String name;
  final String description;
  final List<PostAddress> locations;
  final PostSchedule? timeFrame;
  final List<GalleryAttachment> attachments;
  final List<PostSeller> members;

  bool hasMember(String providerId) =>
      members.any((member) => member.id == providerId);

  bool get canSubmit => name.trim().isNotEmpty;

  TeamFormState copyWith({
    String? name,
    String? description,
    List<PostAddress>? locations,
    PostSchedule? timeFrame,
    bool clearTimeFrame = false,
    List<GalleryAttachment>? attachments,
    List<PostSeller>? members,
  }) {
    return TeamFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      locations: locations ?? this.locations,
      timeFrame: clearTimeFrame
          ? null
          : timeFrame ?? this.timeFrame,
      attachments: attachments ?? this.attachments,
      members: members == null ? this.members : List.unmodifiable(members),
    );
  }
}

class TeamFormCubit extends Cubit<TeamFormState> {
  TeamFormCubit() : super(const TeamFormState());

  void toggleMember(PostSeller member) {
    if (isClosed || member.id.trim().isEmpty) return;
    emit(
      state.copyWith(
        members: state.hasMember(member.id)
            ? state.members.where((entry) => entry.id != member.id).toList()
            : [...state.members, member],
      ),
    );
  }

  void updateName(String value) {
    emit(state.copyWith(name: value));
  }

  void updateDescription(String value) {
    emit(state.copyWith(description: value));
  }

  void updateLocations(List<PostAddress> locations) {
    emit(
      state.copyWith(
        locations: List.unmodifiable(locations),
      ),
    );
  }

  void updateTimeFrame(PostSchedule? timeFrame) {
    emit(
      state.copyWith(
        timeFrame: timeFrame,
        clearTimeFrame: timeFrame == null,
      ),
    );
  }

  void addAttachments(List<GalleryAttachment> selected) {
    final attachments = {
      for (final item in state.attachments) item.id: item,
      for (final item in selected) item.id: item,
    };

    emit(
      state.copyWith(
        attachments: List.unmodifiable(attachments.values),
      ),
    );
  }

  void removeAttachment(String id) {
    emit(
      state.copyWith(
        attachments: List.unmodifiable(
          state.attachments.where((item) => item.id != id),
        ),
      ),
    );
  }
}
