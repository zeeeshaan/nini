import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';

class PostEditorOptionsFields extends StatelessWidget {
  const PostEditorOptionsFields({super.key});
  @override
  Widget build(BuildContext context) {
    final editor = context.read<CreatePostCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownButtonFormField<PreparationTime>(
            initialValue: editor.state.preparationTime,
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
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) editor.selectPreparationTime(value);
            },
            alignment: Alignment.centerRight,
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownButtonFormField<InventoryStatus>(
            initialValue: editor.state.inventoryStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.inventory,
            ),
            items: const [
              DropdownMenuItem(
                value: InventoryStatus.inStock,
                child: Text(
                  ProfilePostStrings.inStock,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
              DropdownMenuItem(
                value: InventoryStatus.outOfStock,
                child: Text(
                  ProfilePostStrings.outOfStock,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
              DropdownMenuItem(
                value: InventoryStatus.preOrder,
                child: Text(
                  ProfilePostStrings.preOrder,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) editor.selectInventoryStatus(value);
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
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }
}
