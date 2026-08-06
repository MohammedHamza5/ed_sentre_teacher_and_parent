import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';
import '../base_repository.dart';

/// Teacher Profile & Centers
/// Handles: teacher lookup, center enrollment, enrollment details
mixin TeacherProfileMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  /// Ensure an independent teacher / center admin has a teacher profile and active enrollment in their center.
  /// This auto-creates the required `teachers` and `teacher_enrollments` rows if they do not already exist,
  /// allowing single-identity sign in without requiring an invitation code.
  Future<void> ensureIndependentTeacherProfile(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 [TeacherProfileMixin] Ensuring Independent Teacher Setup for User: $userId');
      }

      // 1. Find any active center where this user is the administrator
      final center = await client
          .from('centers')
          .select('id, name')
          .eq('admin_user_id', userId)
          .maybeSingle();

      if (center == null) {
        if (kDebugMode) {
          debugPrint('⚠️ [TeacherProfileMixin] No center found owned by admin $userId. Skipping auto-enrollment.');
        }
        return;
      }

      final centerId = center['id'] as String;
      if (kDebugMode) {
        debugPrint('✅ [TeacherProfileMixin] Found Admin Center: $centerId (${center['name']})');
      }

      // 2. Ensure teacher record in `teachers` table
      var teacherRecord = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      String teacherId;
      if (teacherRecord == null) {
        if (kDebugMode) {
          debugPrint('➕ [TeacherProfileMixin] Creating teacher profile for admin...');
        }
        final newTeacher = await client
            .from('teachers')
            .insert({'user_id': userId})
            .select('id')
            .single();
        teacherId = newTeacher['id'] as String;
        if (kDebugMode) {
          debugPrint('✅ [TeacherProfileMixin] Created teacher profile ID: $teacherId');
        }
      } else {
        teacherId = teacherRecord['id'] as String;
        if (kDebugMode) {
          debugPrint('✅ [TeacherProfileMixin] Existing teacher profile ID: $teacherId');
        }
      }

      // 3. Ensure active enrollment in `teacher_enrollments` table for this center
      final existingEnrollment = await client
          .from('teacher_enrollments')
          .select('id, status')
          .eq('center_id', centerId)
          .eq('teacher_user_id', userId)
          .maybeSingle();

      if (existingEnrollment == null) {
        if (kDebugMode) {
          debugPrint('➕ [TeacherProfileMixin] Creating active teacher enrollment in admin center...');
        }
        final userRecord = await client
            .from('users')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle();
        final teacherName = userRecord?['full_name'] as String? ?? center['name'] as String? ?? 'مدرس مستقل';

        await client.from('teacher_enrollments').insert({
          'center_id': centerId,
          'teacher_user_id': userId,
          'teacher_id': teacherId,
          'status': 'active',
          'teacher_name': teacherName,
        });
        if (kDebugMode) {
          debugPrint('✅ [TeacherProfileMixin] Active enrollment created successfully!');
        }
      } else if (existingEnrollment['status'] != 'active') {
        if (kDebugMode) {
          debugPrint('🔄 [TeacherProfileMixin] Activating existing enrollment...');
        }
        await client
            .from('teacher_enrollments')
            .update({'status': 'active', 'teacher_id': teacherId})
            .eq('id', existingEnrollment['id'] as String);
        if (kDebugMode) {
          debugPrint('✅ [TeacherProfileMixin] Enrollment status updated to active!');
        }
      }

      // 4. Automatically bind any orphaned groups in this center (where teacher_id is null) to this independent teacher
      if (kDebugMode) {
        debugPrint('🔗 [TeacherProfileMixin] Linking unassigned groups in admin center to teacher profile...');
      }
      await client
          .from('groups')
          .update({'teacher_id': teacherId})
          .eq('center_id', centerId)
          .isFilter('teacher_id', null);
      if (kDebugMode) {
        debugPrint('✅ [TeacherProfileMixin] Groups successfully linked to independent teacher!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TeacherProfileMixin] Error ensuring independent teacher setup: $e');
      }
    }
  }

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

    final enrollmentsResponse = await client
        .from('teacher_enrollments')
        .select('centers!inner(*)')
        .or(orFilter)
        .eq('status', 'active');

    final ownedCentersResponse = await client
        .from('centers')
        .select('*')
        .eq('admin_user_id', teacherUserId)
        .isFilter('deleted_at', null);

    final distinctCenters = <String, CenterModel>{};

    if ((enrollmentsResponse as List).isNotEmpty) {
      for (var e in enrollmentsResponse) {
        final center = CenterModel.fromJson(e['centers']);
        distinctCenters[center.id] = center;
      }
    }

    if ((ownedCentersResponse as List).isNotEmpty) {
      for (var e in ownedCentersResponse) {
        final center = CenterModel.fromJson(e);
        distinctCenters[center.id] = center;
      }
    }

    if (distinctCenters.isNotEmpty) {
      return distinctCenters.values.toList();
    }

    debugPrint(
      '⚠️  [TeacherRepo] No centers found for userId=$teacherUserId'
      '${teacherTableId != null ? " / teacherId=$teacherTableId" : ""}. '
      'Check teacher_enrollments schema consistency.',
    );
    return [];
  }

  Future<List<CenterModel>> getTeacherCenters(String teacherId) async {
    final enrollmentsResponse = await client
        .from('teacher_enrollments')
        .select('centers!inner(*)')
        .eq('teacher_id', teacherId)
        .eq('status', 'active');

    final ownedCentersResponse = await client
        .from('centers')
        .select('*')
        .eq('admin_user_id', teacherId)
        .isFilter('deleted_at', null);

    final distinctCenters = <String, CenterModel>{};

    if ((enrollmentsResponse as List).isNotEmpty) {
      for (var e in enrollmentsResponse) {
        final center = CenterModel.fromJson(e['centers']);
        distinctCenters[center.id] = center;
      }
    }

    if ((ownedCentersResponse as List).isNotEmpty) {
      for (var e in ownedCentersResponse) {
        final center = CenterModel.fromJson(e);
        distinctCenters[center.id] = center;
      }
    }

    return distinctCenters.values.toList();
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
