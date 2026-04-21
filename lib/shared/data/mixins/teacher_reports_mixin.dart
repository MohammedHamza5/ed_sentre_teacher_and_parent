import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../base_repository.dart';

/// Teacher Reports
/// Handles: student performance, overview stats, attendance trends,
/// assignment trends, burnout detection
mixin TeacherReportsMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Get students performance for teacher
  Future<List<Map<String, dynamic>>> getStudentsPerformance({
    required String centerId,
    String? groupId,
    String? teacherId,
  }) async {
    debugPrint('📊 [Reports] getStudentsPerformance - START');
    final userId = currentUserId;
    if (userId == null) return [];

    var effectiveTeacherId = teacherId;
    if (effectiveTeacherId == null) {
      final teacherResult = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      effectiveTeacherId = teacherResult?['id'] as String?;
    }

    if (effectiveTeacherId == null) {
      debugPrint('📊 [Reports] No teacher record found');
      return [];
    }

    try {
      var query = client
          .from('student_group_enrollments')
          .select('''
            student_id,
            students!inner(
              id,
              user_id,
              users:user_id(full_name, avatar_url)
            ),
            groups!student_group_enrollments_group_id_fkey(
              id,
              teacher_id,
              center_id,
              group_name
            )
          ''')
          .eq('groups.teacher_id', effectiveTeacherId)
          .eq('groups.center_id', centerId)
          .eq('status', 'active');

      if (groupId != null) {
        query = query.eq('group_id', groupId);
      }

      final enrollments = await query;

      List<Map<String, dynamic>> studentsPerformance = [];
      Set<String> processedStudents = {};

      for (var enrollment in (enrollments as List)) {
        final student = enrollment['students'] as Map<String, dynamic>?;
        if (student == null) continue;

        final studentId = student['id'] as String?;
        if (studentId == null) continue;
        if (processedStudents.contains(studentId)) continue;
        processedStudents.add(studentId);

        final user = student['users'] as Map<String, dynamic>?;
        final studentUserId = student['user_id'] as String?;

        final attendanceResponse = await client
            .from('attendance')
            .select('status')
            .eq('student_id', studentId);

        final attendanceList = attendanceResponse as List;
        int presentCount = attendanceList
            .where((a) => a['status'] == 'present')
            .length;
        int totalAttendance = attendanceList.length;
        double attendanceRate = totalAttendance > 0
            ? (presentCount / totalAttendance * 100)
            : 0;

        double assignmentAvg = 0;
        if (studentUserId != null) {
          final submissionsResponse = await client
              .from('assignment_submissions')
              .select('score, assignments!inner(teacher_user_id, max_score)')
              .eq('student_user_id', studentUserId)
              .eq('assignments.teacher_user_id', userId);

          final submissions = submissionsResponse as List;
          if (submissions.isNotEmpty) {
            double totalScore = 0;
            int scoredCount = 0;
            for (var sub in submissions) {
              if (sub['score'] != null) {
                final maxScore =
                    (sub['assignments']['max_score'] ?? 100) as num;
                totalScore += ((sub['score'] as num) / maxScore * 100);
                scoredCount++;
              }
            }
            if (scoredCount > 0) {
              assignmentAvg = totalScore / scoredCount;
            }
          }
        }

        double overall = (attendanceRate * 0.3 + assignmentAvg * 0.7);

        studentsPerformance.add({
          'id': studentId,
          'user_id': studentUserId,
          'name': user?['full_name'] ?? 'طالب',
          'avatar': user?['avatar_url'],
          'attendance': attendanceRate.round(),
          'assignments': assignmentAvg.round(),
          'overall': overall.round(),
        });
      }

      studentsPerformance.sort(
        (a, b) => (b['overall'] as int).compareTo(a['overall'] as int),
      );

      for (int i = 0; i < studentsPerformance.length; i++) {
        studentsPerformance[i]['rank'] = i + 1;
        final overall = studentsPerformance[i]['overall'] as int;
        if (overall >= 80) {
          studentsPerformance[i]['trend'] = 'up';
        } else if (overall >= 60) {
          studentsPerformance[i]['trend'] = 'stable';
        } else {
          studentsPerformance[i]['trend'] = 'down';
        }
      }

      debugPrint(
        '📊 [Reports] getStudentsPerformance - SUCCESS: ${studentsPerformance.length} students',
      );
      return studentsPerformance;
    } catch (e, stack) {
      debugPrint('📊 [Reports] getStudentsPerformance ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  /// Get overview stats for teacher reports
  Future<Map<String, dynamic>> getTeacherOverviewStats(
    String centerId, {
    String? teacherId,
  }) async {
    debugPrint('📊 [Reports] getTeacherOverviewStats - START');
    final userId = currentUserId;
    if (userId == null) return {};

    var effectiveTeacherId = teacherId;
    if (effectiveTeacherId == null) {
      final teacherResult = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      effectiveTeacherId = teacherResult?['id'] as String?;
    }

    if (effectiveTeacherId == null) {
      debugPrint('📊 [Reports] No teacher record found for this user');
      return {
        'total_students': 0,
        'attendance_rate': 0,
        'total_assignments': 0,
      };
    }

    try {
      final studentsResponse = await client
          .from('student_group_enrollments')
          .select(
            'student_id, groups!student_group_enrollments_group_id_fkey(teacher_id, center_id)',
          )
          .eq('groups.teacher_id', effectiveTeacherId)
          .eq('groups.center_id', centerId)
          .eq('status', 'active');

      final uniqueStudents = <String>{};
      for (var e in (studentsResponse as List)) {
        uniqueStudents.add(e['student_id'] as String);
      }

      final groupsResponse = await client
          .from('groups')
          .select('id')
          .eq('teacher_id', effectiveTeacherId)
          .eq('center_id', centerId);

      final groupIds = (groupsResponse as List)
          .map((g) => g['id'] as String)
          .toList();

      List attendanceList = [];
      if (groupIds.isNotEmpty) {
        final attendanceResponse = await client
            .from('attendance')
            .select('status')
            .inFilter('group_id', groupIds);
        attendanceList = attendanceResponse as List;
      }

      int presentCount = attendanceList
          .where((a) => a['status'] == 'present')
          .length;
      double attendanceRate = attendanceList.isNotEmpty
          ? (presentCount / attendanceList.length * 100)
          : 0;

      final assignmentsResponse = await client
          .from('assignments')
          .select('id')
          .eq('center_id', centerId)
          .eq('teacher_user_id', userId)
          .isFilter('deleted_at', null);

      int totalAssignments = (assignmentsResponse as List).length;

      return {
        'total_students': uniqueStudents.length,
        'attendance_rate': attendanceRate.round(),
        'total_assignments': totalAssignments,
      };
    } catch (e, stack) {
      debugPrint('📊 [Reports] ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  /// Get teacher attendance trends (last 30 days)
  Future<List<Map<String, dynamic>>> getTeacherAttendanceTrends(
    String centerId, {
    String? teacherId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var effectiveTeacherId = teacherId;
    if (effectiveTeacherId == null) {
      final teacherResult = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      effectiveTeacherId = teacherResult?['id'] as String?;
    }

    if (effectiveTeacherId == null) return [];

    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));

      final groupsResponse = await client
          .from('groups')
          .select('id')
          .eq('teacher_id', effectiveTeacherId)
          .eq('center_id', centerId);

      final groupIds = (groupsResponse as List)
          .map((g) => g['id'] as String)
          .toList();
      if (groupIds.isEmpty) return [];

      final response = await client
          .from('attendance')
          .select('attendance_date, status')
          .inFilter('group_id', groupIds)
          .gte('attendance_date', startDate.toIso8601String())
          .order('attendance_date');

      final Map<String, Map<String, int>> stats = {};

      for (var record in (response as List)) {
        final dateRaw = record['attendance_date'];
        if (dateRaw == null) continue;
        final date = (dateRaw as String).split('T')[0];
        final status = record['status'] as String? ?? 'absent';

        if (!stats.containsKey(date)) {
          stats[date] = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
        }

        stats[date]!['total'] = (stats[date]!['total'] ?? 0) + 1;

        if (status == 'present') {
          stats[date]!['present'] = (stats[date]!['present'] ?? 0) + 1;
        } else if (status == 'absent') {
          stats[date]!['absent'] = (stats[date]!['absent'] ?? 0) + 1;
        } else if (status == 'late') {
          stats[date]!['late'] = (stats[date]!['late'] ?? 0) + 1;
        }
      }

      return stats.entries.map((e) => {'date': e.key, ...e.value}).toList();
    } catch (e, stack) {
      debugPrint('📊 [Reports] getTeacherAttendanceTrends ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  /// Get teacher assignment creation trends
  Future<List<Map<String, dynamic>>> getTeacherAssignmentTrends(
    String centerId, {
    String? teacherId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));

      final response = await client
          .from('assignments')
          .select('created_at, type')
          .eq('center_id', centerId)
          .eq('teacher_user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at');

      final Map<String, int> dailyCounts = {};

      for (var record in (response as List)) {
        final date = DateTime.parse(
          record['created_at'],
        ).toIso8601String().split('T')[0];
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }

      return dailyCounts.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList();
    } catch (e, stack) {
      debugPrint('📊 [Reports] getTeacherAssignmentTrends ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  /// Determine if a student is at risk of burnout
  Future<bool> getStudentBurnoutRisk({
    required String studentId,
    required String centerId,
  }) async {
    try {
      final response = await client.rpc(
        'get_student_burnout_risk',
        params: {'p_student_id': studentId, 'p_center_id': centerId},
      );
      return response == true;
    } catch (e) {
      debugPrint('❌ [Repo] getStudentBurnoutRisk Error: $e');
      return false;
    }
  }
}
