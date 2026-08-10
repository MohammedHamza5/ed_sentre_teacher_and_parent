import 'package:flutter/foundation.dart';

/// Teacher Enrollment Model - Maps to public.teacher_enrollments table
class TeacherEnrollmentModel {
  final String id;
  final String teacherUserId;
  final String teacherId;
  final String centerId;
  final String status;
  final String? salaryType; // 'percentage' or 'fixed'
  final double? salaryAmount;
  final DateTime createdAt;

  const TeacherEnrollmentModel({
    required this.id,
    required this.teacherUserId,
    required this.teacherId,
    required this.centerId,
    required this.status,
    this.salaryType,
    this.salaryAmount,
    required this.createdAt,
  });

  factory TeacherEnrollmentModel.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('🛠️ [TeacherEnrollmentModel] Parsing enrollment: ${json['id']}');
      return TeacherEnrollmentModel(
        id: json['id'] as String,
        teacherUserId: json['teacher_user_id'] as String,
        teacherId: json['teacher_id'] as String,
        centerId: json['center_id'] as String,
        status: json['status'] as String? ?? 'active',
        salaryType: json['salary_type'] as String?,
        salaryAmount: json['salary_amount'] != null ? double.tryParse(json['salary_amount'].toString()) : null,
        createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
    } catch (e, st) {
      debugPrint('❌ [TeacherEnrollmentModel] Error parsing JSON: $e');
      debugPrint('   👉 JSON Data: $json');
      debugPrint('   👉 StackTrace: $st');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_user_id': teacherUserId,
      'teacher_id': teacherId,
      'center_id': centerId,
      'status': status,
      'salary_type': salaryType,
      'salary_amount': salaryAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
