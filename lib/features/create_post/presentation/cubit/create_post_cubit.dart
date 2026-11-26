import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/features/create_post/domain/models/post_draft.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';

class CreatePostCubit extends Cubit<PostDraft> {
  CreatePostCubit({PostDraft initial = const PostDraft()}) : super(initial);
  void selectCategory(String? key) =>
      emit(state.copyWith(categoryKey: key, clearCategory: key == null));
  void selectProfileCategory(String? id) => emit(
    state.copyWith(profileCategoryId: id, clearProfileCategory: id == null),
  );
  bool assignProfileCategory(String id, List<ProfileCategory> available) {
    if (isClosed ||
        !ProfileCategory.isBackendId(id) ||
        !available.any((category) => category.id == id)) {
      return false;
    }
    selectProfileCategory(id);
    return true;
  }

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
  void updateAddress(PostAddress? value) =>
      emit(state.copyWith(address: value, clearAddress: value == null));
  void setAddress(AddressSelection value) => emit(
    state.copyWith(address: value.selected, savedAddresses: value.saved),
  );
  void setFeatures(List<PostFeature> value) =>
      emit(state.copyWith(features: value));
  void setTags(List<String> value) => emit(state.copyWith(tags: value));
  void addTags(String text) {
    final tags = [...state.tags];
    for (final candidate in text.split(RegExp(r'[,،\n]'))) {
      final tag = candidate.trim().replaceFirst(RegExp(r'^#+'), '');
      if (tag.isNotEmpty &&
          !tags.any((value) => value.toLowerCase() == tag.toLowerCase())) {
        tags.add(tag);
      }
    }
    setTags(List.unmodifiable(tags));
  }

  void removeTag(String tag) {
    final tags = [...state.tags]..remove(tag);
    setTags(List.unmodifiable(tags));
  }

  void setAltTexts(Map<String, String> value) =>
      emit(state.copyWith(altTexts: value));
}
