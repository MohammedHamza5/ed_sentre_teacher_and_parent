/// Teacher Model - Maps to public.teachers table
class TeacherModel {
  final String id;
  final String userId;
  final String? nationalId;
  final DateTime? birthDate;
  final String? gender;
  final String? address;
  final String? city;
  final String? governorate;
  final Map<String, dynamic>? qualifications;
  final int experienceYears;
  final List<String>? specializations;
  final Map<String, dynamic>? certificates;
  final String? cvUrl;
  final String? linkedinUrl;
  final Map<String, dynamic>? emergencyContact;
  final Map<String, dynamic>? bankAccount;
  final String? notes;
  final String? email;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from user join
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  const TeacherModel({
    required this.id,
    required this.userId,
    this.nationalId,
    this.birthDate,
    this.gender,
    this.address,
    this.city,
    this.governorate,
    this.qualifications,
    this.experienceYears = 0,
    this.specializations,
    this.certificates,
    this.cvUrl,
    this.linkedinUrl,
    this.emergencyContact,
    this.bankAccount,
    this.notes,
    this.email,
    this.rating = 0,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nationalId: json['national_id'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      governorate: json['governorate'] as String?,
      qualifications: json['qualifications'] as Map<String, dynamic>?,
      experienceYears: json['experience_years'] as int? ?? 0,
      specializations: (json['specializations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      certificates: json['certificates'] as Map<String, dynamic>?,
      cvUrl: json['cv_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      emergencyContact: json['emergency_contact'] as Map<String, dynamic>?,
      bankAccount: json['bank_account'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      email: json['email'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      fullName:
          json['full_name'] as String? ??
          json['users']?['full_name'] as String?,
      phone: json['phone'] as String? ?? json['users']?['phone'] as String?,
      avatarUrl:
          json['avatar_url'] as String? ??
          json['users']?['avatar_url'] as String?,
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
      'qualifications': qualifications,
      'experience_years': experienceYears,
      'specializations': specializations,
      'certificates': certificates,
      'cv_url': cvUrl,
      'linkedin_url': linkedinUrl,
      'emergency_contact': emergencyContact,
      'bank_account': bankAccount,
      'notes': notes,
      'email': email,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName => fullName ?? 'معلم';
}
