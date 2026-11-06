import 'package:flutter_bloc/flutter_bloc.dart';

class PostOperationState {
  const PostOperationState({
    this.dirty = false,
    this.saving = false,
    this.allowPop = false,
    this.error,
  });
  final bool dirty, saving, allowPop;
  final String? error;
}

class PostOperationCubit extends Cubit<PostOperationState> {
  PostOperationCubit() : super(const PostOperationState());
  void markDirty() {
    if (!state.dirty) {
      emit(
        PostOperationState(
          dirty: true,
          saving: state.saving,
          allowPop: state.allowPop,
          error: state.error,
        ),
      );
    }
  }

  void beginSave() => emit(
    PostOperationState(
      dirty: state.dirty,
      saving: true,
      allowPop: state.allowPop,
    ),
  );
  void fail(String error) => emit(
    PostOperationState(
      dirty: state.dirty,
      allowPop: state.allowPop,
      error: error,
    ),
  );
  void showError(String error) => emit(
    PostOperationState(
      dirty: state.dirty,
      saving: state.saving,
      allowPop: state.allowPop,
      error: error,
    ),
  );
  void allowPop() => emit(
    PostOperationState(
      dirty: state.dirty,
      saving: state.saving,
      allowPop: true,
      error: state.error,
    ),
  );
  void retry() =>
      emit(PostOperationState(dirty: state.dirty, allowPop: state.allowPop));
}
