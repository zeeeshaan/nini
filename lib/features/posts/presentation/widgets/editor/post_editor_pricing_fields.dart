import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/create_post/models/post_draft.dart';
import 'package:hywork/features/create_post/cubit/create_post_cubit.dart';

import '../../helpers/post_editor_validation.dart';

class PostEditorPricingFields extends StatelessWidget {
  const PostEditorPricingFields({
    super.key,
    this.backend = false,
    this.backendData,
    this.onTouched,
  });
  final bool backend;
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
          child: TextFormField(
            initialValue: AppStrings.persianDigits(editor.state.price),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.price,
            ),
            validator: PostEditorValidation.price,
            onChanged: editor.updatePrice,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            initialValue: AppStrings.persianDigits(editor.state.discount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.discount,
            ),
            validator: PostEditorValidation.discount,
            onChanged: editor.updateDiscount,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            initialValue: AppStrings.persianDigits(editor.state.warehouseStock),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.stock,
            ),
            validator: PostEditorValidation.stock,
            onChanged: editor.updateWarehouseStock,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownButtonFormField<PostUnit>(
            initialValue: backend
                ? PostUnit.fromName(
                    backendData?['unit'] is String
                        ? backendData!['unit'] as String
                        : null,
                  )
                : editor.state.unit,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.unit,
            ),
            items: [
              for (final unit in PostUnit.values)
                DropdownMenuItem(
                  value: unit,
                  child: Text(
                    ProfilePostStrings.unitNames[unit.name]!,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                editor.selectUnit(value);
                onTouched?.call('unit');
              }
            },
            alignment: Alignment.centerRight,
          ),
        ),
      ],
    );
  }
}
