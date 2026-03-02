/// Conversation Model - Maps to public.conversations table
class ConversationModel {
  final String id;
  final String studentId;
  final String teacherId;
  final String centerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCountStudent;
  final int unreadCountTeacher;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? teacherName;
  final String? teacherAvatar;
  final String? studentName;
  final String? studentAvatar;

  const ConversationModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.centerId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCountStudent = 0,
    this.unreadCountTeacher = 0,
    required this.createdAt,
    required this.updatedAt,
    this.teacherName,
    this.teacherAvatar,
    this.studentName,
    this.studentAvatar,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? json['conversation_id'] as String,
      studentId: json['student_id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      centerId: json['center_id'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCountStudent:
          json['unread_count_student'] as int? ??
          json['unread_count'] as int? ??
          0,
      unreadCountTeacher: json['unread_count_teacher'] as int? ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      teacherName: json['teacher_name'] as String?,
      teacherAvatar: json['teacher_avatar'] as String?,
      studentName: json['student_name'] as String?,
      studentAvatar: json['student_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'center_id': centerId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count_student': unreadCountStudent,
      'unread_count_teacher': unreadCountTeacher,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
