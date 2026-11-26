import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';

import '../../data/native_device_permissions_repository.dart';
import '../../domain/device_permissions_repository.dart';
import '../cubit/device_permissions_cubit.dart';
import '../widgets/common/settings_page.dart';
import '../widgets/device_permissions/permissions_content.dart';

class DevicePermissionsScreen extends StatelessWidget {
  const DevicePermissionsScreen({super.key, this.repository});
  final DevicePermissionsRepository? repository;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DevicePermissionsCubit(
      repository ?? NativeDevicePermissionsRepository(),
    )..load(),
    child: const SettingsPage(
      title: ProfileSettingsStrings.devicePermissions,
      child: PermissionsContent(),
    ),
  );
}
