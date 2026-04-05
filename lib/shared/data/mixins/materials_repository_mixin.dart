import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_helper.dart';
import '../../../shared/models/models.dart';
import '../base_repository.dart';

/// Materials Repository Mixin
/// Handles study materials CRUD and file uploads
mixin MaterialsRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY MATERIALS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get study materials
  Future<List<StudyMaterialModel>> getStudyMaterials(String centerId) async {
    final response = await client.rpc(
      'get_student_materials',
      params: {'p_center_id': centerId},
    );

    return (response as List)
        .map((e) => StudyMaterialModel.fromJson(e))
        .toList();
  }

  /// Upload study material (teacher)
  Future<String> uploadStudyMaterial(Map<String, dynamic> data) async {
    final response = await client
        .from('study_materials')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Get teacher materials
  Future<List<Map<String, dynamic>>> getTeacherMaterials({
    required String centerId,
    String? courseId,
    String? fileType,
    int? limit,
    int? offset,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    // 1. Get teacher_id from teachers table
    final teacherRes = await client
        .from('teachers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (teacherRes == null) return [];
    final teacherId = teacherRes['id'] as String;

    // 2. Query study_materials using teacher_id
    var query = client
        .from('study_materials')
        .select('''
          *,
          courses:course_id(name)
        ''')
        .eq('center_id', centerId)
        .eq('teacher_id', teacherId);

    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }

    if (fileType != null) {
      query = query.eq('file_type', fileType);
    }

    var transform = query.order('created_at', ascending: false);
    if (limit != null && offset != null) {
      transform = transform.range(offset, offset + limit - 1);
    } else if (limit != null) {
      transform = transform.limit(limit);
    }
    final response = await transform;
    return (response as List).map((e) {
      final course = e['courses'] as Map<String, dynamic>?;
      return <String, dynamic>{
        ...Map<String, dynamic>.from(e as Map),
        'course_name': course?['name'],
      };
    }).toList();
  }

  /// Upload file to Supabase Storage (Materials)
  Future<String?> uploadStudyMaterialFile(File file, String path) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final fullPath = '$path/$fileName';

      await client.storage.from('study_materials').upload(fullPath, file);
      final publicUrl = client.storage
          .from('study_materials')
          .getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  /// Add new study material
  Future<void> addStudyMaterial(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final providedTeacherId = data['teacher_id'] as String?;
    if (providedTeacherId == null || providedTeacherId == userId) {
      final teacherRes = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      final resolvedTeacherId = teacherRes?['id'] as String?;
      if (resolvedTeacherId == null) {
        throw Exception('Teacher profile not found');
      }
      await client.from('study_materials').insert({
        ...data,
        'teacher_id': resolvedTeacherId,
      });
    } else {
      await client.from('study_materials').insert(data);
    }

    // Send notifications to all groups taking this course
    try {
      final courseId = data['course_id'] as String?;
      final title = data['title'] as String? ?? 'محتوى جديد';
      if (courseId != null) {
        // Get Course Name and Groups
        final courseRes = await client
            .from('courses')
            .select('name, groups(id)')
            .eq('id', courseId)
            .single();

        final courseName = courseRes['name'] as String? ?? 'مادة';
        final groups = courseRes['groups'] as List<dynamic>? ?? [];

        for (var g in groups) {
          final groupId = g['id'] as String;
          await NotificationHelper.notifyMaterialUploaded(
            groupId: groupId,
            courseName: courseName,
            materialTitle: title,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending material notification: $e');
    }
  }

  /// Update existing study material
  Future<void> updateStudyMaterial(String id, Map<String, dynamic> data) async {
    await client.from('study_materials').update(data).eq('id', id);
  }

  /// Delete study material
  Future<void> deleteStudyMaterial(String id) async {
    await client.from('study_materials').delete().eq('id', id);
  }

  /// Get teacher materials statistics
  Future<Map<String, dynamic>> getTeacherMaterialsStats(String centerId) async {
    final userId = currentUserId;
    if (userId == null) return {};

    // 1. Get teacher_id first
    final teacherRes = await client
        .from('teachers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (teacherRes == null) return {};
    final teacherId = teacherRes['id'] as String;

    final response = await client
        .from('study_materials')
        .select('id, file_type, download_count')
        .eq('center_id', centerId)
        .eq('teacher_id', teacherId);

    final materials = response as List;
    int totalMaterials = materials.length;
    int totalDownloads = 0;
    Map<String, int> byType = {};

    for (var m in materials) {
      totalDownloads += (m['download_count'] ?? 0) as int;
      final type = m['file_type'] as String? ?? 'other';
      byType[type] = (byType[type] ?? 0) + 1;
    }

    return {
      'total_materials': totalMaterials,
      'total_downloads': totalDownloads,
      'by_type': byType,
    };
  }
}
