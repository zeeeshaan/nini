import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import '../../domain/user_profile.dart';
import '../../domain/user_profile_repository.dart';
import 'user_profile_state.dart';

export 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this.repository) : super(const UserProfileState());

  final UserProfileRepository repository;
  Future<void>? _loading;
  Future<bool>? _saving;
  bool _loaded = false, _closing = false;

  PostSeller get seller => state.profile.seller;

  Future<void> load() {
    if (_closing || state.saving) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    emit(UserProfileState(profile: state.profile));
    try {
      final profile = await repository.load();
      _loaded = true;
      emit(UserProfileState(profile: profile, loading: false));
    } catch (_) {
      _loaded = false;
      emit(
        UserProfileState(
          profile: state.profile,
          loading: false,
          loadFailed: true,
        ),
      );
    }
  }

  Future<bool> save(UserProfile profile, {Uint8List? photo}) {
    if (_closing) return Future.value(false);
    return _saving ??= _save(profile, photo).whenComplete(() => _saving = null);
  }

  Future<bool> _save(UserProfile profile, Uint8List? photo) async {
    if (!_loaded) await load();
    if (!_loaded) return false;
    final previous = state.profile;
    emit(UserProfileState(profile: previous, loading: false, saving: true));
    try {
      final saved = await repository.save(profile, photo: photo);
      emit(UserProfileState(profile: saved, loading: false));
      return true;
    } catch (_) {
      emit(
        UserProfileState(profile: previous, loading: false, saveFailed: true),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    await _loading;
    await _saving;
    await super.close();
  }
}
