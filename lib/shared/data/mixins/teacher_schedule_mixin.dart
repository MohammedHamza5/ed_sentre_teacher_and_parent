import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';
import '../base_repository.dart';

/// Teacher Schedule
/// Handles: fetching teacher's weekly schedule
mixin TeacherScheduleMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Get teacher's schedule
  Future<List<ScheduleItem>> getTeacherSchedule({
    required String teacherId,
    required String centerId,
    String? dayOfWeek,
  }) async {
    debugPrint(
      '🔎 [Repo] getTeacherSchedule: Teacher=$teacherId, Center=$centerId',
    );
    try {
      var query = client
          .from('schedules')
          .select('''
            *,
            classrooms(name),
            groups!inner(id, group_name, courses(id, name))
          ''')
          .eq('center_id', centerId);

      if (dayOfWeek != null) {
        final dayInt = DayOfWeek.fromString(dayOfWeek).value;
        query = query.eq('day_of_week', dayInt);
      }

      final response = await query.order('day_of_week').order('start_time');
      debugPrint(
        '✅ [Repo] getTeacherSchedule: Found ${(response as List).length} items',
      );

      return (response).map((e) {
        final group = e['groups'] as Map<String, dynamic>? ?? {};
        final course =
            group['courses'] as Map<String, dynamic>? ??
            {'id': '', 'name': 'غير محدد'};
        final roomName = e['classrooms']?['name'] as String?;

        return ScheduleItem(
          id: e['id'],
          groupId: e['group_id'] ?? group['id'],
          courseId: course['id'] ?? '',
          courseName: course['name'] ?? 'غير محدد',
          groupName: group['group_name'] ?? 'مجموعة',
          teacherName: '',
          dayOfWeek: DayOfWeek.fromInt(e['day_of_week']).englishName,
          startTime: e['start_time'] ?? '',
          endTime: e['end_time'] ?? '',
          roomName: roomName,
          centerId: e['center_id'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Repo] getTeacherSchedule Error: $e');
      return [];
    }
  }
}
