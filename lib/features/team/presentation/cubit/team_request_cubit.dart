import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/create_post/models/gallery_attachment.dart';
import 'package:hywork/features/team/domain/team_request.dart';
import 'package:hywork/shared/models/post/post_attributes.dart';

class TeamRequestCubit extends Cubit<TeamRequest> {
  TeamRequestCubit(super.initialState);
  bool _checkoutOpen = false;

  Future<void> checkout(Future<String?> Function() openCheckout) async {
    if (_checkoutOpen || state.status != TeamRequestStatus.accepted) return;
    _checkoutOpen = true;
    try {
      final orderId = await openCheckout();
      if (!isClosed && orderId != null) completePreviewPayment(orderId);
    } finally {
      _checkoutOpen = false;
    }
  }

  void updateTitle(String value) => emit(state.copyWith(title: value));
  void updateDescription(String value) =>
      emit(state.copyWith(description: value));
  void updateSchedule(PostSchedule value) =>
      emit(state.copyWith(schedule: value));

  void updateQuantity(String providerId, int value) {
    if (value <= 0) return;
    emit(
      state.copyWith(
        providers: [
          for (final selection in state.providers)
            if (selection.provider.id == providerId)
              selection.withQuantity(value)
            else
              selection,
        ],
      ),
    );
  }

  void addAttachments(List<GalleryAttachment> selected) {
    final attachments = {
      for (final item in state.attachments) item.id: item,
      for (final item in selected) item.id: item,
    };
    emit(state.copyWith(attachments: attachments.values.toList()));
  }

  void removeAttachment(String id) => emit(
    state.copyWith(
      attachments: state.attachments.where((item) => item.id != id).toList(),
    ),
  );

  bool submit() {
    if (!state.canSubmit || state.status != TeamRequestStatus.draft) {
      return false;
    }
    emit(
      state.copyWith(
        title: state.title.trim(),
        description: state.description.trim(),
        status: TeamRequestStatus.awaiting,
      ),
    );
    return true;
  }

  void previewResponse({required bool accepted}) {
    if (state.status != TeamRequestStatus.awaiting) return;
    emit(
      state.copyWith(
        status: accepted
            ? TeamRequestStatus.accepted
            : TeamRequestStatus.declined,
      ),
    );
  }

  void cancelRequest() {
    if (state.status == TeamRequestStatus.paid) return;
    emit(state.copyWith(status: TeamRequestStatus.cancelled));
  }

  void edit() {
    if (state.status == TeamRequestStatus.paid) return;
    emit(state.copyWith(status: TeamRequestStatus.draft, clearPayment: true));
  }

  void completePreviewPayment(String orderId) {
    if (state.status != TeamRequestStatus.accepted || orderId.isEmpty) return;
    emit(state.copyWith(status: TeamRequestStatus.paid, paymentId: orderId));
  }
}
