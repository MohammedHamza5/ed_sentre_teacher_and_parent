sealed class LiveRoomsState {
  const LiveRoomsState();
}

class LiveRoomsInitial extends LiveRoomsState {
  const LiveRoomsInitial();
}

class LiveRoomsLoading extends LiveRoomsState {
  const LiveRoomsLoading();
}

class LiveRoomsLoaded extends LiveRoomsState {
  final List<({
    String roomId,
    String roomName,
    int capacity,
    bool isOccupied,
    String? activeSessionId,
    String groupName,
    String teacherName,
    int checkedInCount,
  })> rooms;

  const LiveRoomsLoaded(this.rooms);
}

class LiveRoomsError extends LiveRoomsState {
  final String message;
  const LiveRoomsError(this.message);
}
