import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/models/chat_conversation.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_inbox_cubit.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/chat/presentation/pages/conversation_screen.dart';
import 'package:hywork/features/chat/presentation/widgets/inbox/chat_conversation_tile.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';
import 'package:hywork/shared/widgets/skeleton/list_tile_skeleton.dart';

enum _InboxMenuAction { toggleUnread, markAllRead }

class ChatInboxScreen extends StatelessWidget {
  const ChatInboxScreen({super.key, this.onOpenConversation});

  final ValueChanged<ChatConversation>? onOpenConversation;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>();
    final initial = session.state;
    bool current() =>
        !session.isClosed &&
        session.state.status == SessionStatus.authenticated &&
        !session.state.isLoggingOut &&
        !session.state.logoutCleanupRequired &&
        session.state.userId != null &&
        session.state.userId == initial.userId &&
        session.state.accountRevision == initial.accountRevision;

    return BlocProvider(
      create: (_) => ChatInboxCubit(
        context.read<ApiChatsRepository>(),
        isCurrentAccount: current,
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

  void _openConversation(ChatConversation conversation) {
    final inboxCubit = context.read<ChatInboxCubit>();
    final unread = context.read<ChatUnreadCubit?>();
    final chats = context.read<ApiChatsRepository>();
    final profiles = context.read<ApiPublicProfileRepository?>();
    final session = context.read<SessionCubit>();
    final initial = session.state;
    bool current() =>
        !session.isClosed &&
        session.state.status == SessionStatus.authenticated &&
        !session.state.isLoggingOut &&
        !session.state.logoutCleanupRequired &&
        session.state.userId != null &&
        session.state.userId == initial.userId &&
        session.state.accountRevision == initial.accountRevision;

    final selectedConversation = conversation.copyWith(unreadCount: 0);

    if (widget.onOpenConversation != null) {
      widget.onOpenConversation!(selectedConversation);
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(
              conversation: selectedConversation,
              repository: chats,
              profiles: profiles,
              isCurrentAccount: current,
              currentUserId: () => current() ? session.state.userId : null,
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
            ),
          ),
        )
        .then((_) {
          if (mounted && !inboxCubit.isClosed) inboxCubit.refresh();
          unread?.refresh();
        });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: (MediaQuery.textScalerOf(context).scale(27) * 1.4 + 8)
              .clamp(72, double.infinity),
          centerTitle: false,
          titleSpacing: 6,
          title: Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppStrings.chat,
              style: AppTextStyles.inboxTitle.copyWith(color: colors.onSurface),
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ),
          actions: [
            BlocBuilder<ChatInboxCubit, ChatInboxState>(
              builder: (context, state) {
                return PopupMenuButton<_InboxMenuAction>(
                  tooltip: AppStrings.chatOptions,
                  icon: const AppIcon(AppIcons.more, size: 24),
                  onSelected: (action) {
                    final cubit = context.read<ChatInboxCubit>();

                    switch (action) {
                      case _InboxMenuAction.toggleUnread:
                        cubit.toggleUnreadFilter();
                        break;
                      case _InboxMenuAction.markAllRead:
                        cubit.markAllAsRead();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _InboxMenuAction.toggleUnread,
                      child: Text(
                        state.unreadOnly
                            ? AppStrings.showAllChats
                            : AppStrings.unreadChats,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    PopupMenuItem(
                      value: _InboxMenuAction.markAllRead,
                      enabled: state.hasUnread,
                      child: const Text(
                        AppStrings.markAllRead,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),

            IconButton(
              tooltip: AppStrings.back,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const AppIcon(AppIcons.backRight, size: 26),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 15),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    context.read<ChatInboxCubit>().search(value);
                  },
                  style: AppTextStyles.comfortableBody.copyWith(
                    color: colors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.search,
                    hintStyle: AppTextStyles.comfortableBody.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.38),
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 13),
                      child: AppIcon(AppIcons.search, size: 24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: colors.onSurface, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: colors.onSurface,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<ChatInboxCubit, ChatInboxState>(
                builder: (context, state) {
                  final inbox = context.read<ChatInboxCubit>();
                  final loading = state.loading && state.conversations.isEmpty;
                  final chats = state.filteredConversations;

                  if (loading) {
                    return AppShimmer(
                      child: ListView.builder(
                        itemCount: 6,
                        itemBuilder: (_, index) =>
                            const ListTileSkeleton(animated: false),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: inbox.refresh,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.axis == Axis.vertical &&
                            notification.metrics.extentAfter < 400 &&
                            state.hasMore &&
                            !state.loadingMore &&
                            state.error == null) {
                          inbox.loadMore();
                        }
                        return false;
                      },
                      child: state.error != null && state.conversations.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                const SizedBox(height: 80),
                                Text(
                                  state.error ?? ChatStrings.loadFailed,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: inbox.retry,
                                  child: const Text(AppStrings.retry),
                                ),
                              ],
                            )
                          : chats.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                const SizedBox(height: 80),
                                const AppIcon(AppIcons.search, size: 32),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    state.unreadOnly
                                        ? AppStrings.noUnreadChats
                                        : AppStrings.noChatsFound,
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.comfortableBody
                                        .copyWith(color: colors.onSurface),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 24,
                              ),
                              itemCount:
                                  chats.length + (state.loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= chats.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final conversation = chats[index];
                                return ChatConversationTile(
                                  key: ValueKey(conversation.id),
                                  conversation: conversation,
                                  onTap: () => _openConversation(conversation),
                                );
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
