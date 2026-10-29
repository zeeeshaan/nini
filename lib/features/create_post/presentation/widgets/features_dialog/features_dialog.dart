import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class FeaturesDialog extends StatefulWidget {
  const FeaturesDialog({super.key, required this.initial});
  final List<PostFeature> initial;
  @override
  State<FeaturesDialog> createState() => _FeaturesDialogState();
}

class _FeaturesDialogState extends State<FeaturesDialog> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  late final List<PostFeature> _features = [...widget.initial];
  int? _editing;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  bool _add() {
    final name = _name.text.trim(), value = _value.text.trim();
    if (name.isEmpty || value.isEmpty) {
      setState(() => _error = AppStrings.featureAndValueRequired);
      return false;
    }
    if (_features.indexed.any(
      (entry) =>
          entry.$1 != _editing &&
          entry.$2.name.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _error = AppStrings.featureExists);
      return false;
    }
    setState(() {
      final feature = PostFeature(name: name, value: value);
      if (_editing == null) {
        _features.add(feature);
      } else {
        _features[_editing!] = feature;
      }
      _editing = null;
      _error = null;
      _name.clear();
      _value.clear();
    });
    return true;
  }

  void _done() {
    if ((_name.text.isNotEmpty || _value.text.isNotEmpty) && !_add()) return;
    Navigator.of(context).pop(List<PostFeature>.unmodifiable(_features));
  }

  @override
  Widget build(BuildContext context) => PostDialog(
    title: AppStrings.featuresHeading,
    icon: AppIcons.features,
    actions: PostDialogActions(onDone: _done),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .58,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.outlined(
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                tooltip: _editing == null
                    ? AppStrings.addFeature
                    : AppStrings.saveFeature,
                onPressed: _add,
                icon: AppIcon(
                  _editing == null ? AppIcons.add : AppIcons.check,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: _value,
                  label: AppStrings.featureValue,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: _name,
                  label: AppStrings.feature,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 22),
          Expanded(
            child: _features.isEmpty
                ? const Center(child: Text(AppStrings.firstFeatureHelp))
                : ListView.builder(
                    itemCount: _features.length,
                    itemBuilder: (context, index) => Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: IconButton(
                            tooltip: AppStrings.removeFeature(
                              _features[index].name,
                            ),
                            icon: const AppIcon(AppIcons.close, size: 18),
                            onPressed: () => setState(() {
                              _features.removeAt(index);
                              _editing = null;
                              _name.clear();
                              _value.clear();
                            }),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _features[index].value,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _features[index].name,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => setState(() {
                            _editing = index;
                            _name.text = _features[index].name;
                            _value.text = _features[index].value;
                          }),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
