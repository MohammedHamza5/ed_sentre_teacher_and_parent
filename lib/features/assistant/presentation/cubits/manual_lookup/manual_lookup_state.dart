sealed class ManualLookupState {
  const ManualLookupState();
}

class ManualLookupInitial extends ManualLookupState {
  const ManualLookupInitial();
}

class ManualLookupLoading extends ManualLookupState {
  const ManualLookupLoading();
}

class ManualLookupLoaded extends ManualLookupState {
  final List<({
    String id,
    String fullName,
    String phone,
  })> results;

  const ManualLookupLoaded(this.results);
}

class ManualLookupError extends ManualLookupState {
  final String message;
  const ManualLookupError(this.message);
}
