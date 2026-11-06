import 'package:nini/features/locations/presentation/cubit/location_permission_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nini/core/assets/app_assets.dart';
import 'package:nini/core/localization/location_strings.dart';
import 'package:nini/core/permissions/location_permission_service.dart';
import 'package:nini/shared/widgets/app_loader/app_loader.dart';

import '../location_permission_actions/location_permission_actions.dart';

class LocationPermissionDialog extends StatefulWidget {
  const LocationPermissionDialog({super.key, required this.service});

  final LocationPermissionService service;

  @override
  State<LocationPermissionDialog> createState() =>
      _LocationPermissionDialogState();
}

class _LocationPermissionDialogState extends State<LocationPermissionDialog> {
  final _permission = LocationPermissionCubit();
  Future<void> _choose(LocationAccessChoice choice) async {
    if (_permission.state.busy) return;
    if (choice == LocationAccessChoice.deny) {
      Navigator.of(context).pop();
      return;
    }
    final granted = await _permission.request(widget.service, choice);
    if (mounted && granted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _permission.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LocationPermissionCubit, LocationPermissionState>(
    bloc: _permission,
    builder: (context, state) => PopScope(
      canPop: !_permission.state.busy,
      child: Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    AppAssets.locationPermission,
                    height: math.min(
                      210.0,
                      MediaQuery.sizeOf(context).height * .28,
                    ),
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    LocationStrings.permissionQuestion,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.permissionPrompt,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    LocationStrings.permissionHint,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.helper,
                  ),
                  if (_permission.state.busy) ...[
                    const SizedBox(height: 12),
                    const AppLoader(size: 18),
                  ],
                  if (_permission.state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _permission.state.error!,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                  const SizedBox(height: 8),
                  LocationPermissionActions(
                    onSelected: _choose,
                    busy: _permission.state.busy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
