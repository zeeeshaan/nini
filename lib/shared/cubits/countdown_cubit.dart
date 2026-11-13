import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class CountdownState {
  const CountdownState(this.seconds, {this.running = false});
  final int seconds;
  final bool running;
}

class CountdownCubit extends Cubit<CountdownState> {
  CountdownCubit(this.duration, {bool startImmediately = false})
    : super(CountdownState(duration)) {
    if (startImmediately) start();
  }
  final int duration;
  Timer? _timer;
  void start() {
    _timer?.cancel();
    emit(CountdownState(duration, running: true));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.seconds - 1;
      if (remaining == 0) timer.cancel();
      emit(CountdownState(remaining, running: remaining > 0));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
