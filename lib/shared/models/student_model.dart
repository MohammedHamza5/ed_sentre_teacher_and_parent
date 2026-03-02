import 'enums.dart';

/// Student Model - Maps to public.students table
class StudentModel {
  final String id;
  final String? userId;
  final String? nationalId;
  final DateTime? birthDate;
  final String? gender;
  final String? address;
  final String? city;
  final String? governorate;
  final String? postalCode;
  final Map<String, dynamic>? emergencyContact;
  final Map<String, dynamic>? medicalInfo;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelation;
  final Map<String, dynamic>? previousEducation;
  final String? notes;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? deviceId;
  final Map<String, dynamic>? deviceInfo;
  final DateTime? lastLoginAt;
  final String? schoolName;
  final String? academicYear;
  final String? parentPhone;
  final String? studentCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentModel({
    required this.id,
    this.userId,
    this.nationalId,
    this.birthDate,
    this.gender,
    this.address,
    this.city,
    this.governorate,
    this.postalCode,
    this.emergencyContact,
    this.medicalInfo,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelation,
    this.previousEducation,
    this.notes,
    this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.deviceId,
    this.deviceInfo,
    this.lastLoginAt,
    this.schoolName,
    this.academicYear,
    this.parentPhone,
    this.studentCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      nationalId: json['national_id'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      governorate: json['governorate'] as String?,
      postalCode: json['postal_code'] as String?,
      emergencyContact: json['emergency_contact'] as Map<String, dynamic>?,
      medicalInfo: json['medical_info'] as Map<String, dynamic>?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      guardianRelation: json['guardian_relation'] as String?,
      previousEducation: json['previous_education'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      deviceId: json['device_id'] as String?,
      deviceInfo: json['device_info'] as Map<String, dynamic>?,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      schoolName: json['school_name'] as String?,
      academicYear: json['academic_year'] as String?,
      parentPhone: json['parent_phone'] as String?,
      studentCode: json['student_code'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'national_id': nationalId,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'address': address,
      'city': city,
      'governorate': governorate,
      'postal_code': postalCode,
      'emergency_contact': emergencyContact,
      'medical_info': medicalInfo,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'guardian_relation': guardianRelation,
      'previous_education': previousEducation,
      'notes': notes,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'device_id': deviceId,
      'device_info': deviceInfo,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'school_name': schoolName,
      'academic_year': academicYear,
      'parent_phone': parentPhone,
      'student_code': studentCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName => fullName ?? 'طالب';
}

/// Parent's child info with center details
class ChildWithCenters {
  final StudentModel student;
  final List<ChildCenterInfo> centers;

  const ChildWithCenters({required this.student, required this.centers});
}

/// Child's center enrollment info
class ChildCenterInfo {
  final String centerId;
  final String centerName;
  final String? centerLogo;
  final EnrollmentStatus status;
  final double? attendanceRate;
  final double? totalDue;
  final double? totalPaid;

  const ChildCenterInfo({
    required this.centerId,
    required this.centerName,
    this.centerLogo,
    required this.status,
    this.attendanceRate,
    this.totalDue,
    this.totalPaid,
  });

  factory ChildCenterInfo.fromJson(Map<String, dynamic> json) {
    return ChildCenterInfo(
      centerId: json['center_id'] as String,
      centerName: json['center_name'] as String? ?? 'سنتر',
      centerLogo: json['center_logo'] as String?,
      status: EnrollmentStatus.fromString(
        json['enrollment_status'] as String? ?? 'active',
      ),
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble(),
      totalDue: (json['total_due'] as num?)?.toDouble(),
      totalPaid: (json['total_paid'] as num?)?.toDouble(),
    );
  }
}
