import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';
import '../base_repository.dart';

/// Teacher Groups & Students
/// Handles: group listing, student listing, student creation, group suggestions
mixin TeacherGroupsMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Get teacher's groups (classes)
  Future<List<GroupModel>> getTeacherGroups(
    String teacherId,
    String centerId,
  ) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 [DEBUG TRACKING] getTeacherGroups:');
    debugPrint('   👉 Teacher ID: $teacherId');
    debugPrint('   👉 Center ID: $centerId');
    debugPrint('   👉 Auth UID: ${client.auth.currentUser?.id}');
    debugPrint('   👉 Auth Email: ${client.auth.currentUser?.email}');
    try {
      // NOTE: In Independent Teacher architecture, all groups in centerId belong to the teacher
      var response = await client
          .from('groups')
          .select('*, courses(name)')
          .eq('center_id', centerId)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('day_of_week');

      debugPrint('   ✅ Raw Response Count: ${(response as List).length}');
      debugPrint('   ✅ Raw Data: $response');

      final groupModels = (response)
          .map(
            (e) => GroupModel.fromJson({
              ...e,
              'course_name': e['courses']?['name'],
            }),
          )
          .toList();

      debugPrint('   ✅ Parsed GroupModels Count: ${groupModels.length}');

      if (groupModels.isNotEmpty) {
        final groupIds = groupModels.map((g) => g.id).toList();

        // 1. Query 'course_prices' for unified pricing fallback
        List coursePrices = [];
        try {
          final pricesResponse = await client
              .from('course_prices')
              .select('subject_name, monthly_price, session_price, grade_level, teacher_id')
              .eq('center_id', centerId)
              .eq('is_active', true);
          coursePrices = pricesResponse as List;
        } catch (e) {
          debugPrint('⚠️ [Repo] Course prices query failed: $e');
        }

        // 2. Query 'schedules' directly — 'group_schedules' table does not exist
        List allScheduleRows = [];
        try {
          final schedulesResponse = await client
              .from('schedules')
              .select('*, classrooms(name)')
              .inFilter('group_id', groupIds);
          allScheduleRows = schedulesResponse as List;
        } catch (e) {
          debugPrint('⚠️ [Repo] Schedules query failed: $e');
        }

        final allSchedules = allScheduleRows.map((e) {
          final roomName = e['classrooms']?['name'] as String?;
          return ScheduleItem.fromJson({...e, 'room_name': roomName});
        }).toList();

        for (var i = 0; i < groupModels.length; i++) {
          final current = groupModels[i];
          final groupSchedules = allSchedules
              .where((s) => s.groupId == current.id)
              .toList();

          double? effectiveMonthlyFee = current.monthlyFee;
          double? effectiveSessionPrice = current.sessionPrice;

          // If monthly fee is not set on the group row, fallback to unified course_prices
          if ((effectiveMonthlyFee == null || effectiveMonthlyFee <= 0) && coursePrices.isNotEmpty) {
            Map<String, dynamic>? matchingPrice;
            for (var cp in coursePrices) {
              final subjectName = (cp['subject_name'] as String?)?.trim().toLowerCase();
              final courseName = (current.courseName ?? '').trim().toLowerCase();
              final groupName = current.groupName.trim().toLowerCase();
              if (subjectName != null &&
                  (subjectName == courseName ||
                      groupName.contains(subjectName) ||
                      courseName.contains(subjectName))) {
                matchingPrice = cp as Map<String, dynamic>?;
                break;
              }
            }

            if (matchingPrice != null) {
              effectiveMonthlyFee = (matchingPrice['monthly_price'] as num?)?.toDouble();
              effectiveSessionPrice = (matchingPrice['session_price'] as num?)?.toDouble();
            }
          }

          groupModels[i] = current.copyWith(
            schedules: groupSchedules,
            monthlyFee: effectiveMonthlyFee,
            sessionPrice: effectiveSessionPrice,
          );
        }
      }

      return groupModels;
    } catch (e, stack) {
      debugPrint('❌ [Repo] getTeacherGroups Error: $e');
      debugPrint('   Stack: $stack');
      return [];
    }
  }

  /// Get teacher's students for a specific group
  Future<List<Map<String, dynamic>>> getGroupStudents(String groupId) async {
    final response = await client
        .from('student_group_enrollments')
        .select('*, students!inner(id, full_name, phone, avatar_url)')
        .eq('group_id', groupId)
        .eq('status', 'active');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get teacher's students
  /// NOTE: Pass [preloadedGroups] to avoid a duplicate getTeacherGroups() call
  /// when groups are already loaded by the caller (e.g., TeacherProvider).
  Future<List<Map<String, dynamic>>> getTeacherStudents({
    required String teacherId,
    required String centerId,
    List<GroupModel>? preloadedGroups,
    int? limit,
    int? offset,
  }) async {
    try {
      final groups =
          preloadedGroups ?? await getTeacherGroups(teacherId, centerId);

      debugPrint('🔍 [DEBUG TRACKING] getTeacherStudents:');
      debugPrint('   👉 Teacher ID: $teacherId, Center ID: $centerId');
      debugPrint('   👉 Groups Count: ${groups.length}');

      if (groups.isEmpty) {
        debugPrint('   ⚠️ No groups found, returning empty students list.');
        return [];
      }
      final groupIds = groups.map((g) => g.id).toList();

      var query = client
          .from('student_group_enrollments')
          .select('''
            id,
            group_id,
            student_id,
            status,
            students!inner(
              id,
              user_id,
              full_name,
              phone,
              avatar_url,
              student_code
            )
          ''')
          .inFilter('group_id', groupIds)
          .eq('status', 'active')
          .order('id', ascending: false);
      if (limit != null && offset != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }
      final response = await query;

      final data = List<Map<String, dynamic>>.from(response as List);
      debugPrint('   ✅ Fetched Students Enrollments Count: ${data.length}');

      return data.map((e) {
        final student = e['students'] as Map<String, dynamic>;
        final groupId = e['group_id'] as String;

        final group = groups.firstWhere(
          (g) => g.id == groupId,
          orElse: () => GroupModel(
            id: groupId,
            groupName: 'Unknown',
            teacherId: teacherId,
            centerId: centerId,
            courseId: '',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return {
          'id': student['id'],
          'student_id': student['id'],
          'user_id': student['user_id'],
          'student_user_id': student['user_id'],
          'student_name': student['full_name'],
          'student_phone': student['phone'],
          'student_avatar': student['avatar_url'],
          'student_code': student['student_code'],
          'group_id': group.id,
          'group_name': group.groupName,
          'course_name': group.courseName ?? 'مادة',
          'enrollment_id': e['id'],
        };
      }).toList();
    } catch (e, stack) {
      debugPrint('❌ [Repo] getTeacherStudents Error: $e');
      debugPrint('   Stack: $stack');
      return [];
    }
  }


  /// Add a new student and enroll them in a group
  Future<void> addStudent({
    required String fullName,
    required String phone,
    required String gradeLevel,
    required String groupId,
    required String centerId,
    String? code,
  }) async {
    final studentCode = code ?? _generateStudentCode();

    final studentResponse = await client
        .from('students')
        .insert({
          'full_name': fullName,
          'phone': phone,
          'student_code': studentCode,
          'grade_level': gradeLevel,
        })
        .select('id')
        .single();

    final studentId = studentResponse['id'] as String;

    // NOTE: Added center_id (NOT NULL in schema)
    await client.from('student_group_enrollments').insert({
      'student_id': studentId,
      'group_id': groupId,
      'center_id': centerId,
      'status': 'active',
      'enrollment_date': DateTime.now().toIso8601String(),
    });
  }

  String _generateStudentCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return 'WS-${now.substring(now.length - 6)}';
  }

  /// Suggest best groups for a student
  Future<List<Map<String, dynamic>>> suggestBestGroups({
    required String centerId,
    required String courseId,
    String? studentId,
    String? gradeLevel,
  }) async {
    try {
      final response = await client.rpc(
        'suggest_best_groups_for_student',
        params: {
          'p_center_id': centerId,
          'p_course_id': courseId,
          'p_student_id': studentId,
          'p_grade_level': gradeLevel,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error suggesting groups: $e');
      return [];
    }
  }
}
