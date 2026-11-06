import 'package:nini/features/create_post/presentation/cubit/post_address_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/create_post_strings.dart';
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
    this.doneLabel = CreatePostStrings.done,
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
  late final _draft = PostAddressCubit(widget.initial, widget.saved);
  @override
  void dispose() {
    _draft.close();
    _text.dispose();
    super.dispose();
  }

  PostAddress? _add() => _draft.save(_text.text);

  void _done() {
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
                    onPointSelected: _draft.pin,
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
                        onDone: _done,
                        doneLabel: widget.doneLabel,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          AppTextField(
                            controller: _text,
                            label: CreatePostStrings.address,
                            hint: CreatePostStrings.enterFullAddress,
                            maxLines: 2,
                            textAlign: TextAlign.right,
                            prefixIcon: IconButton(
                              tooltip: CreatePostStrings.addAddress,
                              onPressed: _add,
                              icon: const AppIcon(AppIcons.add, size: 22),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _draft.state.point == null
                                ? CreatePostStrings.chooseMapLocation
                                : CreatePostStrings.mapPin(
                                    _draft.state.point!.latitude,
                                    _draft.state.point!.longitude,
                                  ),
                            style: AppTextStyles.helper,
                          ),
                          if (_draft.state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_draft.state.error!),
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
