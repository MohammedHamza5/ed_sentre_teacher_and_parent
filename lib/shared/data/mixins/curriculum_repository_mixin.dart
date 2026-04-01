import 'package:supabase_flutter/supabase_flutter.dart';
import '../base_repository.dart';

/// Curriculum Repository Mixin
/// Handles CRUD operations for subjects, chapters, and lessons within a center
mixin CurriculumRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // SUBJECTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all subjects for a center
  Future<List<Map<String, dynamic>>> getCurriculumSubjects(
    String centerId,
  ) async {
    final response = await client
        .from('subjects')
        .select()
        .eq('center_id', centerId)
        .isFilter('deleted_at', null)
        .order('order_num');

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Add a new subject to a center
  Future<Map<String, dynamic>> addSubject({
    required String centerId,
    required String name,
    String? code,
    String? description,
    String? gradeLevel,
    int? semester,
    String? icon,
    String? color,
    int? orderNum,
  }) async {
    final response = await client
        .from('subjects')
        .insert({
          'center_id': centerId,
          'name': name,
          if (code != null) 'code': code,
          if (description != null) 'description': description,
          if (gradeLevel != null) 'grade_level': gradeLevel,
          if (semester != null) 'semester': semester,
          'icon': icon ?? '📚',
          'color': color ?? '#4F46E5',
          'order_num': orderNum ?? 0,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Update an existing subject
  Future<void> updateSubject(String subjectId, Map<String, dynamic> data) async {
    await client.from('subjects').update(data).eq('id', subjectId);
  }

  /// Delete a subject (soft delete)
  Future<void> deleteSubject(String subjectId) async {
    await client.from('subjects').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_by': currentUserId,
    }).eq('id', subjectId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHAPTERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get chapters with their lessons for a subject
  Future<List<Map<String, dynamic>>> getChaptersWithLessons(
    String subjectId,
  ) async {
    final response = await client
        .from('chapters')
        .select('*, lessons(*)')
        .eq('subject_id', subjectId)
        .order('order_num');

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Add a new chapter to a subject
  Future<Map<String, dynamic>> addChapter({
    required String subjectId,
    required String title,
    String? description,
    int? orderNum,
  }) async {
    final response = await client
        .from('chapters')
        .insert({
          'subject_id': subjectId,
          'title': title,
          if (description != null) 'description': description,
          'order_num': orderNum ?? 0,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Update an existing chapter
  Future<void> updateChapter(String chapterId, Map<String, dynamic> data) async {
    await client.from('chapters').update(data).eq('id', chapterId);
  }

  /// Delete a chapter (cascading deletes its lessons)
  Future<void> deleteChapter(String chapterId) async {
    await client.from('chapters').delete().eq('id', chapterId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LESSONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Add a new lesson to a chapter
  Future<Map<String, dynamic>> addLesson({
    required String centerId,
    required String subjectId,
    required String chapterId,
    required String title,
    String? objectives,
    int? durationMins,
    int? orderNum,
  }) async {
    final response = await client
        .from('lessons')
        .insert({
          'center_id': centerId,
          'subject_id': subjectId,
          'chapter_id': chapterId,
          'title': title,
          if (objectives != null) 'objectives': objectives,
          'duration_mins': durationMins ?? 45,
          'order_num': orderNum ?? 0,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Update an existing lesson
  Future<void> updateLesson(String lessonId, Map<String, dynamic> data) async {
    await client.from('lessons').update(data).eq('id', lessonId);
  }

  /// Delete a lesson
  Future<void> deleteLesson(String lessonId) async {
    await client.from('lessons').delete().eq('id', lessonId);
  }
}
