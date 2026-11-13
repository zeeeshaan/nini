import 'package:nini/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/location_strings.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/features/profile_settings/presentation/widgets/common/settings_detail_header.dart';

import '../widgets/common/location_label_card.dart';
import '../widgets/common/location_map_preview.dart';
import '../widgets/common/saved_location_list.dart';

/// Local UI preview. Labels can be added/selected without saving to an account.
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});
  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _label = TextEditingController();
  final _locations = LocationsCubit();
  @override
  void dispose() {
    _locations.close();
    _label.dispose();
    super.dispose();
  }

  void _addLabel() {
    final name = _label.text.trim();
    if (name.isEmpty) return;
    _locations.add(name);
    _label.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LocationsCubit, LocationsState>(
        bloc: _locations,
        builder: (context, state) => PersianFeature(
          child: Scaffold(
            appBar: const SettingsDetailHeader(title: LocationStrings.title),
            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                    child: Column(
                      children: [
                        const LocationMapPreview(),
                        const SizedBox(height: 8),
                        LocationLabelCard(controller: _label, onAdd: _addLabel),
                        const SizedBox(height: 48),
                        SavedLocationList(
                          labels: _locations.state.labels,
                          selected: _locations.state.selected,
                          onSelected: (label) {
                            _locations.select(label);
                            _label.text = label;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
