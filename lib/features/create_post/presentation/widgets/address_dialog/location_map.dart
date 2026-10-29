import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/icons/app_icons.dart';
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
  bool _ready = false, _failed = false;
  int _retry = 0;
  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready && widget.point != null && oldWidget.point != widget.point) {
      _controller.move(widget.point!, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tileError() {
    if (_failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                key: ValueKey(_retry),
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
                  AppStrings.mapAttribution,
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
        if (_failed)
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
                        AppStrings.mapUnavailable,
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _failed = false;
                      _retry++;
                    }),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
