import 'package:hywork/features/create_post/cubit/post_address_cubit.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/models/post_options.dart';
import 'package:hywork/features/create_post/widgets/address_dialog/location_map.dart';
import 'package:hywork/features/create_post/widgets/address_dialog/manual_address_dialog.dart';
import 'package:hywork/features/create_post/widgets/post_dialog/post_dialog.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_textfield/app_text_field.dart';

class AddressDialog extends StatefulWidget {
  const AddressDialog({
    super.key,
    this.initial,
    this.saved = const [],
    this.tileProvider,
    this.doneLabel = CreatePostStrings.done,
    this.allowManualEntry = false,
  });
  final PostAddress? initial;
  final List<PostAddress> saved;
  final TileProvider? tileProvider;
  final String doneLabel;
  final bool allowManualEntry;
  @override
  State<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  late final _text = TextEditingController(text: widget.initial?.address ?? '');
  final _addressFocus = FocusNode();
  late final _draft = PostAddressCubit(widget.initial, widget.saved);
  String? _autoFilledAddress;
  @override
  void dispose() {
    _draft.close();
    _addressFocus.dispose();
    _text.dispose();
    super.dispose();
  }

  PostAddress? _add() {
    final address = _draft.save(
      _text.text,
      allowWithoutPin: widget.allowManualEntry,
    );
    if (_text.text.trim().isEmpty) {
      _addressFocus.requestFocus();
    } else {
      // Reveal the map if the remaining step is choosing the pin.
      _addressFocus.unfocus();
    }
    return address;
  }

  void _showKeyboard() {
    _addressFocus.requestFocus();
    // Reopen the input connection even when the field already has focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _addressFocus.hasFocus) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
    });
  }

  Future<void> _enterManually() async {
    _draft.clearError();
    final selected = _draft.state.selected;
    final point = _draft.state.point;
    final samePoint =
        selected?.latitude == point?.latitude &&
        selected?.longitude == point?.longitude;
    final address = await showPostDialog<PostAddress>(
      context,
      ManualAddressDialog(
        initial: PostAddress(
          address: _text.text,
          latitude: point?.latitude,
          longitude: point?.longitude,
          city: samePoint ? selected?.city ?? '' : '',
          province: samePoint ? selected?.province ?? '' : '',
          postalCode: samePoint ? selected?.postalCode ?? '' : '',
          buildingNumber: samePoint ? selected?.buildingNumber ?? '' : '',
          unitNumber: samePoint ? selected?.unitNumber ?? '' : '',
        ),
      ),
    );
    if (!mounted || address == null) return;
    _autoFilledAddress = null;
    _draft.select(address);
    _draft.save(address.address, allowWithoutPin: true);
    _text.value = TextEditingValue(
      text: address.address,
      selection: TextSelection.collapsed(offset: address.address.length),
    );
  }

  Future<void> _selectPoint(LatLng point) async {
    _addressFocus.unfocus();
    if (_autoFilledAddress != null && _text.text == _autoFilledAddress) {
      _text.clear();
    }
    _autoFilledAddress = null;
    final address = await _draft.resolvePin(
      point,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted || address == null) return;
    _autoFilledAddress = address;
    _text.value = TextEditingValue(
      text: address,
      selection: TextSelection.collapsed(offset: address.length),
    );
  }

  void _done() {
    if (_draft.state.resolvingAddress) return;
    // Editing the text or pin must never silently save the previous selection.
    final selected = _draft.state.selected;
    if (selected == null ||
        _text.text.trim() != selected.address ||
        _draft.state.point?.latitude != selected.latitude ||
        _draft.state.point?.longitude != selected.longitude) {
      if (_add() == null) return;
    }
    Navigator.of(context).pop(
      AddressSelection(
        selected: _draft.state.selected!,
        saved: List.unmodifiable(_draft.state.saved),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostAddressCubit, PostAddressState>(
        bloc: _draft,
        builder: (context, state) {
          final available =
              MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom -
              MediaQuery.paddingOf(context).top;
          final height = available * .92;
          final mapHeight =
              height *
              (MediaQuery.viewInsetsOf(context).bottom > 0 ? .20 : .40);
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
                    point: _draft.state.point,
                    tileProvider: widget.tileProvider,
                    bottomOverlayHeight: 24,
                    onPointSelected: _selectPoint,
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
                      title: CreatePostStrings.address,
                      icon: AppIcons.map,
                      actions: PostDialogActions(
                        onDone: state.resolvingAddress ? null : _done,
                        doneLabel: widget.doneLabel,
                      ),
                      // PostDialog already scrolls. One scrollable lets the
                      // text field reveal itself when the keyboard opens.
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _text,
                            focusNode: _addressFocus,
                            label: CreatePostStrings.address,
                            hint: CreatePostStrings.enterFullAddress,
                            maxLines: 2,
                            readOnly: widget.allowManualEntry,
                            keyboardType: TextInputType.streetAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addressFocus.unfocus(),
                            onTap: widget.allowManualEntry
                                ? _enterManually
                                : _showKeyboard,
                            onChanged: (_) {
                              _autoFilledAddress = null;
                              _draft.clearError();
                            },
                            textAlign: TextAlign.right,
                            prefixIcon: IconButton(
                              tooltip: CreatePostStrings.addAddress,
                              onPressed: state.resolvingAddress ? null : _add,
                              icon: const AppIcon(AppIcons.add, size: 22),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (state.resolvingAddress)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Semantics(
                                liveRegion: true,
                                child: const Text(
                                  CreatePostStrings.findingAddress,
                                  style: AppTextStyles.helper,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            ),
                          Text(
                            _draft.state.point == null
                                ? CreatePostStrings.chooseMapLocation
                                : CreatePostStrings.mapPin(
                                    _draft.state.point!.latitude,
                                    _draft.state.point!.longitude,
                                  ),
                            style: AppTextStyles.helper,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
                          ),
                          if (_draft.state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _draft.state.error!,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          for (final address in _draft.state.saved)
                            Column(
                              children: [
                                PostChoiceTile(
                                  label: address.address,
                                  selected: identical(
                                    _draft.state.selected,
                                    address,
                                  ),
                                  onTap: () {
                                    _addressFocus.unfocus();
                                    _draft.select(address);
                                    _text.text = address.address;
                                  },
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
        },
      );
}
