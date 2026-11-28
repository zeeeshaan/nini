import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/features/create_post/models/gallery_attachment.dart';
import 'package:hywork/features/team/domain/team_provider_selection.dart';
import 'package:hywork/features/team/domain/team_request.dart';
import 'package:hywork/shared/models/post/post_attributes.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

class TeamFormState {
  const TeamFormState({
    this.name = '',
    this.description = '',
    this.locations = const [],
    this.timeFrame,
    this.attachments = const [],
    this.members = const [],
    this.memberServices = const {},
    this.requestDraft,
  });

  final String name;
  final String description;
  final List<PostAddress> locations;
  final PostSchedule? timeFrame;
  final List<GalleryAttachment> attachments;
  final List<PostSeller> members;
  final Map<String, TeamProviderSelection> memberServices;
  final TeamRequest? requestDraft;

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
    Map<String, TeamProviderSelection>? memberServices,
    TeamRequest? requestDraft,
  }) {
    return TeamFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      locations: locations ?? this.locations,
      timeFrame: clearTimeFrame ? null : timeFrame ?? this.timeFrame,
      attachments: attachments ?? this.attachments,
      members: members == null ? this.members : List.unmodifiable(members),
      memberServices: memberServices == null
          ? this.memberServices
          : Map.unmodifiable(memberServices),
      requestDraft: requestDraft ?? this.requestDraft,
    );
  }
}

class TeamFormCubit extends Cubit<TeamFormState> {
  TeamFormCubit() : super(const TeamFormState());

  void updateRequestDraft(TeamRequest request) {
    if (isClosed) return;
    final services = {
      for (final selection in request.providers)
        if (state.memberServices.containsKey(selection.provider.id))
          selection.provider.id: selection,
    };
    emit(state.copyWith(memberServices: services, requestDraft: request));
  }

  void toggleProvider(TeamProviderSelection selection) {
    final member = selection.provider;
    if (isClosed || member.id.trim().isEmpty || selection.quantity <= 0) return;
    final services = {...state.memberServices};
    final selected = state.hasMember(member.id);
    if (selected) {
      services.remove(member.id);
    } else {
      services[member.id] = selection;
    }
    emit(
      state.copyWith(
        members: selected
            ? state.members.where((entry) => entry.id != member.id).toList()
            : [...state.members, member],
        memberServices: services,
        requestDraft: state.requestDraft?.copyWith(
          providers: services.values.toList(),
          status: TeamRequestStatus.draft,
          clearPayment: true,
        ),
      ),
    );
  }

  void toggleMember(PostSeller member) {
    if (isClosed || member.id.trim().isEmpty) return;
    final services = {...state.memberServices}..remove(member.id);
    emit(
      state.copyWith(
        members: state.hasMember(member.id)
            ? state.members.where((entry) => entry.id != member.id).toList()
            : [...state.members, member],
        memberServices: services,
        requestDraft: state.requestDraft?.copyWith(
          providers: services.values.toList(),
          status: TeamRequestStatus.draft,
          clearPayment: true,
        ),
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
    emit(state.copyWith(locations: List.unmodifiable(locations)));
  }

  void updateTimeFrame(PostSchedule? timeFrame) {
    emit(
      state.copyWith(timeFrame: timeFrame, clearTimeFrame: timeFrame == null),
    );
  }

  void addAttachments(List<GalleryAttachment> selected) {
    final attachments = {
      for (final item in state.attachments) item.id: item,
      for (final item in selected) item.id: item,
    };

    emit(state.copyWith(attachments: List.unmodifiable(attachments.values)));
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
