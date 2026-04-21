import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';
import '../base_repository.dart';

/// Parent Repository Mixin
/// Handles parent-specific data: children, dashboard, attendance, grades, payments, schedule
mixin ParentRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT PROFILE
  // ═══════════════════════════════════════════════════════════════════════

  /// Get parent record by user ID
  Future<Map<String, dynamic>?> getParentByUserId(String userId) async {
    final response = await client
        .from('parents')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT - CHILDREN
  // ═══════════════════════════════════════════════════════════════════════

  /// Get parent's children - يجلب أبناء ولي الأمر فقط
  Future<List<StudentModel>> getParentChildren(String parentUserId) async {
    debugPrint('🔍 [getParentChildren] Starting for userId: $parentUserId');

    // الخطوة 1: الحصول على parent_id من جدول parents
    final parentRecord = await client
        .from('parents')
        .select('id')
        .eq('user_id', parentUserId)
        .maybeSingle();

    final parentId = parentRecord?['id'] ?? parentUserId;
    debugPrint('🔍 [getParentChildren] Using parentId: $parentId');

    // الخطوة 2: جلب روابط الأبناء من student_parents
    final linksResponse = await client
        .from('student_parents')
        .select('student_user_id, relationship, is_primary')
        .eq('parent_id', parentId);

    final links = List<Map<String, dynamic>>.from(linksResponse as List);
    debugPrint('🔍 [getParentChildren] Found ${links.length} child links');

    if (links.isEmpty) {
      return [];
    }

    // الخطوة 3: جلب بيانات الطلاب بناءً على student_user_id
    final studentUserIds = links
        .map((l) => l['student_user_id'] as String)
        .toList();

    final studentsResponse = await client
        .from('students')
        .select('''
          id, user_id, full_name, phone, email, avatar_url,
          birth_date, gender, school_name, academic_year, student_code
        ''')
        .inFilter('user_id', studentUserIds);

    final students = List<Map<String, dynamic>>.from(studentsResponse as List);
    debugPrint('🔍 [getParentChildren] Found ${students.length} students');

    // الخطوة 4: دمج البيانات
    return students.map((student) {
      final link = links.firstWhere(
        (l) => l['student_user_id'] == student['user_id'],
        orElse: () => {'relationship': 'guardian', 'is_primary': false},
      );

      return StudentModel.fromJson({
        ...student,
        'relationship': link['relationship'],
        'is_primary': link['is_primary'],
      });
    }).toList();
  }

  /// Get child's centers with detailed info
  Future<List<ChildCenterInfo>> getChildCenters(String studentUserId) async {
    final response = await client.rpc(
      'get_student_centers_detailed',
      params: {'p_user_id': studentUserId},
    );

    return (response as List).map((e) => ChildCenterInfo.fromJson(e)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT - DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  /// Get student dashboard summary
  Future<Map<String, dynamic>> getStudentDashboardSummary({
    required String studentId,
    String? centerId,
  }) async {
    debugPrint(
      '📊 [getStudentDashboardSummary] studentId: $studentId, centerId: $centerId',
    );
    final response = await client.rpc(
      'get_student_dashboard_summary',
      params: {'p_user_id': studentId, 'p_center_id': centerId},
    );

    debugPrint('📊 [getStudentDashboardSummary] response: $response');
    return response as Map<String, dynamic>? ?? {};
  }

  /// Get student home stats
  Future<Map<String, dynamic>> getStudentHomeStats() async {
    final response = await client.rpc('get_student_home_stats');
    return response as Map<String, dynamic>? ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT - ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════

  /// Get student attendance
  Future<List<AttendanceModel>> getStudentAttendance({
    String? centerId,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
    String? studentUserId,
  }) async {
    debugPrint(
      '📅 [getStudentAttendance] centerId: $centerId, studentUserId: $studentUserId, limit: $limit',
    );
    final response = await client.rpc(
      'get_student_attendance',
      params: {
        'p_center_id': centerId,
        'p_limit': limit,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
        'p_student_user_id': studentUserId,
      },
    );

    debugPrint(
      '📅 [getStudentAttendance] Response: ${(response as List).length} records',
    );
    return (response).map((e) => AttendanceModel.fromJson(e)).toList();
  }

  /// Get attendance stats by course
  Future<List<CourseAttendanceStats>> getAttendanceStatsByCourse({
    required String studentId,
    String? centerId,
  }) async {
    final response = await client.rpc(
      'get_student_course_attendance',
      params: {'p_student_id': studentId, 'p_center_id': centerId},
    );

    return (response as List)
        .map((e) => CourseAttendanceStats.fromJson(e))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT - GRADES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get student grades
  Future<List<StudentGradeView>> getStudentGrades({
    String? centerId,
    String? courseId,
    String? examType,
    int limit = 100,
    int offset = 0,
    String? studentUserId,
  }) async {
    debugPrint(
      '📝 [getStudentGrades] centerId: $centerId, limit: $limit, studentUserId: $studentUserId',
    );
    final response = await client.rpc(
      'get_student_grades',
      params: {
        'p_center_id': centerId,
        'p_exam_type': examType,
        'p_limit': limit,
        'p_offset': offset,
        'p_student_user_id': studentUserId,
      },
    );

    debugPrint(
      '📝 [getStudentGrades] Found ${(response as List).length} grades',
    );
    return (response).map((e) => StudentGradeView.fromJson(e)).toList();
  }

  /// Add grade (teacher)
  Future<void> addGrade(Map<String, dynamic> data) async {
    final userId = currentUserId;
    await client.from('grades').insert({
      ...data,
      'graded_by': userId,
      'graded_at': DateTime.now().toIso8601String(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT - PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get student payments
  Future<List<PaymentModel>> getStudentPayments({
    String? centerId,
    String? status,
    int? limit,
    String? studentUserId,
  }) async {
    debugPrint(
      '💰 [getStudentPayments] centerId: $centerId, studentUserId: $studentUserId, limit: $limit',
    );
    final response = await client.rpc(
      'get_student_payments',
      params: {
        'p_center_id': centerId,
        'p_limit': limit,
        'p_student_user_id': studentUserId,
      },
    );

    return (response as List).map((e) => PaymentModel.fromJson(e)).toList();
  }

  /// Get student invoice summary
  Future<Map<String, dynamic>> getStudentInvoiceSummary({
    required String studentId,
    required String centerId,
    required int month,
    required int year,
  }) async {
    final response = await client.rpc(
      'get_student_invoice_summary',
      params: {
        'p_student_id': studentId,
        'p_center_id': centerId,
        'p_month': month,
        'p_year': year,
      },
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return {};
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT - SCHEDULE
  // ═══════════════════════════════════════════════════════════════════════

  /// Get schedule for a day (student perspective)
  Future<List<ScheduleItem>> getSchedule({
    String? dayOfWeek,
    String? centerId,
  }) async {
    final response = await client.rpc(
      'get_student_schedule',
      params: {'p_day_of_week': dayOfWeek, 'p_center_id': centerId},
    );

    return (response as List).map((e) => ScheduleItem.fromJson(e)).toList();
  }

  /// Get student schedule (detailed, for parent)
  Future<List<Map<String, dynamic>>> getStudentSchedule({
    required String centerId,
    required String studentUserId,
  }) async {
    try {
      final studentData = await client
          .from('students')
          .select('id')
          .eq('user_id', studentUserId)
          .maybeSingle();

      if (studentData == null) return [];
      final studentId = studentData['id'];

      // 1. Get all active enrolled groups for this student
      // ⚠️  لا نستخدم .eq('groups.center_id', centerId) لأنه يعمل فقط مع
      //     !inner join صريح — نُصفّي بالـ centerId لاحقاً على جدول schedules
      final enrollments = await client
          .from('student_group_enrollments')
          .select('group_id')
          .eq('student_id', studentId)
          .eq('status', 'active');

      final groupIds = (enrollments as List).map((e) => e['group_id']).toList();

      if (groupIds.isEmpty) return [];

      // 2. Fetch schedules for these groups
      final response = await client
          .from('schedules')
          .select('''
            day_of_week, start_time, end_time,
            groups!inner(group_name),
            courses(name),
            teachers(users(full_name)),
            classrooms(name)
          ''')
          .inFilter('group_id', groupIds)
          .eq('center_id', centerId);

      List<Map<String, dynamic>> scheduleItems = [];

      for (var s in (response as List)) {
        final group = s['groups'] as Map<String, dynamic>? ?? {};
        final course = s['courses'] as Map<String, dynamic>? ?? {};
        final teacher = s['teachers'] as Map<String, dynamic>? ?? {};
        final teacherUser = teacher['users'] as Map<String, dynamic>? ?? {};
        final classroom = s['classrooms'] as Map<String, dynamic>? ?? {};

        final courseName = course['name'] ?? 'مادة دراسية';
        final teacherName = teacherUser['full_name'] ?? 'معلم';
        final groupName = group['group_name'] ?? '';
        final roomName = classroom['name'] ?? '';

        scheduleItems.add({
          'day': s['day_of_week'],
          'start_time': s['start_time'],
          'end_time': s['end_time'],
          'course_name': courseName,
          'teacher_name': teacherName,
          'group_name': groupName,
          'room_name': roomName,
        });
      }

      scheduleItems.sort((a, b) {
        final dayCompare = (a['day'] as int).compareTo(b['day'] as int);
        if (dayCompare != 0) return dayCompare;
        return (a['start_time'] as String).compareTo(b['start_time'] as String);
      });

      return scheduleItems;
    } catch (e) {
      debugPrint('Error getting student schedule: $e');
      return [];
    }
  }
}
