import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/notification_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class NotificationHeader extends StatelessWidget {
  const NotificationHeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 4, 16, 14),
    child: Row(
      textDirection: TextDirection.ltr,
      children: [
        const SizedBox(width: 8),
        BlocBuilder<NotificationsCubit, NotificationsState>(
          buildWhen: (previous, current) =>
              previous.unreadCount != current.unreadCount,
          builder: (context, state) => _HeaderBell(count: state.badgeCount),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            NotificationStrings.title,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: AppTextStyles.screenTitle,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: AppStrings.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: const AppIcon(AppIcons.backRight, size: 24),
        ),
      ],
    ),
  );
}

class _HeaderBell extends StatelessWidget {
  const _HeaderBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const AppIcon(AppIcons.notifications, size: 26),
        if (count > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.notificationBadge,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppStrings.persianDigits(count > 99 ? '99+' : count),
                textAlign: TextAlign.center,
                style: AppTextStyles.smallPrintBold.copyWith(
                  color: AppColors.white,
                  fontSize: 10,
                ),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
      ],
    ),
  );
}
