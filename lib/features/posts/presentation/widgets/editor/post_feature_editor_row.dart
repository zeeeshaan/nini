import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';

class PostFeatureEditorRow extends StatelessWidget {
  const PostFeatureEditorRow({
    super.key,
    required this.name,
    required this.value,
    required this.onNameChanged,
    required this.onValueChanged,
    required this.onRemove,
  });
  final String name, value;
  final ValueChanged<String> onNameChanged, onValueChanged;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: ProfilePostStrings.featureName,
                  ),
                  onChanged: onNameChanged,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
            IconButton(
              tooltip: ProfilePostStrings.removeFeature,
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            initialValue: value,
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.featureValue,
            ),
            onChanged: onValueChanged,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    ),
  );
}
