import 'enums.dart';

/// Assignment Model - Maps to public.assignments table
class AssignmentModel {
  final String id;
  final String centerId;
  final String? subjectId;
  final String? courseId;
  final String? classroomId;
  final String? teacherUserId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final double maxScore;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? courseName;
  final String? teacherName;
  final List<dynamic>? questions;

  const AssignmentModel({
    required this.id,
    required this.centerId,
    this.subjectId,
    this.courseId,
    this.classroomId,
    this.teacherUserId,
    required this.title,
    this.description,
    this.dueDate,
    this.maxScore = 100,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    this.teacherName,
    this.questions,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String? ?? json['assignment_id'] as String,
      centerId: json['center_id'] as String? ?? '',
      subjectId: json['subject_id'] as String?,
      courseId: json['course_id'] as String?,
      classroomId: json['classroom_id'] as String?,
      teacherUserId: json['teacher_user_id'] as String?,
      title: json['title'] as String? ?? 'واجب',
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 100,
      fileUrl: json['file_url'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      courseName: json['course_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      questions: json['questions'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center_id': centerId,
      'subject_id': subjectId,
      'course_id': courseId,
      'classroom_id': classroomId,
      'teacher_user_id': teacherUserId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'max_score': maxScore,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'questions': questions,
    };
  }

  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!);
}

/// Assignment with submission info for student view
class AssignmentWithSubmission {
  final String assignmentId;
  final String title;
  final String? description;
  final String courseId;
  final String courseName;
  final DateTime? dueDate;
  final double maxScore;
  final String? submissionId;
  final DateTime? submittedAt;
  final double? score;
  final String? feedback;
  final AssignmentStatus status;
  final List<dynamic>? questions;

  const AssignmentWithSubmission({
    required this.assignmentId,
    required this.title,
    this.description,
    required this.courseId,
    required this.courseName,
    this.dueDate,
    required this.maxScore,
    this.submissionId,
    this.submittedAt,
    this.score,
    this.feedback,
    required this.status,
    this.questions,
  });

  factory AssignmentWithSubmission.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    AssignmentStatus status;
    if (statusStr == 'graded') {
      status = AssignmentStatus.graded;
    } else if (statusStr == 'submitted') {
      status = AssignmentStatus.submitted;
    } else {
      status = AssignmentStatus.pending;
    }

    return AssignmentWithSubmission(
      assignmentId: json['assignment_id'] as String,
      title: json['title'] as String? ?? 'واجب',
      description: json['description'] as String?,
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? 'غير محدد',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 100,
      submissionId: json['submission_id'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      status: status,
      questions: json['questions'] as List<dynamic>?,
    );
  }
}

/// Submission Model for grading
class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentUserId;
  final String? submissionText;
  final List<String>? fileUrls;
  final DateTime submittedAt;
  final double? score;
  final String? feedback;
  final String? gradedBy;
  final DateTime? gradedAt;

  // Additional fields from joins
  final String? studentName;
  final String? studentAvatar;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentUserId,
    this.submissionText,
    this.fileUrls,
    required this.submittedAt,
    this.score,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    this.studentName,
    this.studentAvatar,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentUserId: json['student_user_id'] as String,
      submissionText: json['submission_text'] as String?,
      fileUrls: (json['file_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      gradedBy: json['graded_by'] as String?,
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'] as String)
          : null,
      studentName: json['student_name'] as String?,
      studentAvatar: json['student_avatar'] as String?,
    );
  }

  bool get isGraded => score != null;
}
