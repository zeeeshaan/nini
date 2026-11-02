import 'package:flutter/material.dart';
import 'package:nini/core/localization/location_strings.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/shared/widgets/settings_detail_header/settings_detail_header.dart';

import '../widgets/location_label_card/location_label_card.dart';
import '../widgets/location_map_preview/location_map_preview.dart';
import '../widgets/saved_location_list/saved_location_list.dart';

/// Local UI preview. Labels can be added/selected without saving to an account.
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});
  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _label = TextEditingController();
  final _labels = List<String>.of(LocationStrings.initialLabels);
  String? _selected;
  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _addLabel() {
    final name = _label.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_labels.contains(name)) _labels.add(name);
      _selected = name;
    });
    _label.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Scaffold(
      appBar: const SettingsDetailHeader(title: LocationStrings.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
              child: Column(
                children: [
                  const LocationMapPreview(),
                  const SizedBox(height: 8),
                  LocationLabelCard(controller: _label, onAdd: _addLabel),
                  const SizedBox(height: 48),
                  SavedLocationList(
                    labels: _labels,
                    selected: _selected,
                    onSelected: (label) {
                      setState(() => _selected = label);
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
  );
}
