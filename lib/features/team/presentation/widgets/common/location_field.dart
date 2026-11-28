import 'package:flutter/material.dart';

import 'package:hywork/features/create_post/models/post_options.dart';
import 'package:hywork/features/create_post/widgets/address_dialog/address_dialog.dart';
import 'package:hywork/features/create_post/widgets/post_dialog/post_dialog.dart';
import 'package:hywork/features/create_post/widgets/post_form_option_tile/post_form_option_tile.dart';

class TeamLocationField extends StatelessWidget {
  const TeamLocationField({
    super.key,
    required this.locations,
    required this.onChanged,
  });

  final List<PostAddress> locations;
  final ValueChanged<List<PostAddress>> onChanged;

  Future<void> _selectLocation(BuildContext context) async {
    final result = await showPostDialog<AddressSelection>(
      context,
      AddressDialog(
        allowManualEntry: true,
        initial: locations.isEmpty ? null : locations.last,
        saved: locations,
      ),
    );

    if (!context.mounted || result == null) return;

    final updatedLocations = [...result.saved];
    final selected = result.selected;

    final alreadyExists = updatedLocations.any(
      (location) =>
          location.address == selected.address &&
          location.latitude == selected.latitude &&
          location.longitude == selected.longitude,
    );

    if (!alreadyExists) {
      updatedLocations.add(selected);
    }

    onChanged(List.unmodifiable(updatedLocations));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PostFormOptionTile(
          label: 'Project location',
          value: locations.isEmpty ? null : locations.first.address,
          trailing: const Icon(Icons.location_on_outlined),
          onTap: () => _selectLocation(context),
        ),

        // Display additional selected addresses.
        if (locations.length > 1) ...[
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final location in locations.skip(1))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            location.address,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
