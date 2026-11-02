import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/location_strings.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map preview only: no device-location permission or address lookup is used.
class LocationMapPreview extends StatefulWidget {
  const LocationMapPreview({super.key});
  @override
  State<LocationMapPreview> createState() => _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<LocationMapPreview> {
  bool _failed = false;
  void _tileError() {
    if (_failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(28.6139, 77.2090),
                initialZoom: 11,
                backgroundColor: colors.surfaceContainerHighest,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nini.nini',
                  errorTileCallback: (_, _, _) => _tileError(),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: colors.surface,
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      AppStrings.mapAttribution,
                      style: TextStyle(fontSize: 9),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ),
            ),
            if (_failed)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      LocationStrings.mapUnavailable,
                      style: TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
