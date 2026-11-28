import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/models/chat_conversation.dart';
import 'package:hywork/features/chat/cubit/chat_inbox_cubit.dart';
import 'package:hywork/features/chat/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/chat/utils/chat_account_scope.dart';
import 'package:hywork/features/chat/utils/push_chat_conversation.dart';
import 'package:hywork/features/chat/widgets/chat_inbox_header/chat_inbox_header.dart';
import 'package:hywork/features/chat/widgets/chat_inbox_list/chat_inbox_list.dart';
import 'package:hywork/features/chat/widgets/chat_inbox_search/chat_inbox_search.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';

class ChatInboxScreen extends StatelessWidget {
  const ChatInboxScreen({super.key, this.onOpenConversation});

  final ValueChanged<ChatConversation>? onOpenConversation;

  @override
  Widget build(BuildContext context) {
    final account = ChatAccountScope.capture(context.read<SessionCubit>());

    return BlocProvider(
      create: (_) => ChatInboxCubit(
        context.read<ApiChatsRepository>(),
        isCurrentAccount: account.isCurrent,
        realtime: context.read<RealtimeSocketClient?>(),
      ),
      child: _ChatInboxView(onOpenConversation: onOpenConversation),
    );
  }
}

class _ChatInboxView extends StatefulWidget {
  const _ChatInboxView({required this.onOpenConversation});

  final ValueChanged<ChatConversation>? onOpenConversation;

  @override
  State<_ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<_ChatInboxView>
    with WidgetsBindingObserver, RouteAware {
  final TextEditingController _searchController = TextEditingController();
  PageRoute<dynamic>? _route;
  bool _inboxVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      entranceRouteObserver.unsubscribe(this);
      _route = route is PageRoute<dynamic> ? route : null;
      if (_route != null) entranceRouteObserver.subscribe(this, _route!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    entranceRouteObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  void _refreshOnFocus() {
    if (!mounted || !_inboxVisible) return;
    final inbox = context.read<ChatInboxCubit>();
    final unread = context.read<ChatUnreadCubit?>();
    if (!inbox.isClosed) inbox.refresh();
    unread?.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _inboxVisible) {
      _refreshOnFocus();
    }
  }

  @override
  void didPopNext() {
    _inboxVisible = true;
    // Single refresh path when returning from a conversation (replaces a
    // duplicate Navigator.then refresh that used to race this callback).
    _refreshOnFocus();
  }

  @override
  void didPushNext() {
    _inboxVisible = false;
  }

  @override
  void didPush() {
    _inboxVisible = true;
  }

  Future<void> _openConversation(ChatConversation conversation) async {
    final selected = conversation.copyWith(unreadCount: 0);

    if (widget.onOpenConversation != null) {
      widget.onOpenConversation!(selected);
      return;
    }

    final inboxCubit = context.read<ChatInboxCubit>();
    final unread = context.read<ChatUnreadCubit?>();

    await pushChatConversation(
      context,
      conversation: selected,
      onMarkedRead: () {
        if (!inboxCubit.isClosed) {
          inboxCubit.markAsRead(conversation.id);
        }
        unread?.applyConversationRead();
        unread?.refresh();
      },
      onLatestMessageChanged: (message) {
        if (inboxCubit.isClosed) return;
        inboxCubit.updateConversationPreview(conversation.id, message);
      },
    );
    // Refresh is handled by didPopNext when the conversation route is popped.
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: ChatInboxHeader(toolbarHeight: chatInboxToolbarHeight(context)),
        body: Column(
          children: [
            ChatInboxSearch(controller: _searchController),
            Expanded(
              child: ChatInboxList(onOpenConversation: _openConversation),
            ),
          ],
        ),
      ),
    );
  }
}
