import 'enums.dart';

/// Group Model - Maps to public.groups table
class GroupModel {
  final String id;
  final String centerId;
  final String courseId;
  final String? teacherId;
  final String groupName;
  final String? groupCode;
  final String? gradeLevel;
  final String? description;
  final int maxStudents;
  final int currentStudents;
  final int? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final double? monthlyFee;
  final double? sessionPrice;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? courseName;
  final String? teacherName;

  const GroupModel({
    required this.id,
    required this.centerId,
    required this.courseId,
    this.teacherId,
    required this.groupName,
    this.groupCode,
    this.gradeLevel,
    this.description,
    this.maxStudents = 30,
    this.currentStudents = 0,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.monthlyFee,
    this.sessionPrice,
    this.status = 'active',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    this.teacherName,
    this.schedules = const [],
  });

  final List<ScheduleItem> schedules;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      centerId: json['center_id'] as String,
      courseId: json['course_id'] as String,
      teacherId: json['teacher_id'] as String?,
      groupName: json['group_name'] as String? ?? 'مجموعة',
      groupCode: json['group_code'] as String?,
      gradeLevel: json['grade_level'] as String?,
      description: json['description'] as String?,
      maxStudents: json['max_students'] as int? ?? 30,
      currentStudents: json['current_students'] as int? ?? 0,
      dayOfWeek: json['day_of_week'] as int?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      monthlyFee: (json['monthly_fee'] as num?)?.toDouble(),
      sessionPrice: (json['session_price'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      courseName: json['course_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      schedules: [], // Populated manually or via separate join
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center_id': centerId,
      'course_id': courseId,
      'teacher_id': teacherId,
      'group_name': groupName,
      'group_code': groupCode,
      'grade_level': gradeLevel,
      'description': description,
      'max_students': maxStudents,
      'current_students': currentStudents,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'monthly_fee': monthlyFee,
      'session_price': sessionPrice,
      'status': status,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isFull => currentStudents >= maxStudents;

  DayOfWeek? get day =>
      dayOfWeek != null ? DayOfWeek.fromInt(dayOfWeek!) : null;

  GroupModel copyWith({
    List<ScheduleItem>? schedules,
    String? startTime,
    String? endTime,
    int? dayOfWeek,
  }) {
    return GroupModel(
      id: id,
      centerId: centerId,
      courseId: courseId,
      teacherId: teacherId,
      groupName: groupName,
      groupCode: groupCode,
      gradeLevel: gradeLevel,
      description: description,
      maxStudents: maxStudents,
      currentStudents: currentStudents,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      monthlyFee: monthlyFee,
      sessionPrice: sessionPrice,
      status: status,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      courseName: courseName,
      teacherName: teacherName,
      schedules: schedules ?? this.schedules,
    );
  }
}

/// Schedule item for weekly view
class ScheduleItem {
  final String id;
  final String? groupId;
  final String? courseId;
  final String courseName;
  final String groupName;
  final String teacherName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? roomName;
  final String centerId;

  const ScheduleItem({
    required this.id,
    this.groupId,
    this.courseId,
    required this.courseName,
    required this.groupName,
    required this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomName,
    required this.centerId,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['schedule_id'] as String? ?? json['id'] as String,
      groupId: json['group_id'] as String?,
      courseId: json['course_id'] as String?,
      courseName: json['course_name'] as String? ?? 'غير محدد',
      groupName: json['group_name'] as String? ?? 'مجموعة',
      teacherName: json['teacher_name'] as String? ?? 'غير محدد',
      dayOfWeek: json['day_of_week'] is int
          ? DayOfWeek.fromInt(json['day_of_week'] as int).englishName
          : json['day_of_week'] as String? ?? 'Unknown',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      roomName: json['room_name'] as String?,
      centerId: json['center_id'] as String? ?? '',
    );
  }

  DayOfWeek get day => DayOfWeek.fromString(dayOfWeek);
}
