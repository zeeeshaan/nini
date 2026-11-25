import 'package:nini/shared/cubits/map_tiles_cubit.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({
    super.key,
    required this.point,
    required this.onPointSelected,
    this.tileProvider,
    this.bottomOverlayHeight = 0,
  });
  final LatLng? point;
  final ValueChanged<LatLng> onPointSelected;

  /// Allows local/offline tile sources as well as network tiles.
  final TileProvider? tileProvider;
  final double bottomOverlayHeight;
  static const defaultCenter = LatLng(35.6892, 51.3890);
  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final _controller = MapController();
  bool _ready = false;
  final _tiles = MapTilesCubit();
  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready && widget.point != null && oldWidget.point != widget.point) {
      _controller.move(widget.point!, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _tiles.close();
    _controller.dispose();
    super.dispose();
  }

  void _tileError() {
    if (_tiles.state.failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tiles.state.failed) _tiles.fail();
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MapTilesCubit, MapTilesState>(
    bloc: _tiles,
    builder: (context, state) {
      final colors = Theme.of(context).colorScheme;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final sign = dark ? -1.0 : 1.0, offset = dark ? 255.0 : 0.0;
      return Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.point ?? LocationMap.defaultCenter,
              initialZoom: 13,
              backgroundColor: colors.surfaceContainerHighest,
              onMapReady: () => _ready = true,
              onTap: (_, point) => widget.onPointSelected(point),
            ),
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  .2126 * sign,
                  .7152 * sign,
                  .0722 * sign,
                  0,
                  offset,
                  .2126 * sign,
                  .7152 * sign,
                  .0722 * sign,
                  0,
                  offset,
                  .2126 * sign,
                  .7152 * sign,
                  .0722 * sign,
                  0,
                  offset,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: TileLayer(
                  key: ValueKey(_tiles.state.attempt),
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nini.nini',
                  tileProvider: widget.tileProvider,
                  errorTileCallback: (_, error, stack) => _tileError(),
                ),
              ),
              if (widget.point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.point!,
                      width: 44,
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.onSurface, width: 2),
                        ),
                        child: Center(
                          child: AppIcon(
                            AppIcons.location,
                            size: 24,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: widget.bottomOverlayHeight,
            right: 0,
            child: Material(
              color: colors.surface,
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    CreatePostStrings.mapAttribution,
                    style: AppTextStyles.smallPrint,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ),
          ),
          if (_tiles.state.failed)
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Material(
                color: colors.surface,
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          CreatePostStrings.mapUnavailable,
                          style: AppTextStyles.helper,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _tiles.retry(),
                      child: const Text(
                        CreatePostStrings.retry,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
