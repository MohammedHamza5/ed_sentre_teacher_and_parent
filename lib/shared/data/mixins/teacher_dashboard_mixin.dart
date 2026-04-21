import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../base_repository.dart';

/// Teacher Dashboard & Stats
/// Handles: dashboard stats, salary breakdown
mixin TeacherDashboardMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Get teacher dashboard stats for a center
  Future<Map<String, dynamic>> getTeacherDashboardStats({
    required String teacherId,
    required String teacherUserId,
    required String centerId,
  }) async {
    debugPrint(
      '📊 [Repo] getTeacherDashboardStats: START for Teacher: $teacherId',
    );

    // 1. Active Groups
    final groupsResponse = await client
        .from('groups')
        .select('id')
        .eq('teacher_id', teacherId)
        .eq('center_id', centerId)
        .eq('is_active', true);
    final groupsCount = (groupsResponse as List).length;
    debugPrint('   🔹 Active Groups: $groupsCount');

    // 2. Active Students
    int studentsCount = 0;
    if (groupsCount > 0) {
      final groupIds = (groupsResponse).map((g) => g['id'] as String).toList();
      final studentsResponse = await client
          .from('student_group_enrollments')
          .select('id')
          .inFilter('group_id', groupIds)
          .eq('status', 'active');
      studentsCount = (studentsResponse as List).length;
    }
    debugPrint('   🔹 Active Students: $studentsCount');

    // 3. Today's Classes
    final today = DateTime.now();
    final dayOfWeek = today.weekday % 7;
    final todaySchedule = await client
        .from('schedules')
        .select('id')
        .eq('center_id', centerId)
        .eq('day_of_week', dayOfWeek);
    final todayClassesCount = (todaySchedule as List).length;
    debugPrint('   🔹 Today\'s Classes (Day=$dayOfWeek): $todayClassesCount');

    // 4. Pending Assignments
    final pendingAssignments = await client
        .from('assignment_submissions')
        .select('id, assignments!inner(teacher_user_id)')
        .eq('assignments.teacher_user_id', teacherUserId)
        .isFilter('score', null);
    final pendingCount = (pendingAssignments as List).length;
    debugPrint('   🔹 Pending Assignments: $pendingCount');

    // 5. Unread Messages
    int unreadMessagesCount = 0;
    final conversationsResponse = await client
        .from('conversations')
        .select('id')
        .eq('teacher_id', teacherId)
        .eq('center_id', centerId);

    if ((conversationsResponse as List).isNotEmpty) {
      final conversationIds = (conversationsResponse)
          .map((c) => c['id'] as String)
          .toList();

      final unreadResponse = await client
          .from('messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', teacherId)
          .eq('is_read', false);

      unreadMessagesCount = (unreadResponse as List).length;
    }
    debugPrint('   🔹 Unread Messages: $unreadMessagesCount');

    return {
      'groups_count': groupsCount,
      'students_count': studentsCount,
      'today_classes_count': todayClassesCount,
      'pending_assignments_count': pendingCount,
      'unread_messages_count': unreadMessagesCount,
    };
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
