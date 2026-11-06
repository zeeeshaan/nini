import 'package:flutter_bloc/flutter_bloc.dart';

class PostDetailState {
  const PostDetailState({
    this.imageIndex = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.quantity = 0,
  });

  final int imageIndex;
  final bool isLiked;
  final bool isBookmarked;

  /// Hundredths of a unit, matching the Cart quantity format.
  final int quantity;

  PostDetailState copyWith({
    int? imageIndex,
    bool? isLiked,
    bool? isBookmarked,
    int? quantity,
  }) {
    return PostDetailState(
      imageIndex: imageIndex ?? this.imageIndex,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      quantity: quantity ?? this.quantity,
    );
  }
}

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit() : super(const PostDetailState());

  void selectQuantity(int quantity) {
    if (quantity < 0 || quantity == state.quantity) return;
    emit(state.copyWith(quantity: quantity));
  }

  void changeImage(int index) {
    if (index < 0 || state.imageIndex == index) return;

    emit(state.copyWith(imageIndex: index));
  }

  void toggleLike() {
    emit(state.copyWith(isLiked: !state.isLiked));
  }

  void toggleBookmark() {
    emit(state.copyWith(isBookmarked: !state.isBookmarked));
  }
}
