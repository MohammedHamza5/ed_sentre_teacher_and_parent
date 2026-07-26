import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/assistant_repository.dart';
import 'manual_lookup_state.dart';

class ManualLookupCubit extends Cubit<ManualLookupState> {
  final AssistantRepository _repository;
  final String _centerId;

  ManualLookupCubit(this._repository, this._centerId) : super(const ManualLookupInitial());

  Future<void> search(String query) async {
    if (query.trim().length < 3) {
      emit(const ManualLookupInitial());
      return;
    }
    
    emit(const ManualLookupLoading());

    final result = await _repository.searchStudentByPhone(query, _centerId);
    
    result.when(
      success: (results) {
        emit(ManualLookupLoaded(results));
      },
      failure: (exception) {
        emit(ManualLookupError(exception.message));
      },
    );
  }
}
