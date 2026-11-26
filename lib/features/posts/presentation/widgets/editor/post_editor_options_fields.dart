import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/create_post/domain/models/post_draft.dart';
import 'package:hywork/features/create_post/presentation/cubit/create_post_cubit.dart';

class PostEditorOptionsFields extends StatelessWidget {
  const PostEditorOptionsFields({super.key, this.backendData, this.onTouched});
  final Map<String, dynamic>? backendData;
  final ValueChanged<String>? onTouched;
  @override
  Widget build(BuildContext context) {
    final editor = context.read<CreatePostCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownButtonFormField<PreparationTime>(
            initialValue: backendData == null
                ? editor.state.preparationTime
                : PreparationTime.values
                      .where((v) => v.label == backendData!['preparationTime'])
                      .firstOrNull,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.preparation,
            ),
            items: [
              for (final value in PreparationTime.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    value.days == null
                        ? ProfilePostStrings.noPreparation
                        : value.days == 0
                        ? ProfilePostStrings.sameDay
                        : ProfilePostStrings.preparationDays(value.days!),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                editor.selectPreparationTime(value);
                onTouched?.call('preparationTime');
              }
            },
            alignment: Alignment.centerRight,
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownButtonFormField<InventoryStatus>(
            initialValue: backendData == null
                ? editor.state.inventoryStatus
                : switch (backendData!['inventoryStatus']) {
                    'available' => InventoryStatus.inStock,
                    'out_of_stock' => InventoryStatus.outOfStock,
                    _ => null,
                  },
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.inventory,
            ),
            items: const [
              DropdownMenuItem(
                value: InventoryStatus.inStock,
                child: Text(
                  ProfilePostStrings.inStock,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
              DropdownMenuItem(
                value: InventoryStatus.outOfStock,
                child: Text(
                  ProfilePostStrings.outOfStock,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
              DropdownMenuItem(
                value: InventoryStatus.preOrder,
                child: Text(
                  ProfilePostStrings.preOrder,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                editor.selectInventoryStatus(value);
                onTouched?.call('inventoryStatus');
              }
            },
            alignment: Alignment.centerRight,
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            initialValue: editor.state.tags.join(', '),
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.tags,
            ),
            onChanged: (value) => editor.setTags(
              value
                  .split(RegExp('[,،]'))
                  .map((tag) => tag.trim().replaceFirst(RegExp(r'^#+'), ''))
                  .where((tag) => tag.isNotEmpty)
                  .toSet()
                  .toList(),
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}
