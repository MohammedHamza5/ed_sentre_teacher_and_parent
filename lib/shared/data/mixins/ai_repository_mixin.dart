import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../base_repository.dart';

/// AI Repository Mixin
/// Handles AI-related operations like smart enrollment
mixin AIRepositoryMixin on BaseRepository {
  SupabaseClient get client;

  // ═══════════════════════════════════════════════════════════════════════
  // SMART ENROLLMENT (AI/LOGIC)
  // ═══════════════════════════════════════════════════════════════════════

  /// Suggest best groups for a student based on load balancing and schedule
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

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error suggesting best groups: $e');
      return [];
    }
  }
}
