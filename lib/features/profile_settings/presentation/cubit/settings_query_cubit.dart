import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsQueryCubit extends Cubit<String> {
  SettingsQueryCubit([String initialQuery = ''])
    : super(initialQuery.trim().toLowerCase());
  void search(String value) => emit(value.trim().toLowerCase());
}
