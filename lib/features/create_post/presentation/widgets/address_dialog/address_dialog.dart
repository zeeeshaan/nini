import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/address_dialog/location_map.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class AddressDialog extends StatefulWidget {
  const AddressDialog({
    super.key,
    this.initial,
    this.saved = const [],
    this.tileProvider,
    this.doneLabel = AppStrings.done,
  });
  final PostAddress? initial;
  final List<PostAddress> saved;
  final TileProvider? tileProvider;
  final String doneLabel;
  @override
  State<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  late final _text = TextEditingController(text: widget.initial?.address ?? '');
  late final List<PostAddress> _saved = [...widget.saved];
  late PostAddress? _selected = widget.initial;
  late LatLng? _point = widget.initial == null
      ? null
      : LatLng(widget.initial!.latitude, widget.initial!.longitude);
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  PostAddress? _add() {
    if (_text.text.trim().isEmpty || _point == null) {
      setState(() => _error = AppStrings.addressPinRequired);
      return null;
    }
    final location = PostAddress(
      address: _text.text.trim(),
      latitude: _point!.latitude,
      longitude: _point!.longitude,
    );
    setState(() {
      final index = _saved.indexWhere(
        (entry) =>
            entry.address.toLowerCase() == location.address.toLowerCase(),
      );
      if (index < 0) {
        _saved.add(location);
      } else {
        _saved[index] = location;
      }
      _selected = location;
      _error = null;
    });
    return location;
  }

  void _done() {
    // Editing the text or pin must never silently save the previous selection.
    final selected = _selected;
    if (selected == null ||
        _text.text.trim() != selected.address ||
        _point?.latitude != selected.latitude ||
        _point?.longitude != selected.longitude) {
      if (_add() == null) return;
    }
    Navigator.of(context).pop(
      AddressSelection(selected: _selected!, saved: List.unmodifiable(_saved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).top;
    final height = available * .92;
    final mapHeight =
        height * (MediaQuery.viewInsetsOf(context).bottom > 0 ? .20 : .40);
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mapHeight,
            child: LocationMap(
              point: _point,
              tileProvider: widget.tileProvider,
              bottomOverlayHeight: 24,
              onPointSelected: (point) => setState(() {
                _point = point;
                _error = null;
              }),
            ),
          ),
          Positioned(
            top: mapHeight - 24,
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: PostDialog(
                title: AppStrings.address,
                icon: AppIcons.map,
                actions: PostDialogActions(
                  onDone: _done,
                  doneLabel: widget.doneLabel,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    AppTextField(
                      controller: _text,
                      label: AppStrings.address,
                      hint: AppStrings.enterFullAddress,
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      prefixIcon: IconButton(
                        tooltip: AppStrings.addAddress,
                        onPressed: _add,
                        icon: const AppIcon(AppIcons.add, size: 22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _point == null
                          ? AppStrings.chooseMapLocation
                          : AppStrings.mapPin(
                              _point!.latitude,
                              _point!.longitude,
                            ),
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!),
                      ),
                    const SizedBox(height: 20),
                    for (final address in _saved)
                      Column(
                        children: [
                          PostChoiceTile(
                            label: address.address,
                            selected: identical(_selected, address),
                            onTap: () => setState(() {
                              _selected = address;
                              _point = LatLng(
                                address.latitude,
                                address.longitude,
                              );
                              _text.text = address.address;
                              _error = null;
                            }),
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
