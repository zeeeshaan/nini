import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/home/presentation/widgets/common/home_notification_button.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:hywork/features/notifications/presentation/helpers/open_notifications.dart';

class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
    child: Row(
      children: [
        const SizedBox(width: 98),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              HomeStrings.brand,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeBrand,
            ),
          ),
        ),
        const SizedBox(width: 8),
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) => HomeNotificationButton(
            unreadCount: state.badgeCount,
            onPressed: () => openNotifications(context),
          ),
        ),
      ],
    ),
  );
}
