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
  bool _busy = false;
  String? _error;

  Future<void> _choose(LocationAccessChoice choice) async {
    if (_busy) return;
    if (choice == LocationAccessChoice.deny) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.request(choice);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = LocationStrings.permissionUnavailable;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
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
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 8),
                const Text(
                  LocationStrings.permissionHint,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 11),
                ),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  const AppLoader(size: 18),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textDirection: TextDirection.rtl),
                ],
                const SizedBox(height: 8),
                LocationPermissionActions(onSelected: _choose, busy: _busy),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
