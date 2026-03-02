/// Course Model - Maps to public.courses table
class CourseModel {
  final String id;
  final String centerId;
  final String name;
  final String code;
  final String? description;
  final String? level;
  final String? academicTerm;
  final String? color;
  final double? fee;
  final String? feeType;
  final String? teacherId;
  final String? gradeLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? teacherName;

  const CourseModel({
    required this.id,
    required this.centerId,
    required this.name,
    required this.code,
    this.description,
    this.level,
    this.academicTerm,
    this.color,
    this.fee,
    this.feeType,
    this.teacherId,
    this.gradeLevel,
    required this.createdAt,
    required this.updatedAt,
    this.teacherName,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      centerId: json['center_id'] as String,
      name: json['name'] as String? ?? 'مادة',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      level: json['level'] as String?,
      academicTerm: json['academic_term'] as String?,
      color: json['color'] as String?,
      fee: (json['fee'] as num?)?.toDouble(),
      feeType: json['fee_type'] as String?,
      teacherId: json['teacher_id'] as String?,
      gradeLevel: json['grade_level'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      teacherName: json['teacher_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center_id': centerId,
      'name': name,
      'code': code,
      'description': description,
      'level': level,
      'academic_term': academicTerm,
      'color': color,
      'fee': fee,
      'fee_type': feeType,
      'teacher_id': teacherId,
      'grade_level': gradeLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
