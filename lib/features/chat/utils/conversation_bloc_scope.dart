import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/services/device_voice_recorder.dart';
import 'package:hywork/features/chat/services/just_audio_chat_player.dart';
import 'package:hywork/features/chat/services/local_chat_media_store.dart';
import 'package:hywork/features/chat/services/chat_audio_player.dart';
import 'package:hywork/features/chat/services/chat_media_store.dart';
import 'package:hywork/features/chat/services/voice_recorder.dart';
import 'package:hywork/features/chat/cubit/conversation_cubit.dart';
import 'package:hywork/features/chat/cubit/voice_playback_cubit.dart';
import 'package:hywork/features/chat/cubit/voice_recording_cubit.dart';
import 'package:hywork/features/chat/utils/chat_account_scope.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';

/// Route-scoped BLoC wiring for a peer conversation.
///
/// Reuses account-scoped [ApiChatsRepository], [ApiPublicProfileRepository] and
/// [RealtimeSocketClient] from the tree. Creates conversation, recording and
/// playback Cubits for this route only (disposed with the route).
class ConversationBlocScope extends StatelessWidget {
  const ConversationBlocScope({
    super.key,
    required this.conversationId,
    required this.child,
    this.repository,
    this.mediaStore,
    this.voiceRecorder,
    this.audioPlayer,
    this.recordingClock,
    this.profiles,
    this.isCurrentAccount,
    this.currentUserId,
    this.onMarkedRead,
  });

  final String conversationId;
  final Widget child;
  final ApiChatsRepository? repository;
  final ChatMediaStore? mediaStore;
  final VoiceRecorder? voiceRecorder;
  final ChatAudioPlayer? audioPlayer;
  final DateTime Function()? recordingClock;
  final ApiPublicProfileRepository? profiles;
  final bool Function()? isCurrentAccount;
  final String? Function()? currentUserId;
  final VoidCallback? onMarkedRead;

  @override
  Widget build(BuildContext context) {
    final account = captureChatAccountScope(context.read<SessionCubit?>());

    bool current() {
      if (isCurrentAccount != null) return isCurrentAccount!();
      return account?.isCurrent() ?? false;
    }

    String? userId() {
      if (currentUserId != null) return currentUserId!();
      return account?.currentUserId();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ConversationCubit(
            conversationId: conversationId,
            repository: repository ?? context.read<ApiChatsRepository>(),
            mediaStore: mediaStore ?? LocalChatMediaStore(),
            profiles: profiles ?? context.read<ApiPublicProfileRepository?>(),
            isCurrentAccount: current,
            currentUserId: userId,
            onMarkedRead: onMarkedRead,
            realtime: context.read<RealtimeSocketClient?>(),
          ),
        ),
        BlocProvider(
          create: (_) => VoiceRecordingCubit(
            voiceRecorder ?? DeviceVoiceRecorder(),
            clock: recordingClock,
          ),
        ),
        BlocProvider(
          create: (_) =>
              VoicePlaybackCubit(audioPlayer ?? JustAudioChatPlayer()),
        ),
      ],
      child: child,
    );
  }
}
