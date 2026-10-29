import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_option_selection.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/post_form_option_tile/post_form_option_tile.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class PostPricingInventorySection extends StatelessWidget {
  const PostPricingInventorySection({
    super.key,
    required this.priceController,
    required this.discountController,
    required this.stockController,
  });
  final TextEditingController priceController,
      discountController,
      stockController;
  @override
  Widget build(BuildContext context) {
    final draftCubit = context.read<CreatePostCubit>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: priceController,
          label: AppStrings.price,
          hint: AppStrings.enterPrice,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          onChanged: draftCubit.updatePrice,
        ),
        const SizedBox(height: 10),
        AppTextField(
          controller: discountController,
          label: AppStrings.discount,
          hint: AppStrings.zeroPercent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          onChanged: draftCubit.updateDiscount,
        ),
        const SizedBox(height: 10),
        BlocSelector<CreatePostCubit, PostDraft, InventoryStatus>(
          selector: (state) => state.inventoryStatus,
          builder: (context, value) => PostFormOptionTile(
            label: AppStrings.inventoryStatus,
            value: value.label,
            onTap: () => choosePostOption<InventoryStatus>(
              context,
              PostChoiceDialog<InventoryStatus>(
                title: AppStrings.inventoryStatus,
                values: InventoryStatus.values,
                label: (value) => value.label,
                selected: draftCubit.state.inventoryStatus,
              ),
              draftCubit.selectInventoryStatus,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.inventoryHelp,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: stockController,
          label: AppStrings.warehouseStock,
          hint: AppStrings.enterStock,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          onChanged: draftCubit.updateWarehouseStock,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
