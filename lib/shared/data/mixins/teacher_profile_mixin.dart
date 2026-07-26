import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';
import '../base_repository.dart';

/// Teacher Profile & Centers
/// Handles: teacher lookup, center enrollment, enrollment details
mixin TeacherProfileMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Get teacher record by user ID
  Future<TeacherModel?> getTeacherByUserId(String userId) async {
    final response = await client
        .from('teachers')
        .select('*, users!inner(full_name, phone, avatar_url)')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return TeacherModel.fromJson(response);
  }

  /// Get teacher's centers (using teacher_enrollments table)
  ///
  /// ⚠️  Schema Inconsistency Workaround:
  /// ─────────────────────────────────────────────────────────────────────
  /// بعض السجلات في teacher_enrollments تستخدم `teacher_user_id`
  /// (= auth user UUID)، وأخرى تستخدم `teacher_id` (= teachers.id UUID).
  ///
  /// هذا يحدث عندما يُنشأ بعض السجلات عبر trigger يُسجّل user_id مباشرةً،
  /// وأخرى عبر Admin panel يُسجّل teacher_id من جدول teachers.
  ///
  /// الحل المثالي: توحيد الـ schema في Supabase (migration) لضمان أن
  /// جميع السجلات تستخدم نفس الـ identifier.
  /// حتى ذلك الحين، نجرّب الاحتمالات الأربعة بترتيب.
  /// ─────────────────────────────────────────────────────────────────────
  Future<List<CenterModel>> getTeacherCentersEnrolled(
    String teacherUserId, {
    String? teacherTableId,
  }) async {
    final conditions = <String>[
      'teacher_user_id.eq.$teacherUserId',
      'teacher_id.eq.$teacherUserId',
    ];

    if (teacherTableId != null && teacherTableId != teacherUserId) {
      conditions.add('teacher_id.eq.$teacherTableId');
      conditions.add('teacher_user_id.eq.$teacherTableId');
    }

    final orFilter = conditions.join(',');

    final response = await client
        .from('teacher_enrollments')
        .select('centers!inner(*)')
        .or(orFilter)
        .eq('status', 'active');

    if ((response as List).isNotEmpty) {
      final distinctCenters = <String, CenterModel>{};
      for (var e in response) {
        final center = CenterModel.fromJson(e['centers']);
        distinctCenters[center.id] = center;
      }
      return distinctCenters.values.toList();
    }

    debugPrint(
      '⚠️  [TeacherRepo] No centers found for userId=$teacherUserId'
      '${teacherTableId != null ? " / teacherId=$teacherTableId" : ""}. '
      'Check teacher_enrollments schema consistency.',
    );
    return [];
  }

  /// Get user's centers (teacher enrollments)
  Future<List<CenterModel>> getTeacherCenters(String teacherId) async {
    final response = await client
        .from('teacher_enrollments')
        .select('centers!inner(*)')
        .eq('teacher_id', teacherId)
        .eq('status', 'active');

    return (response as List)
        .map((e) => CenterModel.fromJson(e['centers']))
        .toList();
  }

  /// Get teacher enrollment details for a specific center (includes salary info)
  Future<TeacherEnrollmentModel?> getTeacherEnrollment({
    required String centerId,
    required String teacherUserId,
    String? teacherTableId,
  }) async {
    final conditions = <String>[
      'teacher_user_id.eq.$teacherUserId',
      'teacher_id.eq.$teacherUserId',
    ];

    if (teacherTableId != null && teacherTableId != teacherUserId) {
      conditions.add('teacher_id.eq.$teacherTableId');
      conditions.add('teacher_user_id.eq.$teacherTableId');
    }

    final orFilter = conditions.join(',');

    final response = await client
        .from('teacher_enrollments')
        .select()
        .eq('center_id', centerId)
        .or(orFilter)
        .eq('status', 'active')
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return TeacherEnrollmentModel.fromJson(response);
  }
}
