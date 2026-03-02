import 'enums.dart';

/// User Model - Maps to public.users table
class UserModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final UserRole role;
  final String? defaultCenterId;
  final String? lastSelectedCenterId;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
    required this.role,
    this.defaultCenterId,
    this.lastSelectedCenterId,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'مستخدم',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'student'),
      defaultCenterId: json['default_center_id'] as String?,
      lastSelectedCenterId: json['last_selected_center_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
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
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role.toJson(),
      'default_center_id': defaultCenterId,
      'last_selected_center_id': lastSelectedCenterId,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    UserRole? role,
    String? defaultCenterId,
    String? lastSelectedCenterId,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      defaultCenterId: defaultCenterId ?? this.defaultCenterId,
      lastSelectedCenterId: lastSelectedCenterId ?? this.lastSelectedCenterId,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
