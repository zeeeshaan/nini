import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/calls/domain/models/call_session.dart';
import 'package:nini/features/calls/presentation/widgets/call_action_button.dart';

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!incoming)
            CallActionButton(
              label: AppStrings.returnToChat,
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: onMessage,
            ),
          if (!incoming)
            CallActionButton(
              label: session.microphoneMuted
                  ? AppStrings.unmuteCall
                  : AppStrings.muteCall,
              selected: session.microphoneMuted,
              icon: session.microphoneMuted
                  ? Icons.mic_off_outlined
                  : Icons.mic_none,
              onPressed: connected ? onMute : null,
            ),
          CallActionButton(
            label: incoming ? AppStrings.declineCall : AppStrings.endCall,
            icon: Icons.call_end_rounded,
            onPressed: onEnd,
            size: incoming ? 54 : 56,
            color: const Color(0xFFFF454D),
            foreground: Colors.white,
          ),
          if (incoming) ...[
            CallActionButton(
              label: AppStrings.answerCall,
              icon: Icons.call_rounded,
              onPressed: busy ? null : onAccept,
              size: 54,
              color: const Color(0xFF31EF73),
              foreground: Colors.white,
            ),
            CallActionButton(
              label: AppStrings.returnToChat,
              icon: Icons.chat_bubble_rounded,
              onPressed: onMessage,
              size: 54,
              color: const Color(0xFFFFD447),
              foreground: Colors.white,
            ),
          ] else ...[
            if (video)
              CallActionButton(
                label: session.cameraEnabled
                    ? AppStrings.turnCameraOff
                    : AppStrings.turnCameraOn,
                icon: session.cameraEnabled
                    ? Icons.videocam_outlined
                    : Icons.videocam_off_outlined,
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
                  ? Icons.cameraswitch_outlined
                  : Icons.volume_up_outlined,
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
