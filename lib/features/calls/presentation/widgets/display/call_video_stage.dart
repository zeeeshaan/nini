import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';

import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/features/calls/domain/call_session.dart';
import 'package:nini/features/calls/presentation/widgets/controls/call_action_button.dart';

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
              color: AppColors.videoPlaceholder,
              child: Center(
                child: AppIcon(
                  AppIcons.profile,
                  color: AppColors.white,
                  size: 100,
                ),
              ),
            ),
          ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.videoGradientTop,
              AppColors.transparent,
              AppColors.videoGradientBottom,
            ],
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
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          width: 90,
          height: 138,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.videoPlaceholder,
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
                  child: AppIcon(
                    AppIcons.videoOff,
                    color: AppColors.white,
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
                  textAlign: TextAlign.right,
                  style: AppTextStyles.smallPrint.copyWith(
                    color: AppColors.white,
                    shadows: [Shadow(blurRadius: 4, color: AppColors.black)],
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: CallActionButton(
                  label: AppStrings.switchCamera,
                  icon: AppIcons.refresh,
                  onPressed: session.cameraEnabled ? onSwitch : null,
                  size: 44,
                  color: AppColors.videoSwitchButton,
                  foreground: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CallActionButton(
          label: AppStrings.back,
          icon: AppIcons.backRight,
          onPressed: onBack,
          color: AppColors.videoBackButton,
          foreground: AppColors.white,
        ),
      ],
    ),
  );
}
