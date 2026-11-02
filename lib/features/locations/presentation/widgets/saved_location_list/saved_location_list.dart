import 'package:flutter/material.dart';

class SavedLocationList extends StatelessWidget {
  const SavedLocationList({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final label in labels)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: () => onSelected(label),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerRight,
                minimumSize: const Size.fromHeight(42),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: selected == label
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
    ],
  );
}
