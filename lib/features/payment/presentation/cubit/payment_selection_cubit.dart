import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/payment_method.dart';

class PaymentSelectionCubit extends Cubit<PaymentMethod> {
  PaymentSelectionCubit([super.initial = PaymentMethod.mellat]);
  void select(PaymentMethod method) => emit(method);
}
