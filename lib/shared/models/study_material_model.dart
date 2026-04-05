/// Study Material Model - Maps to public.study_materials table
class StudyMaterialModel {
  final String id;
  final String centerId;
  final String? courseId;
  final String? teacherId;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;
  final String? thumbnailUrl;
  final bool isPublished;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields
  final String? courseName;
  final String? teacherName;

  const StudyMaterialModel({
    required this.id,
    required this.centerId,
    this.courseId,
    this.teacherId,
    required this.title,
    this.description,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    this.thumbnailUrl,
    this.isPublished = true,
    this.downloadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    this.teacherName,
  });

  factory StudyMaterialModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialModel(
      id: json['id'] as String,
      centerId: json['center_id'] as String? ?? '',
      courseId: json['course_id'] as String?,
      teacherId: json['teacher_id'] as String?,
      title: json['title'] as String? ?? 'ملزمة',
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
      downloadCount: json['download_count'] as int? ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      courseName: json['course_name'] as String?,
      teacherName: json['teacher_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center_id': centerId,
      'course_id': courseId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'thumbnail_url': thumbnailUrl,
      'is_published': isPublished,
      'download_count': downloadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileTypeIcon {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'video':
        return '🎬';
      case 'image':
        return '🖼️';
      case 'document':
        return '📝';
      case 'link':
        return '🔗';
      default:
        return '📁';
    }
  }
}
