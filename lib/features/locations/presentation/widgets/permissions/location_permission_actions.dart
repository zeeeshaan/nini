import 'package:flutter/material.dart';
import 'package:nini/core/localization/location_strings.dart';
import 'package:nini/core/permissions/location_permission_service.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class LocationPermissionActions extends StatelessWidget {
  const LocationPermissionActions({
    super.key,
    required this.onSelected,
    required this.busy,
  });

  final ValueChanged<LocationAccessChoice> onSelected;
  final bool busy;

  static const _labels = {
    LocationAccessChoice.once: LocationStrings.allowOnce,
    LocationAccessChoice.whileUsing: LocationStrings.allowWhileUsing,
    LocationAccessChoice.always: LocationStrings.allowAlways,
    LocationAccessChoice.deny: LocationStrings.doNotAllow,
  };

  @override
  Widget build(BuildContext context) => ElevatedButtonTheme(
    data: ElevatedButtonThemeData(
      style: Theme.of(context).elevatedButtonTheme.style!
          .copyWith(shape: const WidgetStatePropertyAll(StadiumBorder())),
    ),
    child: Column(
      children: [
        for (final entry in _labels.entries)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppButton(
              label: entry.value,
              height: 42,
              onPressed: busy ? null : () => onSelected(entry.key),
            ),
          ),
      ],
    ),
  );
}
