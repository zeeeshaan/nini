import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/report_strings.dart';
import 'package:nini/features/reports/data/api_reports_repository.dart';

class ReportState {
  const ReportState({
    this.submitting = false,
    this.error,
    this.submitted = false,
  });
  final bool submitting, submitted;
  final String? error;
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._repository) : super(const ReportState());
  final ApiReportsRepository _repository;

  Future<bool> submit({
    required String targetType,
    required String targetId,
    required String reason,
    String? note,
  }) async {
    if (state.submitting) return false;
    emit(const ReportState(submitting: true));
    try {
      await _repository.submit(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        note: note,
      );
      if (!isClosed) emit(const ReportState(submitted: true));
      return true;
    } catch (error) {
      if (isClosed) return false;
      final status = error is DioException ? error.response?.statusCode : null;
      emit(
        ReportState(
          error: error is FormatException
              ? error.message
              : status == 401
              ? ReportStrings.signInRequired
              : status == 429
              ? 'Too many reports. Try again later.'
              : ReportStrings.failed,
        ),
      );
      return false;
    }
  }
}
