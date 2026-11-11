import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/team/domain/team_provider_selection.dart';
import 'package:nini/shared/models/post/post_attributes.dart';

enum TeamRequestStatus { draft, awaiting, accepted, declined, cancelled, paid }

/// One shared work brief for all selected providers. Statuses are UI previews.
class TeamRequest {
  TeamRequest({
    required List<TeamProviderSelection> providers,
    this.title = '',
    this.description = '',
    this.schedule,
    List<GalleryAttachment> attachments = const [],
    this.status = TeamRequestStatus.draft,
    this.paymentId,
  }) : providers = List.unmodifiable(providers),
       attachments = List.unmodifiable(attachments);

  final List<TeamProviderSelection> providers;
  final String title, description;
  final PostSchedule? schedule;
  final List<GalleryAttachment> attachments;
  final TeamRequestStatus status;
  final String? paymentId;

  bool get canSubmit =>
      providers.isNotEmpty &&
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      schedule != null &&
      providers.every((selection) => selection.quantity > 0);

  TeamRequest copyWith({
    List<TeamProviderSelection>? providers,
    String? title,
    String? description,
    PostSchedule? schedule,
    List<GalleryAttachment>? attachments,
    TeamRequestStatus? status,
    String? paymentId,
    bool clearPayment = false,
  }) => TeamRequest(
    providers: providers ?? this.providers,
    title: title ?? this.title,
    description: description ?? this.description,
    schedule: schedule ?? this.schedule,
    attachments: attachments ?? this.attachments,
    status: status ?? this.status,
    paymentId: clearPayment ? null : paymentId ?? this.paymentId,
  );
}
