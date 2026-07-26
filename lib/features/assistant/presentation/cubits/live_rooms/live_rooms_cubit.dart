import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/assistant_repository.dart';
import 'live_rooms_state.dart';

class LiveRoomsCubit extends Cubit<LiveRoomsState> {
  final AssistantRepository _repository;
  final String _centerId;

  LiveRoomsCubit(this._repository, this._centerId) : super(const LiveRoomsInitial());

  Future<void> fetchLiveRooms() async {
    emit(const LiveRoomsLoading());

    final result = await _repository.getLiveRooms(_centerId);
    
    result.when(
      success: (rooms) {
        emit(LiveRoomsLoaded(rooms));
      },
      failure: (exception) {
        emit(LiveRoomsError(exception.message));
      },
    );
  }
}
