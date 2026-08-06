import 'package:flutter/foundation.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/config/ai_config.dart';

enum WeaknessType { grades, attendance, behavior }

enum WeaknessSeverity { low, medium, high }

class WeaknessInsight {
  final String subjectName;
  final WeaknessType type;
  final WeaknessSeverity severity;
  final String message;
  final String suggestion;

  WeaknessInsight({
    required this.subjectName,
    required this.type,
    required this.severity,
    required this.message,
    required this.suggestion,
  });
}

class AIWeaknessDetector {
  final SupabaseRepository _repository;
  final AiService _aiService;

  AIWeaknessDetector(this._repository, this._aiService);

  /// Analyze a student's performance and behavior to detect weaknesses (Local Rule-Based)
  Future<List<WeaknessInsight>> analyzeStudent({
    required String studentId,
    required String centerId,
  }) async {
    final insights = <WeaknessInsight>[];

    // 1. Analyze Grades (Assignments)
    try {
      final assignments = await _repository.getStudentAssignments(
        centerId: centerId,
        status: 'graded',
      );

      for (var a in assignments) {
        if (a.score != null && a.maxScore > 0) {
          final score = a.score!;
          final max = a.maxScore;
          final percentage = (score / max) * 100;

          if (percentage < 50) {
            insights.add(
              WeaknessInsight(
                subjectName: a.title,
                type: WeaknessType.grades,
                severity: WeaknessSeverity.high,
                message:
                    'Low score in ${a.title} (${percentage.toStringAsFixed(1)}%)',
                suggestion:
                    'Schedule a review session or assign remedial work.',
              ),
            );
          } else if (percentage < 70) {
            insights.add(
              WeaknessInsight(
                subjectName: a.title,
                type: WeaknessType.grades,
                severity: WeaknessSeverity.medium,
                message: 'Below average performance in ${a.title}',
                suggestion: 'Monitor progress in upcoming quizzes.',
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error analyzing grades: $e');
    }

    // 2. Analyze Attendance
    try {
      final attendanceStats = await _repository.getAttendanceStatsByCourse(
        studentId: studentId,
        centerId: centerId,
      );

      for (var stat in attendanceStats) {
        final absencePercentage = 100.0 - stat.attendanceRate;

        if (absencePercentage > 20) {
          insights.add(
            WeaknessInsight(
              subjectName: stat.courseName,
              type: WeaknessType.attendance,
              severity: WeaknessSeverity.high,
              message:
                  'High absence rate in ${stat.courseName} (${absencePercentage.toStringAsFixed(1)}%)',
              suggestion: 'Contact parents to discuss attendance issues.',
            ),
          );
        } else if (absencePercentage > 10) {
          insights.add(
            WeaknessInsight(
              subjectName: stat.courseName,
              type: WeaknessType.attendance,
              severity: WeaknessSeverity.medium,
              message: 'Frequent absence in ${stat.courseName}',
              suggestion: 'Remind student about attendance policy.',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error analyzing attendance: $e');
    }

    return insights;
  }

  /// Analyze using AI (Deep Analysis)
  Future<List<WeaknessInsight>> analyzeStudentWithAI({
    required String studentId,
    required String centerId,
  }) async {
    try {
      // Fetch Raw Data
      final assignments = await _repository.getStudentAssignments(
        centerId: centerId,
        status: 'graded',
      );
      final attendance = await _repository.getAttendanceStatsByCourse(
        studentId: studentId,
        centerId: centerId,
      );

      // Build Context String
      final buffer = StringBuffer();
      buffer.writeln('Assignments:');
      for (var a in assignments) {
        buffer.writeln(
          '- ${a.title} (${a.submittedAt ?? a.dueDate ?? "No Date"}): ${a.score}/${a.maxScore}',
        );
      }
      buffer.writeln('\nAttendance Stats:');
      for (var s in attendance) {
        buffer.writeln('- ${s.courseName}: ${s.attendanceRate}% attendance');
      }

      // Execute AI Task
      final response = await _aiService.router.executeTask(
        task: EdSentreTask.teacherAnalyzeClassPerformance,
        content: buffer.toString(),
      );

      if (response.isValid && response.json != null) {
        final insightsJson = response.json!['insights'] as List?;
        if (insightsJson == null) return [];

        return insightsJson.map((item) {
          return WeaknessInsight(
            subjectName: item['subject'] ?? 'General',
            type: _parseType(item['type']),
            severity: _parseSeverity(item['severity']),
            message: item['message'] ?? '',
            suggestion: item['suggestion'] ?? '',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error in AI analysis: $e');
      return [];
    }
  }

  WeaknessType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'attendance':
        return WeaknessType.attendance;
      case 'behavior':
        return WeaknessType.behavior;
      default:
        return WeaknessType.grades;
    }
  }

  WeaknessSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return WeaknessSeverity.high;
      case 'medium':
        return WeaknessSeverity.medium;
      case 'low':
      default:
        return WeaknessSeverity.low;
    }
  }

  /// Analyze a full group's performance with AI
  Future<Map<String, dynamic>?> analyzeGroupWithAI({
    required String groupId,
    required String centerId,
  }) async {
    try {
      // Fetch students in the group
      final students = await _repository.getGroupStudents(groupId);
      
      final buffer = StringBuffer();
      buffer.writeln('Group Size: ${students.length} students');
      buffer.writeln('Please provide a holistic analysis of this group including:');
      buffer.writeln('- Overall class health (a score out of 100)');
      buffer.writeln('- 3 Key strengths (what the group excels at)');
      buffer.writeln('- 3 Common weaknesses (where the group struggles collectively)');
      buffer.writeln('- 3 Actionable suggestions (e.g., remedial quiz, specific topics to review)');

      final response = await _aiService.router.executeTask(
        task: EdSentreTask.teacherAnalyzeClassPerformance,
        content: buffer.toString(),
      );

      if (response.isValid && response.json != null) {
        return response.json;
      }

      // NOTE: Returning null here is intentional. The widget hides itself when
      // AI returns no valid data. We must NEVER show hardcoded/fabricated
      // insights — a teacher could act on fake data and harm students.
      return null;
    } catch (e) {
      debugPrint('Error in AI Group analysis: $e');
      return null;
    }
  }
}
