import 'package:nini/core/state/map_tiles_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _tiles = MapTilesCubit();
  void _tileError() {
    if (_tiles.state.failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tiles.state.failed) _tiles.fail();
    });
  }

  @override
  void dispose() {
    _tiles.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MapTilesCubit, MapTilesState>(
        bloc: _tiles,
        builder: (context, state) {
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
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                            style: AppTextStyles.metadata,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_tiles.state.failed)
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
                            style: AppTextStyles.helper,
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
        },
      );
}
