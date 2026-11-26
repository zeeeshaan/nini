import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/domain/models/post_draft.dart';
import 'package:hywork/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:hywork/features/create_post/presentation/helpers/post_option_selection.dart';
import 'package:hywork/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:hywork/features/create_post/presentation/widgets/form/post_form_option_tile.dart';
import 'package:hywork/shared/widgets/app_textfield/app_text_field.dart';

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
          hint: CreatePostStrings.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          onChanged: draftCubit.updatePrice,
          decorationDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
        _DiscountField(
          controller: discountController,
          onChanged: draftCubit.updateDiscount,
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
                label: (status) => CreatePostStrings.optionLabel(status),
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: .55),
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: stockController,
          hint: CreatePostStrings.warehouseStock,
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

/// Figma discount row: percent badge on the left, editable value on the right.
class _DiscountField extends StatefulWidget {
  const _DiscountField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_DiscountField> createState() => _DiscountFieldState();
}

class _DiscountFieldState extends State<_DiscountField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _DiscountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final raw = widget.controller.text.trim();
    final percent = raw.isEmpty ? CreatePostStrings.zeroPercent : '$raw%';

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline, width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              percent,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Container(width: 0.8, height: 28, color: colors.outline),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                hintText: CreatePostStrings.discount,
                hintTextDirection: TextDirection.ltr,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: .35),
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
