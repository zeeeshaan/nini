import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/app_strings.dart';

class HomeCategoryCubit extends Cubit<String> {
  HomeCategoryCubit() : super(AppStrings.all);

  void selectCategory(String category) {
    if (category == state) return;
    emit(category);
  }
}
