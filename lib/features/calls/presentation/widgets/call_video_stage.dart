import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/calls/domain/models/call_session.dart';
import 'package:nini/features/calls/presentation/widgets/call_action_button.dart';

/// Existing app images stand in for video during the UI-only preview.
class CallVideoStage extends StatelessWidget {
  const CallVideoStage({super.key, this.avatarAsset, this.remoteVideo});
  final String? avatarAsset;
  final Widget? remoteVideo;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      remoteVideo ??
          Image.asset(
            avatarAsset ?? 'assets/img2.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFF333333),
              child: Center(
                child: Icon(Icons.person, color: Colors.white, size: 100),
              ),
            ),
          ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x44000000), Colors.transparent, Color(0xCC000000)],
            stops: [0, .5, 1],
          ),
        ),
      ),
    ],
  );
}

/// Placed above the scrolling controls so both header actions remain tappable.
class CallVideoHeader extends StatelessWidget {
  const CallVideoHeader({
    super.key,
    required this.session,
    required this.onBack,
    required this.onSwitch,
    this.localVideo,
  });
  final CallSession session;
  final VoidCallback onBack, onSwitch;
  final Widget? localVideo;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CallActionButton(
          label: AppStrings.back,
          icon: Icons.chevron_left,
          onPressed: onBack,
          color: const Color(0x55000000),
          foreground: Colors.white,
        ),
        const Spacer(),
        Container(
          width: 90,
          height: 138,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (session.cameraEnabled)
                localVideo ??
                    Image.asset(
                      session.frontCamera
                          ? 'assets/img3.png'
                          : 'assets/img1.png',
                      fit: BoxFit.cover,
                    ),
              if (!session.cameraEnabled)
                const Center(
                  child: Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              Positioned(
                left: 4,
                top: 4,
                right: 4,
                child: Text(
                  session.cameraEnabled
                      ? (session.frontCamera
                            ? AppStrings.frontCamera
                            : AppStrings.rearCamera)
                      : AppStrings.cameraOff,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: CallActionButton(
                  label: AppStrings.switchCamera,
                  icon: Icons.cameraswitch_outlined,
                  onPressed: session.cameraEnabled ? onSwitch : null,
                  size: 44,
                  color: const Color(0x66000000),
                  foreground: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
