import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/app_exceptions.dart';
// Removed invalid core/supabase import

class AssistantRepositoryImpl implements AssistantRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  AsyncResult<({bool hasDebt, double debtAmount, String monthYear, String? invoiceId})> fetchStudentStatusLite(String studentId, String centerId) async {
    try {
      final response = await _client.rpc(
        'check_student_financial_status_lite',
        params: {
          'p_student_id': studentId,
          'p_center_id': centerId,
        },
      );
      
      final data = response as Map<String, dynamic>;
      if (data['success'] == true) {
        return Result.success((
          hasDebt: data['has_debt'] == true,
          debtAmount: (data['debt_amount'] as num?)?.toDouble() ?? 0.0,
          monthYear: data['month_year'] as String? ?? '',
          invoiceId: data['invoice_id'] as String?,
        ));
      } else {
        return Result.failure(ServerException(message: data['message'] ?? 'فشل في جلب الحالة المالية'));
      }
    } catch (e, st) {
      debugPrint('Error fetchStudentStatusLite: $e');
      return Result.failure(UnexpectedException(message: e.toString(), stackTrace: st, originalError: e));
    }
  }

  @override
  AsyncResult<List<({String roomId, String roomName, int capacity, bool isOccupied, String? activeSessionId, String groupName, String teacherName, int checkedInCount})>> getLiveRooms(String centerId) async {
    try {
      final response = await _client.rpc(
        'get_center_live_rooms_status',
        params: {
          'p_center_id': centerId,
        },
      );
      
      final data = response as Map<String, dynamic>;
      if (data['success'] == true) {
        final roomsList = data['rooms'] as List<dynamic>;
        final resultList = roomsList.map((room) {
          final r = room as Map<String, dynamic>;
          return (
            roomId: r['room_id'] as String? ?? '',
            roomName: r['room_name'] as String? ?? '',
            capacity: r['capacity'] as int? ?? 0,
            isOccupied: r['is_occupied'] == true,
            activeSessionId: r['active_session_id'] as String?,
            groupName: r['group_name'] as String? ?? '',
            teacherName: r['teacher_name'] as String? ?? '',
            checkedInCount: r['checked_in_count'] as int? ?? 0,
          );
        }).toList();
        
        return Result.success(resultList);
      } else {
        return Result.failure(ServerException(message: data['message'] ?? 'فشل في جلب القاعات'));
      }
    } catch (e, st) {
      debugPrint('Error getLiveRooms: $e');
      return Result.failure(UnexpectedException(message: e.toString(), stackTrace: st, originalError: e));
    }
  }

  @override
  AsyncResult<void> recordAttendanceAndPayment({
    required String studentId,
    required String sessionId,
    required String centerId,
    String? invoiceId,
    double? paidAmount,
  }) async {
    try {
      // 1. Record Attendance
      final existing = await _client.from('attendance').select('id').eq('session_id', sessionId).eq('student_id', studentId).maybeSingle();
      
      if (existing == null) {
        await _client.from('attendance').insert({
          'session_id': sessionId,
          'student_id': studentId,
          'center_id': centerId,
          'status': 'present',
        });
      }

      // 2. Add Payment if applicable
      if (invoiceId != null && paidAmount != null && paidAmount > 0) {
        await _client.from('invoice_payments').insert({
          'invoice_id': invoiceId,
          'amount': paidAmount,
          'payment_method': 'cash',
        });
      }
      
      return Result.success(Unit.value);
    } catch (e, st) {
      debugPrint('Error recordAttendanceAndPayment: $e');
      return Result.failure(UnexpectedException(message: e.toString(), stackTrace: st, originalError: e));
    }
  }

  @override
  AsyncResult<List<({String id, String fullName, String phone})>> searchStudentByPhone(String query, String centerId) async {
    try {
      if (query.trim().length < 3) return Result.success([]);
      
      final response = await _client
          .from('users')
          .select('id, full_name, phone')
          .eq('role', 'student')
          .eq('default_center_id', centerId)
          .or('phone.ilike.%$query%,full_name.ilike.%$query%')
          .limit(10);
          
      final resultList = (response as List).map((student) {
        final s = student as Map<String, dynamic>;
        return (
          id: s['id'] as String? ?? '',
          fullName: s['full_name'] as String? ?? '',
          phone: s['phone'] as String? ?? '',
        );
      }).toList();
      
      return Result.success(resultList);
    } catch (e, st) {
      debugPrint('Error searchStudentByPhone: $e');
      return Result.failure(UnexpectedException(message: e.toString(), stackTrace: st, originalError: e));
    }
  }
}
