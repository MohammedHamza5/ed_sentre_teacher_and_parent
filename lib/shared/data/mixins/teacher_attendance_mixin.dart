import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_helper.dart';
import '../base_repository.dart';

/// Teacher Attendance
/// Handles: session start, bulk save, today's records, attendance history
mixin TeacherAttendanceMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Start attendance session
  Future<Map<String, dynamic>> startAttendanceSession({
    required String groupId,
    required String centerId,
    bool force = false,
  }) async {
    final response = await client.rpc(
      'start_attendance_session',
      params: {
        'p_group_id': groupId,
        'p_center_id': centerId,
        'p_force': force,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Save attendance for multiple students
  Future<void> saveAttendanceBulk({
    required String centerId,
    required String groupId,
    required String sessionId,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    for (final item in attendanceList) {
      await client.from('attendance').upsert({
        'center_id': centerId,
        'group_id': groupId,
        'session_id': sessionId,
        'student_id': item['student_id'],
        'status': item['status'],
        'attendance_date': DateTime.now().toIso8601String().split('T')[0],
        'notes': item['notes'],
      });
    }

    // NOTE: Notifications are fire-and-forget — failures don't block the save.
    try {
      final groupRes = await client
          .from('groups')
          .select('group_name, courses(name)')
          .eq('id', groupId)
          .single();

      final groupName = groupRes['group_name'] as String? ?? 'مجموعة';
      final courseName =
          (groupRes['courses'] as Map<String, dynamic>?)?['name'] as String? ??
          'مادة';
      final today = DateTime.now().toIso8601String().split('T')[0];

      await NotificationHelper.notifyAttendanceRecorded(
        groupId: groupId,
        groupName: groupName,
        courseName: courseName,
        date: today,
      );

      final absentStudents = attendanceList
          .where((a) => a['status'] == 'absent')
          .toList();

      for (final absent in absentStudents) {
        final studentId = absent['student_id'] as String;
        final studentRes = await client
            .from('students')
            .select('full_name')
            .eq('id', studentId)
            .maybeSingle();
        final studentName = studentRes?['full_name'] as String? ?? 'طالب';

        await NotificationHelper.notifyStudentAbsent(
          studentId: studentId,
          studentName: studentName,
          courseName: courseName,
          centerId: centerId,
          date: today,
        );
      }
    } catch (e) {
      debugPrint('Error sending attendance notifications: $e');
    }
  }

  /// Get attendance monitor data for a specific group and date
  Future<List<Map<String, dynamic>>> getGroupAttendanceForToday(
    String groupId, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateStr =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    try {
      final studentsResponse = await client
          .from('student_group_enrollments')
          .select('''
            student_id,
            students:students!inner(
              id,
              full_name,
              avatar_url,
              student_code
            )
          ''')
          .eq('group_id', groupId)
          .eq('status', 'active');

      final students = List<Map<String, dynamic>>.from(
        studentsResponse as List,
      );

      final attendanceResponse = await client
          .from('attendance')
          .select('student_id, status, check_in_time')
          .eq('group_id', groupId)
          .or('attendance_date.eq.$dateStr,date.eq.$dateStr');

      final attendanceRecords = List<Map<String, dynamic>>.from(
        attendanceResponse as List,
      );

      return students.map((enrollment) {
        final student = enrollment['students'] as Map<String, dynamic>;
        final studentId = enrollment['student_id'];

        final record = attendanceRecords.firstWhere(
          (r) => r['student_id'] == studentId,
          orElse: () => {},
        );

        return {
          'id': student['id'],
          'student_id': studentId,
          'name': student['full_name'],
          'code': student['student_code'],
          'avatar_url': student['avatar_url'],
          'attendance_status': record.isNotEmpty ? record['status'] : 'pending',
          'check_in_time': record['check_in_time'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching group attendance: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGroupAttendanceHistory({
    required String groupId,
    int days = 30,
    int offsetDays = 0,
  }) async {
    try {
      final endDate = DateTime.now().subtract(Duration(days: offsetDays));
      final startDate = endDate.subtract(Duration(days: days - 1));
      final fromDateString = startDate.toIso8601String().split('T')[0];
      final toDateString = endDate.toIso8601String().split('T')[0];

      final studentsResponse = await client
          .from('student_group_enrollments')
          .select('id')
          .eq('group_id', groupId)
          .eq('status', 'active');

      final totalStudents = (studentsResponse as List).length;

      final attendanceResponse = await client
          .from('attendance')
          .select('attendance_date, status')
          .eq('group_id', groupId)
          .gte('attendance_date', fromDateString)
          .lte('attendance_date', toDateString)
          .order('attendance_date', ascending: false);

      final records = List<Map<String, dynamic>>.from(
        attendanceResponse as List,
      );

      final Map<String, Map<String, dynamic>> grouped = {};

      for (final record in records) {
        final rawDate = record['attendance_date'];
        String dateKey;
        if (rawDate is String) {
          dateKey = rawDate.split('T')[0];
        } else if (rawDate is DateTime) {
          dateKey = rawDate.toIso8601String().split('T')[0];
        } else {
          dateKey = rawDate.toString().split(' ')[0];
        }

        grouped.putIfAbsent(dateKey, () {
          return {
            'date': DateTime.parse(dateKey),
            'present': 0,
            'absent': 0,
            'late': 0,
            'total': totalStudents,
          };
        });

        final status = record['status'] as String?;
        if (status == 'present') {
          grouped[dateKey]!['present'] =
              (grouped[dateKey]!['present'] as int) + 1;
        } else if (status == 'late') {
          grouped[dateKey]!['late'] = (grouped[dateKey]!['late'] as int) + 1;
        } else if (status == 'absent') {
          grouped[dateKey]!['absent'] =
              (grouped[dateKey]!['absent'] as int) + 1;
        }
      }

      final list = grouped.values.toList()
        ..sort((a, b) {
          final ad = a['date'] as DateTime;
          final bd = b['date'] as DateTime;
          return bd.compareTo(ad);
        });

      return list;
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
      rethrow;
    }
  }
}
