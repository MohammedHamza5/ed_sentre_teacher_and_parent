/// Center Model - Maps to public.centers table
class CenterModel {
  final String id;
  final String name;
  final String adminUserId;
  final String? licenseNumber;
  final String? address;
  final String? city;
  final String? governorate;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final String subscriptionPlan;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final int maxStudents;
  final int maxTeachers;
  final int maxSubjects;
  final bool isActive;
  final bool isFrozen;
  final String? freezeReason;
  final Map<String, dynamic>? billingConfig;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CenterModel({
    required this.id,
    required this.name,
    required this.adminUserId,
    this.licenseNumber,
    this.address,
    this.city,
    this.governorate,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    this.subscriptionPlan = 'basic',
    this.subscriptionStart,
    this.subscriptionEnd,
    this.maxStudents = 50,
    this.maxTeachers = 10,
    this.maxSubjects = 20,
    this.isActive = true,
    this.isFrozen = false,
    this.freezeReason,
    this.billingConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'سنتر',
      adminUserId: json['admin_user_id'] as String,
      licenseNumber: json['license_number'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      governorate: json['governorate'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String?,
      subscriptionPlan: json['subscription_plan'] as String? ?? 'basic',
      subscriptionStart: json['subscription_start'] != null
          ? DateTime.parse(json['subscription_start'] as String)
          : null,
      subscriptionEnd: json['subscription_end'] != null
          ? DateTime.parse(json['subscription_end'] as String)
          : null,
      maxStudents: json['max_students'] as int? ?? 50,
      maxTeachers: json['max_teachers'] as int? ?? 10,
      maxSubjects: json['max_subjects'] as int? ?? 20,
      isActive: json['is_active'] as bool? ?? true,
      isFrozen: json['is_frozen'] as bool? ?? false,
      freezeReason: json['freeze_reason'] as String?,
      billingConfig: json['billing_config'] as Map<String, dynamic>?,
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
      'name': name,
      'admin_user_id': adminUserId,
      'license_number': licenseNumber,
      'address': address,
      'city': city,
      'governorate': governorate,
      'phone': phone,
      'email': email,
      'website': website,
      'logo_url': logoUrl,
      'subscription_plan': subscriptionPlan,
      'subscription_start': subscriptionStart?.toIso8601String(),
      'subscription_end': subscriptionEnd?.toIso8601String(),
      'max_students': maxStudents,
      'max_teachers': maxTeachers,
      'max_subjects': maxSubjects,
      'is_active': isActive,
      'is_frozen': isFrozen,
      'freeze_reason': freezeReason,
      'billing_config': billingConfig,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
