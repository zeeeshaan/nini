import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/cubit/voice_playback_cubit.dart';

class ChatVoicePlayer extends StatelessWidget {
  const ChatVoicePlayer({
    super.key,
    required this.id,
    required this.path,
    required this.duration,
    this.color,
  });
  final String id, path;
  final Duration duration;
  final Color? color;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<VoicePlaybackCubit, VoicePlaybackState>(
    buildWhen: (before, after) => before.id == id || after.id == id,
    builder: (context, state) {
      final active = state.id == id, playing = active && state.audio.playing;
      final total = active && state.audio.duration > Duration.zero
          ? state.audio.duration
          : duration;
      final maximum = total.inMilliseconds.toDouble().clamp(
        1.0,
        double.infinity,
      );
      final position = active
          ? state.audio.position.inMilliseconds.toDouble().clamp(0.0, maximum)
          : 0.0;
      final foreground = color ?? Theme.of(context).colorScheme.onSurface;
      return SizedBox(
        width: 270,
        child: Row(
          children: [
            IconButton(
              tooltip: playing ? AppStrings.pauseVoice : AppStrings.playVoice,
              onPressed: active && state.loading
                  ? null
                  : () => context.read<VoicePlaybackCubit>().toggle(id, path),
              icon: active && state.loading
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  : AppIcon(
                      playing ? AppIcons.pause : AppIcons.play,
                      color: foreground,
                    ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                      activeTrackColor: foreground,
                      thumbColor: foreground,
                      inactiveTrackColor: foreground.withValues(alpha: .25),
                      disabledActiveTrackColor: foreground.withValues(
                        alpha: .6,
                      ),
                      disabledInactiveTrackColor: foreground.withValues(
                        alpha: .3,
                      ),
                      disabledThumbColor: foreground.withValues(alpha: .6),
                    ),
                    child: Slider(
                      value: position,
                      max: maximum,
                      onChanged: active && !state.loading
                          ? (value) => context.read<VoicePlaybackCubit>().seek(
                              Duration(milliseconds: value.round()),
                            )
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      AppStrings.chatTime(
                        active && state.audio.playing
                            ? state.audio.position
                            : total,
                      ),
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.helper.copyWith(color: foreground),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
