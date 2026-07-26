import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/assistant_repository.dart';
import 'student_action_state.dart';

class StudentActionCubit extends Cubit<StudentActionState> {
  final AssistantRepository _repository;
  final String _centerId;

  StudentActionCubit(this._repository, this._centerId) : super(const StudentActionInitial());

  Future<void> fetchStatus(String studentId) async {
    if (state is StudentActionLoading) return;
    emit(const StudentActionLoading());

    final result = await _repository.fetchStudentStatusLite(studentId, _centerId);
    
    result.when(
      success: (data) {
        emit(StudentActionStatusLoaded(
          hasDebt: data.hasDebt,
          debtAmount: data.debtAmount,
          monthYear: data.monthYear,
          invoiceId: data.invoiceId,
        ));
      },
      failure: (exception) {
        emit(StudentActionFailure(exception.message));
      },
    );
  }

  Future<void> recordAction({
    required String studentId,
    required String sessionId,
    String? invoiceId,
    double? paidAmount,
  }) async {
    if (state is StudentActionProcessing) return;
    emit(const StudentActionProcessing());

    final result = await _repository.recordAttendanceAndPayment(
      studentId: studentId,
      sessionId: sessionId,
      centerId: _centerId,
      invoiceId: invoiceId,
      paidAmount: paidAmount,
    );

    result.when(
      success: (_) {
        emit(const StudentActionSuccess());
      },
      failure: (exception) {
        emit(StudentActionFailure(exception.message));
      },
    );
  }
}
