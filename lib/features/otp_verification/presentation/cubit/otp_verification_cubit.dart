import 'package:flutter_bloc/flutter_bloc.dart';

class OtpVerificationCubit extends Cubit<String> {
  OtpVerificationCubit() : super('');
  bool _completed = false;
  void changeCode(String code) => emit(code);
  bool complete() {
    if (_completed || state.length != 4) return false;
    _completed = true;
    return true;
  }
}
