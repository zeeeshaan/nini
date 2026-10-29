import 'package:flutter_bloc/flutter_bloc.dart';

class PostDetailState {
  const PostDetailState({
    this.imageIndex = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  final int imageIndex;
  final bool isLiked;
  final bool isBookmarked;

  PostDetailState copyWith({
    int? imageIndex,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return PostDetailState(
      imageIndex: imageIndex ?? this.imageIndex,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit() : super(const PostDetailState());

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
