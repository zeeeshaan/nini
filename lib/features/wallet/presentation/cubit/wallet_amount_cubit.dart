import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_string/app_string.dart';

import '../../data/wallet_sample_data.dart';

class WalletAmountCubit extends Cubit<String?> {
  WalletAmountCubit() : super(WalletSampleData.presets.last);
  void select(String amount) => emit(amount);
  void edit(String value) => emit(
    WalletSampleData.presets
        .where(
          (amount) =>
              amount == value || AppStrings.persianDigits(amount) == value,
        )
        .firstOrNull,
  );
}
