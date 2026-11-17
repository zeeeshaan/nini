import 'package:nini/features/wallet/presentation/cubit/wallet_amount_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../data/wallet_sample_data.dart';
import 'wallet_amount_presets.dart';
import 'wallet_text_field.dart';

class WalletAmountSection extends StatefulWidget {
  const WalletAmountSection({
    super.key,
    this.label = WalletStrings.pendingAmount,
    this.controller,
  });
  final String label;
  final TextEditingController? controller;
  @override
  State<WalletAmountSection> createState() => _WalletAmountSectionState();
}

class _WalletAmountSectionState extends State<WalletAmountSection> {
  late final _amount =
      widget.controller ??
      TextEditingController(
        text: AppStrings.persianDigits(WalletSampleData.pendingAmount),
      );
  final _presets = WalletAmountCubit();
  @override
  void dispose() {
    _presets.close();
    if (widget.controller == null) _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<WalletAmountCubit, String?>(
    bloc: _presets,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          textAlign: TextAlign.right,
          style: AppTextStyles.helper,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 8),
        WalletTextField(
          controller: _amount,
          suffixIcon: const Padding(
            padding: EdgeInsets.all(11),
            child: AppIcon(AppIcons.bankNote, size: 18),
          ),
          onChanged: _presets.edit,
        ),
        const SizedBox(height: 6),
        WalletAmountPresets(
          selected: _presets.state,
          onSelected: (amount) {
            _amount.text = AppStrings.persianDigits(amount);
            _presets.select(amount);
          },
        ),
      ],
    ),
  );
}
