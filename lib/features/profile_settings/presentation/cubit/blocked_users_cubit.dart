import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/features/profile/data/api_public_profile_repository.dart';

import '../../domain/blocked_contact.dart';

class BlockedUsersState {
  const BlockedUsersState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.page = 0,
    this.hasMore = true,
    this.unblockingId,
  });

  final List<BlockedContact> items;
  final bool loading, hasMore;
  final String? error;
  final int page;
  final String? unblockingId;
}

/// Loads `GET /users/me/blocked` and unblocks via the Phase 1 repository.
class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit(this._repository, {required this.isCurrentAccount})
    : super(const BlockedUsersState(loading: true)) {
    load();
  }

  final ApiPublicProfileRepository _repository;
  final bool Function() isCurrentAccount;
  int _revision = 0;

  Future<void> load({bool next = false}) async {
    if (isClosed) return;
    if (next && (state.loading || !state.hasMore)) return;
    if (!isCurrentAccount()) {
      emit(
        const BlockedUsersState(
          error: ProfileSettingsStrings.blockedSignInRequired,
        ),
      );
      return;
    }
    final revision = next ? _revision : ++_revision;
    final page = next ? state.page + 1 : 1;
    emit(
      BlockedUsersState(
        items: next ? state.items : const [],
        loading: true,
        page: next ? state.page : 0,
        hasMore: next ? state.hasMore : true,
      ),
    );
    try {
      final result = await _repository.loadBlocked(
        page: page,
        limit: 20,
        isCurrentAccount: isCurrentAccount,
      );
      if (isClosed || revision != _revision || !isCurrentAccount()) return;
      final mapped = [
        for (final entry in result.items)
          BlockedContact(
            id: entry.id,
            name: (entry.name != null && entry.name!.trim().isNotEmpty)
                ? entry.name
                : entry.username,
            avatar: entry.avatarUrl,
          ),
      ];
      final items = [if (next) ...state.items, ...mapped];
      emit(
        BlockedUsersState(
          items: List.unmodifiable(items),
          page: result.page,
          hasMore: result.page * result.limit < result.total,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _revision) return;
      final status = error is DioException ? error.response?.statusCode : null;
      emit(
        BlockedUsersState(
          items: state.items,
          page: state.page,
          hasMore: state.hasMore,
          error: status == 401
              ? ProfileSettingsStrings.blockedSignInRequired
              : ProfileSettingsStrings.blockedLoadFailed,
        ),
      );
    }
  }

  Future<void> unblock(String id) async {
    if (isClosed || state.unblockingId != null || !isCurrentAccount()) return;
    emit(
      BlockedUsersState(
        items: state.items,
        page: state.page,
        hasMore: state.hasMore,
        unblockingId: id,
      ),
    );
    try {
      await _repository.unblock(id, isCurrentAccount: isCurrentAccount);
      if (isClosed || !isCurrentAccount()) return;
      emit(
        BlockedUsersState(
          items: List.unmodifiable(
            state.items.where((contact) => contact.id != id),
          ),
          page: state.page,
          hasMore: state.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      final status = error is DioException ? error.response?.statusCode : null;
      emit(
        BlockedUsersState(
          items: state.items,
          page: state.page,
          hasMore: state.hasMore,
          error: error is FormatException
              ? error.message
              : status == 401
              ? ProfileSettingsStrings.blockedSignInRequired
              : ProfileSettingsStrings.unblockFailed,
        ),
      );
    }
  }
}
