import 'dart:async';

import 'package:nini/core/theme/app_text_styles.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/calls/data/preview_call_service.dart';
import 'package:nini/features/calls/domain/call_session.dart';
import 'package:nini/features/calls/domain/call_service.dart';
import 'package:nini/features/calls/presentation/cubit/call_cubit.dart';
import 'package:nini/features/calls/presentation/widgets/display/call_avatar.dart';
import 'package:nini/features/calls/presentation/widgets/controls/call_controls.dart';
import 'package:nini/features/calls/presentation/widgets/display/call_video_stage.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({
    super.key,
    required this.conversation,
    required this.type,
    this.service,
    this.remoteVideo,
    this.localVideo,
    this.clock,
  });
  final ChatConversation conversation;
  final CallType type;
  final CallService? service;
  final DateTime Function()? clock;
  final Widget? remoteVideo, localVideo;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        CallCubit(service ?? PreviewCallService(clock: clock), clock: clock)
          ..start(conversation.id, type),
    child: _CallView(
      conversation: conversation,
      type: type,
      preview: service == null || service is PreviewCallService,
      remoteVideo: remoteVideo,
      localVideo: localVideo,
    ),
  );
}

class _CallView extends StatefulWidget {
  const _CallView({
    required this.conversation,
    required this.type,
    required this.preview,
    this.remoteVideo,
    this.localVideo,
  });
  final ChatConversation conversation;
  final CallType type;
  final bool preview;
  final Widget? remoteVideo, localVideo;
  @override
  State<_CallView> createState() => _CallViewState();
}

class _CallViewState extends State<_CallView> {
  bool _leaving = false;
  CallCubit get _call => context.read<CallCubit>();
  void _leave() {
    if (_leaving) return;
    _leaving = true;
    unawaited(_call.end());
    Navigator.of(context).pop();
  }

  String _status(CallState state) => switch (state.session.phase) {
    CallPhase.preparing => AppStrings.callConnecting,
    CallPhase.ringing =>
      state.session.incoming
          ? AppStrings.incomingCall
          : AppStrings.outgoingCall,
    CallPhase.connecting => AppStrings.callConnecting,
    CallPhase.connected => AppStrings.chatTime(state.elapsed),
    CallPhase.ended => AppStrings.callEnded,
    CallPhase.failed => AppStrings.callFailed,
  };
  @override
  Widget build(BuildContext context) => BlocConsumer<CallCubit, CallState>(
    listenWhen: (before, after) =>
        before.controlError != after.controlError && after.controlError != null,
    listener: (context, state) => AppToast.error(context, state.controlError!),
    builder: (context, state) {
      final video = widget.type == CallType.video;
      final colors = Theme.of(context).colorScheme;
      final foreground = video ? AppColors.white : colors.onSurface;
      final controls = CallControls(
        session: state.session,
        video: video,
        busy: state.busy,
        onEnd: _leave,
        onAccept: _call.accept,
        onMessage: _leave,
        onMute: _call.toggleMicrophone,
        onSpeaker: _call.toggleSpeaker,
        onCamera: _call.toggleCamera,
        onSwitchCamera: _call.switchCamera,
      );
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _leave();
        },
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: Stack(
              children: [
                if (video)
                  Positioned.fill(
                    child: CallVideoStage(
                      avatarAsset: widget.conversation.avatarAsset,
                      remoteVideo: widget.remoteVideo,
                    ),
                  ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              SizedBox(height: video ? 156 : 56),
                              if (widget.preview)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    AppStrings.callPreview,
                                    style: AppTextStyles.helper.copyWith(
                                      color: foreground.withValues(alpha: .55),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              if (!video) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _status(state),
                                    style: AppTextStyles.largeBody.copyWith(
                                      color: foreground,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: SizedBox(
                                      height: (constraints.maxHeight * .42)
                                          .clamp(100, 340),
                                      child: CallAvatar(
                                        name: widget.conversation.name,
                                        asset:
                                            widget.conversation.avatarAsset ??
                                            'assets/img2.png',
                                        rings: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else
                                const Spacer(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    widget.conversation.name,
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.callName.copyWith(
                                      color: foreground,
                                    ),
                                  ),
                                ),
                              ),
                              if (video) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _status(state),
                                    style: AppTextStyles.comfortableBody
                                        .copyWith(color: foreground),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 30),
                              Theme(
                                data: video ? AppTheme.dark : Theme.of(context),
                                child: controls,
                              ),
                              if (video) ...[
                                const SizedBox(height: 12),
                                IconButton(
                                  tooltip: state.optionsVisible
                                      ? AppStrings.hideCallOptions
                                      : AppStrings.showCallOptions,
                                  onPressed: () => _call.toggleOptions(),
                                  icon: AppIcon(
                                    state.optionsVisible
                                        ? AppIcons.chevronDown
                                        : AppIcons.chevronUp,
                                    color: AppColors.white,
                                  ),
                                ),
                                if (state.optionsVisible)
                                  Theme(
                                    data: AppTheme.dark,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 36,
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                          AppStrings.speakerOn,
                                          textAlign: TextAlign.right,
                                        ),
                                        value: state.session.speakerEnabled,
                                        onChanged: state.busy
                                            ? null
                                            : (_) => _call.toggleSpeaker(),
                                      ),
                                    ),
                                  ),
                              ],
                              SizedBox(height: video ? 8 : 48),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (video)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: CallVideoHeader(
                        session: state.session,
                        onBack: _leave,
                        onSwitch: _call.switchCamera,
                        localVideo: widget.localVideo,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
