import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';
import '../base_repository.dart';

/// Auth & User Repository Mixin
/// Handles authentication, user profiles, invitation codes, and role management
mixin AuthRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // AUTH & USER
  // ═══════════════════════════════════════════════════════════════════════

  /// Get current authenticated user
  User? get currentUser => client.auth.currentUser;

  /// Sign in with email, code, or phone fallback
  Future<AuthResponse> signInWithIdentifier(
    String identifier,
    String password,
  ) async {
    final cleanIdentifier = identifier.trim();
    String emailToUse;

    // If it's already an email, use it directly
    if (cleanIdentifier.contains('@')) {
      emailToUse = cleanIdentifier.toLowerCase();
    } else if (cleanIdentifier.toUpperCase().startsWith('T') ||
        cleanIdentifier.toUpperCase().startsWith('P') ||
        cleanIdentifier.toUpperCase().startsWith('STD')) {
      emailToUse = '${cleanIdentifier.toUpperCase()}@edsentre.com';
    } else {
      // Phone number fallback (Assistants / Staff / Phone-based Users)
      try {
        final response = await client.rpc(
          'get_login_identifier_by_phone',
          params: {'p_phone': cleanIdentifier},
        );
        if (response != null && response.toString().isNotEmpty) {
          emailToUse = response.toString();
        } else {
          emailToUse = '$cleanIdentifier@assistant.edsentre.com';
        }
      } catch (e) {
        emailToUse = '$cleanIdentifier@assistant.edsentre.com';
      }
    }

    return await client.auth.signInWithPassword(
      email: emailToUse,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get user profile
  Future<UserModel?> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client.from('users').update(data).eq('id', userId);
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// تسجيل مستخدم جديد (Sign Up)
  Future<AuthResponse> signUp({
    required String invitationCode,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final pseudoEmail = '${invitationCode.toUpperCase()}@edsentre.com';
    final response = await client.auth.signUp(
      email: pseudoEmail,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );
    return response;
  }

  /// Check if user is actually a student (exists in students table)
  Future<bool> isActualStudent(String userId) async {
    try {
      final response = await client
          .from('students')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is actually a teacher (exists in teacher_enrollments)
  Future<bool> isActualTeacher(String userId) async {
    try {
      final response = await client
          .from('teacher_enrollments')
          .select('id')
          .eq('teacher_user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// تحديث بيانات المستخدم في جدول users
  Future<void> createOrUpdateUserRecord({
    required String userId,
    required String email,
    String? fullName,
    String? phone,
    String? role,
  }) async {
    await client.from('users').upsert({
      'id': userId,
      'email': email,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INVITATION CODES
  // ═══════════════════════════════════════════════════════════════════════

  /// التحقق من كود الدعوة (verify_invitation_code)
  Future<Map<String, dynamic>> verifyInvitationCode(String code) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 [Repo] Verify Code: $code - User: $currentUserId');
      }

      final response = await client.rpc(
        'verify_invitation_code',
        params: {'p_code': code},
      );

      if (kDebugMode) {
        debugPrint('✅ [Repo] Verify Code Result: $response');
      }

      final result = response as Map<String, dynamic>?;

      if (result == null || result['valid'] != true) {
        // RPC أرجع null أو غير صالح — نجرّب الجداول يدوياً
        try {
          if (kDebugMode) {
            debugPrint(
              '⚠️ [Repo] RPC returned null or invalid. Probing manual tables...',
            );
            debugPrint(
              '🔍 [Repo] Querying teacher_invitations WHERE code = $code',
            );
          }

          final teacherInvite = await client
              .from('teacher_invitations')
              .select()
              .eq('code', code)
              .maybeSingle();

          if (kDebugMode) {
            debugPrint('📊 [Repo] teacher_invitations result: $teacherInvite');
          }

          if (teacherInvite != null) {
            if (kDebugMode) {
              debugPrint(
                '✅ [Repo] Found in teacher_invitations: $teacherInvite',
              );
            }
            return {
              'valid': true,
              'type': 'teacher',
              'center_id': teacherInvite['center_id'],
              'center_name': 'Unknown Center (Manual)',
              'teacher_name': teacherInvite['teacher_name'],
            };
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ [Repo] No match in teacher_invitations');
              debugPrint(
                '🔍 [Repo] Querying teacher_enrollments WHERE invitation_code = $code',
              );
            }
          }

          final teacherEnrollment = await client
              .from('teacher_enrollments')
              .select()
              .eq('invitation_code', code)
              .maybeSingle();

          if (kDebugMode) {
            debugPrint(
              '📊 [Repo] teacher_enrollments result: $teacherEnrollment',
            );
          }

          if (teacherEnrollment != null) {
            if (kDebugMode) {
              debugPrint(
                '✅ [Repo] Found in teacher_enrollments: $teacherEnrollment',
              );
            }
            return {
              'valid': true,
              'type': 'teacher',
              'center_id': teacherEnrollment['center_id'],
              'center_name': 'Unknown Center (Via Enrollment)',
              'teacher_name': null,
            };
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ [Repo] No match in teacher_enrollments');
            }
          }

          final parentInvite = await client
              .from('parent_invitations')
              .select()
              .eq('code', code)
              .maybeSingle();

          if (parentInvite != null) {
            if (kDebugMode) {
              debugPrint('✅ [Repo] Found in parent_invitations: $parentInvite');
            }
            return {
              'valid': true,
              'type': 'parent',
              'student_id': parentInvite['student_id'],
              'student_name': 'Unknown Student (Manual)',
            };
          }
        } catch (probeError) {
          if (kDebugMode) {
            debugPrint('❌ [Repo] Manual Probe Failed: $probeError');
          }
        }

        return {'valid': false, 'error': 'Invalid code'};
      }

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Repo] Verify Code Error: $e');
      }
      rethrow;
    }
  }

  /// ربط ولي الأمر بابنه باستخدام كود الدعوة
  Future<Map<String, dynamic>> linkParentToChild(String code) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 [Repo] Link Parent: $code - User: $currentUserId');
      }

      final response = await client.rpc(
        'link_parent_to_child',
        params: {'p_code': code},
      );

      if (kDebugMode) {
        debugPrint('✅ [Repo] Link Parent Result: $response');
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Repo] Link Parent Error: $e');
      }
      rethrow;
    }
  }

  /// ربط المعلم بالسنتر باستخدام كود الدعوة
  Future<Map<String, dynamic>> claimTeacherInvitation(String code) async {
    if (kDebugMode) {
      debugPrint('🔄 [Repo] START Claim Teacher Invitation');
      debugPrint('➡️ Code: $code');
      debugPrint('👤 User: $currentUserId');
    }

    try {
      final response = await client.rpc(
        'claim_teacher_invitation',
        params: {'p_code': code},
      );

      if (kDebugMode) {
        debugPrint('✅ [Repo] RPC Success: $response');
      }

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        return result;
      }

      if (kDebugMode) {
        debugPrint(
          '⚠️ [Repo] RPC returned false success: '
          '${result['error'] ?? result['message']}',
        );
        debugPrint('⚠️ Proceeding to Manual Fallback...');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Repo] RPC Failed: $e');
        debugPrint('⚠️ Proceeding to Manual Fallback...');
      }
    }

    // ─── MANUAL FALLBACK LOGIC ────────────────────────────────────────────
    try {
      if (kDebugMode) {
        debugPrint('🔍 Querying teacher_enrollments for code: $code');
      }

      final enrollment = await client
          .from('teacher_enrollments')
          .select()
          .eq('invitation_code', code)
          .maybeSingle();

      if (kDebugMode) {
        debugPrint('📊 Enrollment Found: $enrollment');
      }

      if (enrollment != null) {
        final enrollmentId = enrollment['id'];
        final centerId = enrollment['center_id'];
        final existingTeacherId = enrollment['teacher_id'];

        if (kDebugMode) {
          debugPrint('🔍 Enrollment Teacher ID: $existingTeacherId');
        }

        String teacherProfileId;

        if (existingTeacherId != null) {
          if (kDebugMode) {
            debugPrint(
              '✅ Found PRE-EXISTING teacher profile (Admin Created): '
              '$existingTeacherId',
            );
          }

          await client
              .from('teachers')
              .update({'user_id': currentUserId})
              .eq('id', existingTeacherId);

          teacherProfileId = existingTeacherId;

          if (kDebugMode) {
            debugPrint(
              '✅ Linked User $currentUserId to Teacher $teacherProfileId',
            );
          }
        } else {
          if (kDebugMode) {
            debugPrint('🔍 Checking Teacher Profile for User: $currentUserId');
          }

          final existingProfile = await client
              .from('teachers')
              .select('id')
              .eq('user_id', currentUserId!)
              .maybeSingle();

          if (existingProfile != null) {
            teacherProfileId = existingProfile['id'];
            if (kDebugMode) {
              debugPrint(
                '✅ Found existing teacher profile for user: $teacherProfileId',
              );
            }
          } else {
            if (kDebugMode) {
              debugPrint('➕ Creating new teacher profile...');
            }
            final newProfile = await client
                .from('teachers')
                .insert({'user_id': currentUserId})
                .select('id')
                .single();
            teacherProfileId = newProfile['id'];
            if (kDebugMode) {
              debugPrint('✅ Created new teacher profile: $teacherProfileId');
            }
          }
        }

        if (kDebugMode) {
          debugPrint(
            '✏️ Attempting to FORCE UPDATE teacher_enrollments '
            '(Safe FK Handling)...',
          );
        }

        // 1. Update the teacher record so FK cascades propagate
        await client
            .from('teachers')
            .update({'user_id': currentUserId})
            .eq('id', teacherProfileId);

        // 2. Activate the specific enrollment claimed and clear code
        await client
            .from('teacher_enrollments')
            .update({'status': 'active', 'invitation_code': null})
            .eq('id', enrollmentId);

        if (kDebugMode) {
          debugPrint('✅ Manual Update Successful!');
          debugPrint('👤 Updating User Role to teacher...');
        }

        try {
          await client
              .from('users')
              .update({'role': 'teacher'})
              .eq('id', currentUserId!);
          if (kDebugMode) {
            debugPrint('✅ User Role Updated!');
          }
        } catch (eRole) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ Failed to update user role (might be already set): $eRole',
            );
          }
        }

        return {
          'success': true,
          'message': 'تم الربط بنجاح (Manual Fix)',
          'center_id': centerId,
          'center_name': 'Center (Manual)',
        };
      } else {
        if (kDebugMode) {
          debugPrint('❌ Enrollment not found with this code.');
        }
        return {'success': false, 'error': 'الكود غير صحيح'};
      }
    } catch (e2) {
      if (kDebugMode) {
        debugPrint('❌ Manual Fallback Failed: $e2');
      }
      return {'success': false, 'error': 'حدث خطأ في الربط: $e2'};
    }
  }
}
