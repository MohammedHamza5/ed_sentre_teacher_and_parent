import '../../../../core/errors/result.dart';

abstract class AssistantRepository {
  /// Fetch student financial status using lite RPC
  AsyncResult<({
    bool hasDebt,
    double debtAmount,
    String monthYear,
    String? invoiceId,
  })> fetchStudentStatusLite(String studentId, String centerId);

  /// Fetch live rooms and their status
  AsyncResult<List<({
    String roomId,
    String roomName,
    int capacity,
    bool isOccupied,
    String? activeSessionId,
    String groupName,
    String teacherName,
    int checkedInCount,
  })>> getLiveRooms(String centerId);

  /// Record attendance and potentially a payment in one swift transaction
  AsyncResult<void> recordAttendanceAndPayment({
    required String studentId,
    required String sessionId,
    required String centerId,
    String? invoiceId,
    double? paidAmount,
  });
  
  /// Search for a student manually by phone or name
  AsyncResult<List<({
    String id,
    String fullName,
    String phone,
  })>> searchStudentByPhone(String query, String centerId);
}
