import 'enums.dart';

/// Grade Model - Maps to public.grades table
class GradeModel {
  final String id;
  final String centerId;
  final String studentId;
  final String courseId;
  final ExamType examType;
  final double? score;
  final double? maxScore;
  final String? gradeLetter;
  final String? comments;
  final String? gradedBy;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? courseName;
  final String? studentName;

  const GradeModel({
    required this.id,
    required this.centerId,
    required this.studentId,
    required this.courseId,
    required this.examType,
    this.score,
    this.maxScore,
    this.gradeLetter,
    this.comments,
    this.gradedBy,
    this.gradedAt,
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    this.studentName,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] as String? ?? json['grade_id'] as String,
      centerId: json['center_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      examType: ExamType.fromString(json['exam_type'] as String? ?? 'quiz'),
      score: (json['score'] as num?)?.toDouble(),
      maxScore: (json['max_score'] as num?)?.toDouble(),
      gradeLetter: json['grade_letter'] as String?,
      comments: json['comments'] as String?,
      gradedBy: json['graded_by'] as String?,
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'] as String)
          : null,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      courseName: json['course_name'] as String?,
      studentName: json['student_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center_id': centerId,
      'student_id': studentId,
      'course_id': courseId,
      'exam_type': examType.name == 'final_' ? 'final' : examType.name,
      'score': score,
      'max_score': maxScore,
      'grade_letter': gradeLetter,
      'comments': comments,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get percentage {
    if (score == null || maxScore == null || maxScore == 0) return 0;
    return (score! / maxScore!) * 100;
  }

  String get displayGrade {
    if (gradeLetter != null) return gradeLetter!;
    final pct = percentage;
    if (pct >= 90) return 'A+';
    if (pct >= 85) return 'A';
    if (pct >= 80) return 'B+';
    if (pct >= 75) return 'B';
    if (pct >= 70) return 'C+';
    if (pct >= 65) return 'C';
    if (pct >= 60) return 'D+';
    if (pct >= 50) return 'D';
    return 'F';
  }
}

/// Student grade view from RPC
class StudentGradeView {
  final String gradeId;
  final String courseId;
  final String courseName;
  final String examType;
  final double score;
  final double maxScore;
  final double percentage;
  final String? comments;
  final DateTime createdAt;

  const StudentGradeView({
    required this.gradeId,
    required this.courseId,
    required this.courseName,
    required this.examType,
    required this.score,
    required this.maxScore,
    required this.percentage,
    this.comments,
    required this.createdAt,
  });

  factory StudentGradeView.fromJson(Map<String, dynamic> json) {
    return StudentGradeView(
      gradeId: json['grade_id'] as String,
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? 'غير محدد',
      examType: json['exam_type'] as String? ?? 'quiz',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 100,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      comments: json['comments'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String get displayGrade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 85) return 'A';
    if (percentage >= 80) return 'B+';
    if (percentage >= 75) return 'B';
    if (percentage >= 70) return 'C+';
    if (percentage >= 65) return 'C';
    if (percentage >= 60) return 'D+';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}
