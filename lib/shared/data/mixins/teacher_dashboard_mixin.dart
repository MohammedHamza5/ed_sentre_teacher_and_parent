import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../base_repository.dart';

/// Teacher Dashboard & Stats
/// Handles: dashboard stats, salary breakdown
mixin TeacherDashboardMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Get teacher dashboard stats for a center
  /// NOTE: Uses a single RPC call instead of 5 sequential queries.
  /// The RPC function handles all counting server-side for ~4x speed improvement.
  Future<Map<String, dynamic>> getTeacherDashboardStats({
    required String teacherId,
    required String teacherUserId,
    required String centerId,
  }) async {
    debugPrint(
      '📊 [Repo] getTeacherDashboardStats: START (RPC) for Teacher: $teacherId',
    );

    try {
      final response = await client.rpc(
        'get_teacher_dashboard_stats',
        params: {
          'p_teacher_id': teacherId,
          'p_teacher_user_id': teacherUserId,
          'p_center_id': centerId,
        },
      );

      final stats = Map<String, dynamic>.from(response as Map);
      debugPrint(
        '✅ [Repo] getTeacherDashboardStats (RPC): $stats',
      );
      return stats;
    } catch (e) {
      debugPrint('⚠️ [Repo] RPC failed, falling back to sequential: $e');
      // NOTE: Fallback to sequential queries if RPC is not deployed yet
      return _getTeacherDashboardStatsFallback(
        teacherId: teacherId,
        teacherUserId: teacherUserId,
        centerId: centerId,
      );
    }
  }

  /// Fallback: sequential queries (kept for safety during migration)
  Future<Map<String, dynamic>> _getTeacherDashboardStatsFallback({
    required String teacherId,
    required String teacherUserId,
    required String centerId,
  }) async {
    // Run all independent queries in parallel instead of sequentially
    final results = await Future.wait<dynamic>([
      // 1. Active Groups
      client
          .from('groups')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('center_id', centerId)
          .eq('is_active', true),
      // 2. Today's Classes
      _getTodayScheduleCount(teacherId, centerId),
      // 3. Pending Assignments
      client
          .from('assignment_submissions')
          .select('id, assignments!inner(teacher_user_id)')
          .eq('assignments.teacher_user_id', teacherUserId)
          .isFilter('score', null),
      // 4. Conversations (for unread messages)
      client
          .from('conversations')
          .select('id')
          .eq('teacher_id', teacherUserId)
          .eq('center_id', centerId),
    ]);

    final groupsResponse = results[0] as List;
    final todayClassesCount = results[1] as int;
    final pendingAssignments = results[2] as List;
    final conversationsResponse = results[3] as List;

    // 2b. Active Students (depends on groups result)
    int studentsCount = 0;
    if (groupsResponse.isNotEmpty) {
      final groupIds = groupsResponse.map((g) => g['id'] as String).toList();
      final studentsResponse = await client
          .from('student_group_enrollments')
          .select('id')
          .inFilter('group_id', groupIds)
          .eq('status', 'active');
      studentsCount = (studentsResponse as List).length;
    }

    // 5. Unread Messages (depends on conversations result)
    int unreadMessagesCount = 0;
    if (conversationsResponse.isNotEmpty) {
      final conversationIds =
          conversationsResponse.map((c) => c['id'] as String).toList();
      final unreadResponse = await client
          .from('messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', teacherUserId)
          .eq('is_read', false);
      unreadMessagesCount = (unreadResponse as List).length;
    }

    return {
      'groups_count': groupsResponse.length,
      'students_count': studentsCount,
      'today_classes_count': todayClassesCount,
      'pending_assignments_count': pendingAssignments.length,
      'unread_messages_count': unreadMessagesCount,
    };
  }

  /// Helper: Get today's schedule count with correct day_of_week text format
  Future<int> _getTodayScheduleCount(String teacherId, String centerId) async {
    final dayNames = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday',
    ];
    final todayName = dayNames[DateTime.now().weekday - 1];

    final todaySchedule = await client
        .from('schedules')
        .select('id')
        .eq('center_id', centerId)
        .eq('teacher_id', teacherId)
        .eq('day_of_week', todayName);
    return (todaySchedule as List).length;
  }

  /// Get teacher salary breakdown
  Future<Map<String, dynamic>> getTeacherSalaryBreakdown({
    required String teacherId,
    required String centerId,
    required int month,
    required int year,
  }) async {
    final response = await client.rpc(
      'get_teacher_salary_breakdown',
      params: {
        'p_teacher_id': teacherId,
        'p_center_id': centerId,
        'p_month': month,
        'p_year': year,
      },
    );
    return response as Map<String, dynamic>;
  }
}
