import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/models.dart';
import '../base_repository.dart';

/// Assignment Repository Mixin
/// Handles assignments and submissions CRUD operations
mixin AssignmentRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get student assignments (with submission status)
  Future<List<AssignmentWithSubmission>> getStudentAssignments({
    String? centerId,
    String? subjectId,
    String? status,
  }) async {
    final response = await client.rpc(
      'get_student_assignments',
      params: {
        'p_center_id': centerId,
        'p_subject_id': subjectId,
        'p_status': status,
      },
    );

    final now = DateTime.now();
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((item) {
          final settings = item['settings'];
          Map<String, dynamic>? settingsMap;
          if (settings is Map) {
            settingsMap = Map<String, dynamic>.from(settings);
          } else if (settings is String) {
            try {
              settingsMap = Map<String, dynamic>.from(
                jsonDecode(settings) as Map,
              );
            } catch (_) {}
          }
          final publishAt = settingsMap?['publish_at'];
          if (publishAt is String) {
            final publishDate = DateTime.tryParse(publishAt);
            if (publishDate != null && now.isBefore(publishDate)) {
              return false;
            }
          }
          final archived = settingsMap?['archived'];
          if (archived == true) return false;
          return true;
        })
        .map((e) => AssignmentWithSubmission.fromJson(e))
        .toList();
  }

  /// Create assignment (teacher)
  Future<String> createAssignment(Map<String, dynamic> data) async {
    final response = await client
        .from('assignments')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Submit assignment (student)
  Future<void> submitAssignment({
    required String assignmentId,
    String? submissionText,
    List<String>? fileUrls,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client.from('assignment_submissions').insert({
      'assignment_id': assignmentId,
      'student_user_id': userId,
      'submission_text': submissionText,
      'file_urls': fileUrls,
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }

  /// Grade assignment (teacher)
  Future<void> gradeSubmission({
    required String submissionId,
    required double score,
    String? feedback,
  }) async {
    final userId = currentUserId;
    await client
        .from('assignment_submissions')
        .update({
          'score': score,
          'feedback': feedback,
          'graded_by': userId,
          'graded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', submissionId);
  }

  /// Get submissions for an assignment (teacher)
  Future<List<SubmissionModel>> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final response = await client
        .from('assignment_submissions')
        .select(
          '*, users!assignment_submissions_student_user_id_fkey(full_name, avatar_url)',
        )
        .eq('assignment_id', assignmentId)
        .neq('status', 'in_progress')
        .order('submitted_at', ascending: false);

    return (response as List).map((e) {
      final user = e['users'] as Map<String, dynamic>?;
      return SubmissionModel.fromJson({
        ...e,
        'student_name': user?['full_name'],
        'student_avatar': user?['avatar_url'],
      });
    }).toList();
  }

  /// Get teacher assignments (واجبات المعلم)
  Future<List<Map<String, dynamic>>> getTeacherAssignments({
    required String centerId,
    String? courseId,
    int? limit,
    int? offset,
  }) async {
    final userId = currentUserId;
    debugPrint(
      '📥 SupabaseRepository: getTeacherAssignments for userId: $userId, centerId: $centerId',
    );
    if (userId == null) return [];

    try {
      var query = client
          .from('assignments')
          .select('*, assignment_submissions(count)')
          .eq('center_id', centerId)
          .eq('teacher_user_id', userId)
          .isFilter('deleted_at', null);

      if (courseId != null) {
        query = query.eq('course_id', courseId);
      }

      var transform = query.order('created_at', ascending: false);
      if (limit != null && offset != null) {
        transform = transform.range(offset, offset + limit - 1);
      } else if (limit != null) {
        transform = transform.limit(limit);
      }
      final response = await transform;
      debugPrint(
        '✅ SupabaseRepository: Found ${(response as List).length} assignments',
      );

      return (response as List).map((e) {
        return Map<String, dynamic>.from(e as Map);
      }).toList();
    } catch (e) {
      debugPrint("❌ SupabaseRepository: Error fetching assignments: $e");
      return [];
    }
  }

  /// Update assignment (تعديل واجب)
  Future<void> updateAssignment(String id, Map<String, dynamic> data) async {
    await client.from('assignments').update(data).eq('id', id);
  }

  /// Add new assignment
  Future<void> addAssignment(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    // Extract questions and remove from main assignment payload
    final questionsList = data['questions'] as List<dynamic>?;
    data.remove('questions');

    // 1. Insert Assignment
    final response = await client
        .from('assignments')
        .insert({
          ...data,
          'teacher_user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final assignmentId = response['id'] as String;

    // 2. Insert Questions if they exist
    if (questionsList != null && questionsList.isNotEmpty) {
      final formattedQuestions = questionsList.asMap().entries.map((entry) {
        final q = entry.value as Map<String, dynamic>;

        // Map string types to enum
        String type = 'mcq';
        if (q['type'] == 'true_false' || q['type'] == 'trueFalse') {
          type = 'true_false';
        }
        if (q['type'] == 'short_answer' || q['type'] == 'shortAnswer') {
          type = 'short_answer';
        }
        if (q['type'] == 'essay') type = 'essay';

        return {
          'id':
              q['id']?.toString() ??
              '${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
          'assignment_id': assignmentId,
          'text': q['text'] ?? '',
          'type': type,
          'marks': q['points'] ?? 1.0,
          'options': q['options'] ?? [],
          'correct_answer':
              q['correct_answer'] ?? q['correct_option_index']?.toString(),
          'order_index': entry.key,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await client.from('exam_questions').insert(formattedQuestions);
    }
  }

  /// Delete assignment (soft delete)
  Future<void> deleteAssignment(String id) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    await client
        .from('assignments')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'deleted_by': userId,
        })
        .eq('id', id)
        .eq('teacher_user_id', userId);
  }

  /// Get assignment statistics for teacher
  Future<Map<String, dynamic>> getTeacherAssignmentStats(
    String centerId,
  ) async {
    final userId = currentUserId;
    if (userId == null) return {};

    final assignmentsResponse = await client
        .from('assignments')
        .select('id')
        .eq('center_id', centerId)
        .eq('teacher_user_id', userId)
        .isFilter('deleted_at', null);

    final totalAssignments = (assignmentsResponse as List).length;

    final pendingResponse = await client
        .from('assignment_submissions')
        .select('id, assignments!inner(teacher_user_id, center_id)')
        .isFilter('score', null);

    int pendingGrading = 0;
    for (var sub in (pendingResponse as List)) {
      final assignment = sub['assignments'] as Map<String, dynamic>?;
      if (assignment?['teacher_user_id'] == userId &&
          assignment?['center_id'] == centerId) {
        pendingGrading++;
      }
    }

    return {
      'total_assignments': totalAssignments,
      'pending_grading': pendingGrading,
    };
  }
}
