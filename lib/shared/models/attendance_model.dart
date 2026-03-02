import 'enums.dart';

/// Attendance Model - Maps to public.attendance table
class AttendanceModel {
  final String id;
  final String centerId;
  final String? lessonId;
  final String? studentUserId;
  final String? studentId;
  final String? groupId;
  final String? sessionId;
  final AttendanceStatus status;
  final DateTime attendanceDate;
  final String? notes;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? attendanceMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? groupName;
  final String? courseName;
  final String? studentName;

  const AttendanceModel({
    required this.id,
    required this.centerId,
    this.lessonId,
    this.studentUserId,
    this.studentId,
    this.groupId,
    this.sessionId,
    required this.status,
    required this.attendanceDate,
    this.notes,
    this.checkInTime,
    this.checkOutTime,
    this.attendanceMethod,
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.courseName,
    this.studentName,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: (json['id'] as String?) ?? (json['attendance_id'] as String?) ?? '',
      centerId: json['center_id'] as String? ?? '',
      lessonId: json['lesson_id'] as String?,
      studentUserId: json['student_user_id'] as String?,
      studentId: json['student_id'] as String?,
      groupId: json['group_id'] as String?,
      sessionId: json['session_id'] as String?,
      status: AttendanceStatus.fromString(
        json['status'] as String? ?? 'absent',
      ),
      attendanceDate: json['attendance_date'] != null
          ? DateTime.parse(json['attendance_date'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      attendanceMethod: json['attendance_method'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      groupName: json['group_name'] as String?,
      courseName: json['course_name'] as String?,
      studentName: json['student_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center_id': centerId,
      'lesson_id': lessonId,
      'student_user_id': studentUserId,
      'student_id': studentId,
      'group_id': groupId,
      'session_id': sessionId,
      'status': status.name,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'notes': notes,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'attendance_method': attendanceMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Attendance statistics per course
class CourseAttendanceStats {
  final String courseId;
  final String courseName;
  final String teacherName;
  final int totalSessions;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double attendanceRate;

  const CourseAttendanceStats({
    required this.courseId,
    required this.courseName,
    required this.teacherName,
    required this.totalSessions,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.attendanceRate,
  });

  factory CourseAttendanceStats.fromJson(Map<String, dynamic> json) {
    return CourseAttendanceStats(
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? 'غير محدد',
      teacherName: json['teacher_name'] as String? ?? 'غير محدد',
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      presentCount: (json['present_count'] as num?)?.toInt() ?? 0,
      absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
      lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}
