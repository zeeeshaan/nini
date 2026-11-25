import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nini/core/constants/app_icons/app_icons.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/features/calls/domain/call_session.dart';
import 'package:nini/features/calls/presentation/widgets/controls/call_action_button.dart';

class CallControls extends StatelessWidget {
  const CallControls({
    super.key,
    required this.session,
    required this.video,
    required this.busy,
    required this.onEnd,
    required this.onAccept,
    required this.onMessage,
    required this.onMute,
    required this.onSpeaker,
    required this.onCamera,
    required this.onSwitchCamera,
  });
  final CallSession session;
  final bool video, busy;
  final VoidCallback onEnd,
      onAccept,
      onMessage,
      onMute,
      onSpeaker,
      onCamera,
      onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    final incoming = session.phase == CallPhase.ringing && session.incoming;
    final connected = session.phase == CallPhase.connected && !busy;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 12,
        children: [
          if (!incoming)
            CallActionButton(
              label: AppStrings.returnToChat,
              icon: AppIcons.chat,
              onPressed: onMessage,
            ),
          if (!incoming)
            CallActionButton(
              label: session.microphoneMuted
                  ? AppStrings.unmuteCall
                  : AppStrings.muteCall,
              selected: session.microphoneMuted,
              icon: session.microphoneMuted
                  ? AppIcons.microphoneOff
                  : AppIcons.microphone,
              onPressed: connected ? onMute : null,
            ),
          CallActionButton(
            label: incoming ? AppStrings.declineCall : AppStrings.endCall,
            icon: AppIcons.phone,
            rotation: math.pi * .75,
            onPressed: onEnd,
            size: incoming ? 54 : 56,
            color: AppColors.callEnd,
            foreground: AppColors.white,
          ),
          if (incoming) ...[
            CallActionButton(
              label: AppStrings.answerCall,
              icon: AppIcons.phone,
              onPressed: busy ? null : onAccept,
              size: 54,
              color: AppColors.callAccept,
              foreground: AppColors.white,
            ),
            CallActionButton(
              label: AppStrings.returnToChat,
              icon: AppIcons.chat,
              onPressed: onMessage,
              size: 54,
              color: AppColors.callMessage,
              foreground: AppColors.white,
            ),
          ] else ...[
            if (video)
              CallActionButton(
                label: session.cameraEnabled
                    ? AppStrings.turnCameraOff
                    : AppStrings.turnCameraOn,
                icon: session.cameraEnabled
                    ? AppIcons.video
                    : AppIcons.videoOff,
                selected: !session.cameraEnabled,
                onPressed: connected ? onCamera : null,
              ),
            CallActionButton(
              label: video
                  ? AppStrings.switchCamera
                  : (session.speakerEnabled
                        ? AppStrings.speakerOff
                        : AppStrings.speakerOn),
              icon: video
                  ? AppIcons.refresh
                  : (session.speakerEnabled
                        ? AppIcons.speaker
                        : AppIcons.speakerQuiet),
              selected: !video && session.speakerEnabled,
              onPressed: connected
                  ? (video ? onSwitchCamera : onSpeaker)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
