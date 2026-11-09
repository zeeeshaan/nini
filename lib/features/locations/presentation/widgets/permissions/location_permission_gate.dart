import 'package:flutter/material.dart';

import '../../helpers/show_location_permission_prompt.dart';

/// Shows the optional location prompt once on entry after confirming OTP.
class LocationPermissionGate extends StatefulWidget {
  const LocationPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLocationPermissionPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
