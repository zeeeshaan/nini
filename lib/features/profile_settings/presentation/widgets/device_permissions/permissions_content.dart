import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';
import 'package:hywork/shared/widgets/skeleton/list_tile_skeleton.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';

import '../../../domain/device_permissions_repository.dart';
import '../../cubit/device_permissions_cubit.dart';
import '../common/settings_empty_state.dart';
import '../common/settings_notice.dart';

class PermissionsContent extends StatefulWidget {
  const PermissionsContent({super.key});
  @override
  State<PermissionsContent> createState() => _PermissionsContentState();
}

class _PermissionsContentState extends State<PermissionsContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<DevicePermissionsCubit>().load();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<DevicePermissionsCubit, DevicePermissionsState>(
    listenWhen: (previous, current) =>
        !previous.settingsFailed && current.settingsFailed,
    listener: (context, state) =>
        AppToast.error(context, ProfileSettingsStrings.settingsFailed),
    builder: (context, state) {
      final cubit = context.read<DevicePermissionsCubit>();
      if (state.loading && state.values.isEmpty) {
        return AppShimmer(
          child: ListView(
            children: List.generate(
              4,
              (_) => const ListTileSkeleton(showAvatar: false, animated: false),
            ),
          ),
        );
      }
      if (state.failed && state.values.isEmpty) {
        return Column(
          children: [
            Expanded(
              child: SettingsEmptyState(
                title: ProfileSettingsStrings.permissionFailed,
                message: AppStrings.retry,
                onRetry: cubit.load,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: ProfileSettingsStrings.openDeviceSettings,
                isLoading: state.opening,
                onPressed: cubit.openSettings,
              ),
            ),
          ],
        );
      }
      return ListView(
        children: [
          const SettingsNotice(text: ProfileSettingsStrings.permissionHelp),
          if (state.failed)
            TextButton(
              onPressed: cubit.load,
              child: const Text(
                AppStrings.retry,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          for (final permission in DeviceAccess.values)
            ListTile(
              title: Text(
                switch (permission) {
                  DeviceAccess.camera => AppStrings.camera,
                  DeviceAccess.microphone => ProfileSettingsStrings.microphone,
                  DeviceAccess.photos => ProfileSettingsStrings.photoLibrary,
                  DeviceAccess.location => ProfileSettingsStrings.location,
                },
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyEmphasis,
                textDirection: TextDirection.ltr,
              ),
              subtitle: Text(
                switch (state.values[permission] ??
                    DeviceAccessStatus.unknown) {
                  DeviceAccessStatus.granted => ProfileSettingsStrings.granted,
                  DeviceAccessStatus.denied => ProfileSettingsStrings.denied,
                  DeviceAccessStatus.restricted =>
                    ProfileSettingsStrings.restricted,
                  DeviceAccessStatus.limited => ProfileSettingsStrings.limited,
                  DeviceAccessStatus.unknown => ProfileSettingsStrings.unknown,
                },
                textAlign: TextAlign.right,
                style: AppTextStyles.helper,
                textDirection: TextDirection.ltr,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: ProfileSettingsStrings.openDeviceSettings,
              isLoading: state.opening,
              onPressed: cubit.openSettings,
            ),
          ),
        ],
      );
    },
  );
}
