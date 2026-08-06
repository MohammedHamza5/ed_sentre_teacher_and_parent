import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../base_repository.dart';

/// Curriculum AI Mixin
/// Handles curriculum intelligence: fetching official book structures,
/// importing curriculum into a center's subjects/chapters/lessons,
/// and retrieving available books per subject.
mixin CurriculumAiMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // AVAILABLE CURRICULUM BOOKS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns all curriculum books whose AI processing is complete.
  /// Used to show the teacher which official books are available for their subject.
  Future<List<Map<String, dynamic>>> getAvailableCurriculumSubjects() async {
    try {
      final response = await client.rpc('get_available_curriculum_subjects');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('[CurriculumAiMixin] getAvailableCurriculumSubjects error: $e');
      return [];
    }
  }

  /// Returns all available books for a specific subject name (case-insensitive).
  Future<List<Map<String, dynamic>>> getAvailableBooksForSubject(
    String subjectName,
  ) async {
    try {
      final response = await client
          .from('curriculum_books')
          .select('id, book_title, grade_level, grade_label, semester, academic_year')
          .ilike('subject_name', subjectName)
          .eq('processing_status', 'done')
          .order('grade_level')
          .order('semester');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('[CurriculumAiMixin] getAvailableBooksForSubject error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CURRICULUM STRUCTURE
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the extracted structure (units + lessons) for a given subject.
  /// Optionally filters by grade level and semester.
  Future<List<Map<String, dynamic>>> getCurriculumStructureForSubject({
    required String subjectName,
    String? gradeLevel,
    int? semester,
  }) async {
    try {
      final response = await client.rpc(
        'get_curriculum_structure_for_subject',
        params: {
          'p_subject_name': subjectName,
          if (gradeLevel != null) 'p_grade_level': gradeLevel,
          if (semester != null) 'p_semester': semester,
        },
      );
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('[CurriculumAiMixin] getCurriculumStructureForSubject error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // IMPORT CURRICULUM INTO CENTER
  // ═══════════════════════════════════════════════════════════════════════

  /// Imports the official curriculum structure into this center's
  /// subjects → chapters → lessons tables.
  ///
  /// Flow:
  /// 1. Calls get_curriculum_structure_for_subject RPC to get official structure.
  /// 2. Creates a new subject (or uses the provided subjectId) in the center.
  /// 3. Upserts chapters and lessons from the official structure.
  ///
  /// Returns the created subject ID if successful, null on failure.
  Future<String?> importCurriculumToCenter({
    required String centerId,
    required String subjectName,
    required String gradeLevel,
    required int semester,
    String? existingSubjectId,
    String? icon,
    String? color,
  }) async {
    try {
      // 1. Get the official structure
      final structure = await getCurriculumStructureForSubject(
        subjectName: subjectName,
        gradeLevel: gradeLevel,
        semester: semester,
      );

      if (structure.isEmpty) {
        debugPrint('[CurriculumAiMixin] No official curriculum found for $subjectName grade $gradeLevel sem $semester');
        return null;
      }

      // 2. Create subject in the center if no existing ID was provided
      String subjectId = existingSubjectId ?? '';
      if (subjectId.isEmpty) {
        final subjectRes = await client
            .from('subjects')
            .insert({
              'center_id': centerId,
              'name': subjectName,
              'grade_level': gradeLevel,
              'semester': semester,
              'icon': icon ?? '📚',
              'color': color ?? '#4F46E5',
              'order_num': 0,
            })
            .select('id')
            .single();
        subjectId = subjectRes['id'] as String;
      }

      // 3. Group structure rows by unit and create chapters + lessons
      final unitMap = <int, Map<String, dynamic>>{};
      for (final row in structure) {
        final unitNum = row['unit_number'] as int;
        unitMap.putIfAbsent(unitNum, () => {
          'unit_title': row['unit_title'] as String,
          'lessons': <Map<String, dynamic>>[],
        });

        final lessonTitle = row['lesson_title'] as String?;
        if (lessonTitle != null && lessonTitle.isNotEmpty) {
          (unitMap[unitNum]!['lessons'] as List<Map<String, dynamic>>).add({
            'lesson_title': lessonTitle,
            'lesson_objectives': row['lesson_objectives'],
            'duration_mins': row['duration_mins'] as int? ?? 45,
            'order_num': row['order_num'] as int,
          });
        }
      }

      int chapterOrder = 0;
      for (final entry in unitMap.entries) {
        // Insert chapter
        final chapterRes = await client
            .from('chapters')
            .insert({
              'subject_id': subjectId,
              'title': entry.value['unit_title'] as String,
              'description': 'وحدة رقم ${entry.key} — مستوردة من المنهج الرسمي',
              'order_num': chapterOrder++,
            })
            .select('id')
            .single();
        final chapterId = chapterRes['id'] as String;

        // Insert lessons for this chapter
        final lessons = entry.value['lessons'] as List<Map<String, dynamic>>;
        for (int i = 0; i < lessons.length; i++) {
          final lesson = lessons[i];
          await client.from('lessons').insert({
            'center_id': centerId,
            'subject_id': subjectId,
            'chapter_id': chapterId,
            'title': lesson['lesson_title'] as String,
            'objectives': (lesson['lesson_objectives'] as List?)?.join('\n'),
            'duration_mins': lesson['duration_mins'] as int,
            'order_num': i,
          });
        }
      }

      debugPrint('[CurriculumAiMixin] Successfully imported ${unitMap.length} units for $subjectName');
      return subjectId;
    } catch (e) {
      debugPrint('[CurriculumAiMixin] importCurriculumToCenter error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LESSON PROGRESS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get lesson progress for a student across all their subjects in a center.
  Future<List<Map<String, dynamic>>> getLessonProgressForStudent({
    required String studentId,
    required String centerId,
  }) async {
    try {
      final response = await client
          .from('lesson_progress')
          .select('*, lessons(title, chapter_id, subjects(name, grade_level, semester))')
          .eq('student_id', studentId)
          .eq('center_id', centerId);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('[CurriculumAiMixin] getLessonProgressForStudent error: $e');
      return [];
    }
  }

  /// Mark a lesson as completed for a student.
  Future<void> markLessonCompleted({
    required String lessonId,
    required String studentId,
    required String centerId,
  }) async {
    try {
      await client.from('lesson_progress').upsert({
        'lesson_id': lessonId,
        'student_id': studentId,
        'center_id': centerId,
        'status': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'lesson_id,student_id');
    } catch (e) {
      debugPrint('[CurriculumAiMixin] markLessonCompleted error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONTEXT BUILDER — used by AI Chat to enrich contextPayload
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the current academic semester based on the calendar month.
  /// Sept–Jan = 1, Feb–June = 2, July–Aug = 2 (summer).
  // NOTE: This matches the same logic in the Edge Function so there is
  // never a mismatch between what the client sends and what the server computes.
  int getCurrentSemester() {
    final month = DateTime.now().month;
    return (month >= 9 || month == 1) ? 1 : 2;
  }

  /// Builds the curriculum context payload for AI Chat.
  /// Fetches which official books are available for a given subject name.
  Future<Map<String, dynamic>> buildCurriculumContextPayload(
    String subjectName,
  ) async {
    try {
      final books = await getAvailableBooksForSubject(subjectName);
      if (books.isEmpty) {
        return {'curriculum_available': false, 'grade_levels': [], 'current_semester': getCurrentSemester()};
      }

      final gradeLevels = books.map((b) => b['grade_level'] as String).toSet().toList();
      return {
        'curriculum_available': true,
        'grade_levels': gradeLevels,
        'current_semester': getCurrentSemester(),
        'subjects_with_curriculum': books
            .map((b) => {
                  'grade': b['grade_level'],
                  'grade_label': b['grade_label'],
                  'semester': b['semester'],
                  'book_title': b['book_title'],
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('[CurriculumAiMixin] buildCurriculumContextPayload error: $e');
      return {'curriculum_available': false, 'grade_levels': [], 'current_semester': getCurrentSemester()};
    }
  }
}
