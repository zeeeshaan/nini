import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_option_selection.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_form_option_tile.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class PostPricingInventorySection extends StatelessWidget {
  const PostPricingInventorySection({
    super.key,
    required this.priceController,
    required this.discountController,
    required this.stockController,
    this.priceError = false,
  });
  final TextEditingController priceController,
      discountController,
      stockController;
  final bool priceError;
  @override
  Widget build(BuildContext context) {
    final draftCubit = context.read<CreatePostCubit>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          hasError: priceError,
          controller: priceController,
          label: CreatePostStrings.price,
          hint: CreatePostStrings.enterPrice,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          onChanged: draftCubit.updatePrice,
          decorationDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
        AppTextField(
          controller: discountController,
          label: CreatePostStrings.discount,
          hint: CreatePostStrings.zeroPercent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          onChanged: draftCubit.updateDiscount,
          decorationDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, InventoryStatus>(
          selector: (state) => state.inventoryStatus,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.inventoryStatus,
            value: CreatePostStrings.optionLabel(value),
            onTap: () => choosePostOption<InventoryStatus>(
              context,
              PostChoiceDialog<InventoryStatus>(
                title: CreatePostStrings.inventoryStatus,
                values: InventoryStatus.values,
                label: (value) => CreatePostStrings.optionLabel(value),
                selected: draftCubit.state.inventoryStatus,
              ),
              draftCubit.selectInventoryStatus,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          CreatePostStrings.inventoryHelp,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: stockController,
          label: CreatePostStrings.warehouseStock,
          hint: CreatePostStrings.enterStock,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          onChanged: draftCubit.updateWarehouseStock,
          decorationDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
