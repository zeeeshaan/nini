import 'package:flutter_bloc/flutter_bloc.dart';

/// Local preview state until account following is connected.
class SellerProfileCubit extends Cubit<bool> {
  SellerProfileCubit() : super(false);

  void toggleFollow() => emit(!state);
}
