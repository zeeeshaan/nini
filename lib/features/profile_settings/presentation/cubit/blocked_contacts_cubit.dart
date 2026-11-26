import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/chat/data/in_memory_chat_repository.dart';

import '../../domain/blocked_contact.dart';

class BlockedContactsCubit extends Cubit<List<BlockedContact>> {
  BlockedContactsCubit(this.repository) : super(const []) {
    refresh();
  }
  final InMemoryChatRepository repository;

  void refresh() => emit(
    List.unmodifiable([
      for (final id in repository.blockedConversationIds)
        BlockedContact(
          id: id,
          name: repository.conversations
              .where((chat) => chat.id == id)
              .firstOrNull
              ?.name,
          avatar: repository.conversations
              .where((chat) => chat.id == id)
              .firstOrNull
              ?.avatarAsset,
        ),
    ]),
  );

  void unblock(String id) {
    repository.setBlocked(id, false);
    refresh();
  }
}
