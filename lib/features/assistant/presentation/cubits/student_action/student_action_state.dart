sealed class StudentActionState {
  const StudentActionState();
}

class StudentActionInitial extends StudentActionState {
  const StudentActionInitial();
}

class StudentActionLoading extends StudentActionState {
  const StudentActionLoading();
}

class StudentActionStatusLoaded extends StudentActionState {
  final bool hasDebt;
  final double debtAmount;
  final String monthYear;
  final String? invoiceId;

  const StudentActionStatusLoaded({
    required this.hasDebt,
    required this.debtAmount,
    required this.monthYear,
    this.invoiceId,
  });
}

class StudentActionProcessing extends StudentActionState {
  const StudentActionProcessing();
}

class StudentActionSuccess extends StudentActionState {
  const StudentActionSuccess();
}

class StudentActionFailure extends StudentActionState {
  final String message;
  const StudentActionFailure(this.message);
}
