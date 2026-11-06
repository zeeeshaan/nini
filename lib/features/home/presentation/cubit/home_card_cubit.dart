import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCardState {
  const HomeCardState({
    this.liked = true,
    this.bookmarked = false,
    this.imageAttempt = 0,
  });
  final bool liked, bookmarked;
  final int imageAttempt;
}

class HomeCardCubit extends Cubit<HomeCardState> {
  HomeCardCubit() : super(const HomeCardState());
  void toggleLike() => emit(
    HomeCardState(
      liked: !state.liked,
      bookmarked: state.bookmarked,
      imageAttempt: state.imageAttempt,
    ),
  );
  void toggleBookmark() => emit(
    HomeCardState(
      liked: state.liked,
      bookmarked: !state.bookmarked,
      imageAttempt: state.imageAttempt,
    ),
  );
  void retryImage() => emit(
    HomeCardState(
      liked: state.liked,
      bookmarked: state.bookmarked,
      imageAttempt: state.imageAttempt + 1,
    ),
  );
}
