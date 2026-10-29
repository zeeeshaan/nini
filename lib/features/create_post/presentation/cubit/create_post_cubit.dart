import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/create_post/domain/models/post_draft.dart';

class CreatePostCubit extends Cubit<PostDraft> {
  CreatePostCubit() : super(const PostDraft());
  void selectPostType(CreatePostType value) =>
      emit(state.copyWith(postType: value));
  void updateTitle(String value) => emit(state.copyWith(title: value));
  void updateCaption(String value) =>
      emit(state.copyWith(caption: value, captionDelta: []));
  void updateRichCaption(String text, List<Map<String, dynamic>> delta) =>
      emit(state.copyWith(caption: text, captionDelta: delta));
  void updatePrice(String value) => emit(state.copyWith(price: value));
  void updateDiscount(String value) => emit(state.copyWith(discount: value));
  void updateWarehouseStock(String value) =>
      emit(state.copyWith(warehouseStock: value));
  void selectPreparationTime(PreparationTime value) =>
      emit(state.copyWith(preparationTime: value));
  void selectUnit(PostUnit value) => emit(state.copyWith(unit: value));
  void selectInventoryStatus(InventoryStatus value) =>
      emit(state.copyWith(inventoryStatus: value));
  void setSchedule(PostSchedule? value) =>
      emit(state.copyWith(schedule: value, clearSchedule: value == null));
  void setAddress(AddressSelection value) => emit(
    state.copyWith(address: value.selected, savedAddresses: value.saved),
  );
  void setFeatures(List<PostFeature> value) =>
      emit(state.copyWith(features: value));
  void setTags(List<String> value) => emit(state.copyWith(tags: value));
  void setAltTexts(Map<String, String> value) =>
      emit(state.copyWith(altTexts: value));
}
