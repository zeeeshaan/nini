import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notifications_cubit.dart';
import '../pages/notifications_screen.dart';

void openNotifications(BuildContext context) {
  context.read<NotificationsCubit>().search('');
  Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
}
