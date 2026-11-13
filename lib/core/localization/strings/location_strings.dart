import 'package:nini/core/localization/app_string/app_string.dart';

/// English development labels for location settings and the Home permission prompt.
abstract final class LocationStrings {
  static const title = "Locations";
  static const label = "Label";
  static const address = "…Street, London, NW1 6XE, United Kingdom";
  static const add = "Add location";
  static const mapUnavailable = "Connect to the internet to view the map.";
  static const initialLabels = [
    'Home',
    'Workplace',
    'Location 3',
    'Location 4',
  ];
  static const permissionQuestion =
      "Allow ${AppStrings.appName} to access this device location?";
  static const permissionHint = "Confirm permission in the device dialog.";
  static const allowOnce = "Allow once";
  static const allowWhileUsing = "Allow while using the app";
  static const allowAlways = "Allow all the time";
  static const doNotAllow = "Do not allow";
  static const permissionUnavailable =
      "Could not request location access. Try again.";
}
