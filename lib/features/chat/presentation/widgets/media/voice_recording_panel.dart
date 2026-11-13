import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/chat/presentation/cubit/voice_recording_cubit.dart';
import 'package:nini/features/chat/presentation/widgets/media/chat_voice_player.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class VoiceRecordingPanel extends StatelessWidget {
  const VoiceRecordingPanel({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onStop,
    required this.onSend,
    this.sending = false,
  });
  final VoiceRecordingState state;
  final VoidCallback onCancel, onStop, onSend;
  final bool sending;
  @override
  Widget build(BuildContext context) {
    final preview = state.phase == VoiceRecordingPhase.preview;
    final busy =
        state.phase == VoiceRecordingPhase.starting ||
        state.phase == VoiceRecordingPhase.processing ||
        sending;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AppIcon(
                  AppIcons.microphone,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    preview
                        ? AppStrings.recordingPreview
                        : AppStrings.recording,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                Text(
                  AppStrings.chatTime(state.elapsed),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            if (preview)
              ChatVoicePlayer(
                id: 'preview:${state.path}',
                path: state.path!,
                duration: state.elapsed,
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.cancel,
                    height: 42,
                    variant: AppButtonVariant.outlined,
                    onPressed: busy ? null : onCancel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: preview
                        ? AppStrings.sendMessage
                        : AppStrings.stopRecording,
                    height: 42,
                    isLoading: busy,
                    onPressed: busy
                        ? null
                        : preview
                        ? onSend
                        : onStop,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
