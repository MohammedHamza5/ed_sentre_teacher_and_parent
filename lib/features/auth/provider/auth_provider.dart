import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/config/app_config.dart';

/// AuthProvider - يدير حالة المصادقة ويحدد نوع المستخدم
///
/// الأنواع المسموح بها:
/// - teacher: المعلم
/// - parent: ولي الأمر
///
/// التدفق:
/// 1. تسجيل جديد (signUp) → شاشة إدخال كود الدعوة
/// 2. إدخال كود → ربط المستخدم بالسنتر/الطالب
/// 3. تسجيل دخول (signIn) → التحقق من الربط
class AuthProvider extends ChangeNotifier {
  final SupabaseRepository _repository;

  UserModel? _currentUser;
  TeacherModel? _teacherProfile;
  Map<String, dynamic>? _parentProfile;
  bool _isLoading = true;
  String? _error;
  bool _isUnauthorizedRole = false;
  bool _needsInvitationCode = false; // هل يحتاج إدخال كود؟
  Map<String, dynamic>? _pendingInvitationInfo; // معلومات الكود المُتحقق منه

  AuthProvider(this._repository) {
    _initAuth();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  TeacherModel? get teacherProfile => _teacherProfile;
  Map<String, dynamic>? get parentProfile => _parentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  UserRole? get userRole => _currentUser?.role;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;
  bool get isParent => _currentUser?.role == UserRole.parent;
  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isCoordinator => _currentUser?.role == UserRole.coordinator;
  bool get isUnauthorizedRole => _isUnauthorizedRole;
  bool get needsInvitationCode => _needsInvitationCode;
  Map<String, dynamic>? get pendingInvitationInfo => _pendingInvitationInfo;

  /// Initialize authentication state
  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    if (AppConfig.isDemoMode) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Listen to auth state changes
      _repository.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          await _loadUserProfile();
        } else {
          log.auth('User Signed Out (Auth State Change)');
          // مسح جميع البيانات عند تسجيل الخروج
          _currentUser = null;
          _teacherProfile = null;
          _parentProfile = null;
          _isUnauthorizedRole = false;
          _needsInvitationCode = false;
          _pendingInvitationInfo = null;
        }
        _isLoading = false;
        notifyListeners();
      });

      // Check current session
      final session = _repository.client.auth.currentSession;
      if (session != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load user profile based on role
  /// يحمل بيانات المستخدم حسب نوعه (معلم/ولي أمر)
  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _repository.getUserProfile();
      _isUnauthorizedRole = false;

      if (_currentUser != null) {
        var role = _currentUser!.role;
        log.auth(
          'Loading Profile for User: ${_currentUser!.id}',
          data: {'role': role.name, 'needsCode': _needsInvitationCode},
        );

        // التحقق من نوع المستخدم
        if (role == UserRole.student) {
          // Check if this is a REAL student or just a pending user
          // If they exist in the 'students' table, they are a real student -> KICK OUT
          // If not, they are likely a new user (teacher/parent) who hasn't linked yet -> ALLOW

          final isRealStudent = await _repository.isActualStudent(
            _currentUser!.id,
          );
          if (kDebugMode) {
            debugPrint(
              '🔍 [Auth] Is Real Student (in valid students table): $isRealStudent',
            );
          }

          if (isRealStudent) {
            if (kDebugMode) {
              debugPrint('❌ [Auth] Blocking Real Student - Signing Out');
            }
            _isUnauthorizedRole = true;
            _error =
                'هذا التطبيق مخصص للمعلمين وأولياء الأمور فقط.\nيرجى استخدام تطبيق الطالب.';
            await _repository.signOut();
            _currentUser = null;
            return;
          } else {
            // Check if they are actually a TEACHER (e.g. they claimed code but role wasn't updated)
            final isRealTeacher = await _repository.isActualTeacher(
              _currentUser!.id,
            );
            if (isRealTeacher) {
              if (kDebugMode) {
                debugPrint(
                  '✅ [Auth] User is actually a TEACHER (Updating Role...)',
                );
              }
              try {
                // Update role in DB
                await _repository.client
                    .from('users')
                    .update({'role': 'teacher'})
                    .eq('id', _currentUser!.id);
                // Reload profile
                _currentUser = await _repository.getUserProfile();
                _needsInvitationCode = false;
                // Recursive call or just set teacher profile
                _teacherProfile = await _repository.getTeacherByUserId(
                  _currentUser!.id,
                );
                notifyListeners();
                return;
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('❌ [Auth] Failed to update role: $e');
                }
              }
            }

            if (kDebugMode) {
              debugPrint(
                '✅ [Auth] Allowing Pending User (Default Student Role)',
              );
            }
            // We treat them as needing invitation code if they are not a real student
            // This might set it to true even if they just logged in, which is what we want
            // so they get redirected to invitation screen.
            _needsInvitationCode = true;
          }
        }

        if (role == UserRole.teacher ||
            _currentUser?.role == UserRole.teacher) {
          // Check updated role
          if (_currentUser?.role == UserRole.teacher) {
            role = UserRole.teacher; // Update local var
          }
          // تحميل بيانات المعلم
          _teacherProfile = await _repository.getTeacherByUserId(
            _currentUser!.id,
          );
        } else if (role == UserRole.parent) {
          // تحميل بيانات ولي الأمر
          _parentProfile = await _repository.getParentByUserId(
            _currentUser!.id,
          );
        } else if (role == UserRole.coordinator || role == UserRole.reception) {
          // المساعد / موظف الاستقبال يكتفي ببيانات المستخدم الأساسية للمصادقة
          if (kDebugMode) {
            debugPrint('✅ [Auth] Loading Staff/Coordinator Profile');
          }
        } else {
          // أي نوع آخر غير مسموح - إلا إذا كان في انتظار كود الدعوة
          if (_needsInvitationCode) {
            if (kDebugMode) {
              debugPrint(
                '✅ [Auth] Allowing Unknown Role (Needs Invitation Code)',
              );
            }
          } else {
            if (kDebugMode) {
              debugPrint('❌ [Auth] Blocking Unknown Role - Signing Out');
            }
            _isUnauthorizedRole = true;
            _error = 'هذا التطبيق مخصص للمعلمين وأولياء الأمور فقط.';
            await _repository.signOut();
            _currentUser = null;
            return;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Sign in with identifier (Code or Phone) and password
  Future<bool> signInWithIdentifier(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (identifier == 'DEMO1234' || identifier == '123456') {
      AppConfig.isDemoMode = true;
    }

    if (AppConfig.isDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      
      final isTeacher = identifier.toLowerCase().contains('teacher') || identifier == '123' || identifier == 'demo_teacher';
      
      _currentUser = UserModel(
        id: isTeacher ? 'demo_teacher_id' : 'demo_parent_id',
        email: isTeacher ? 'teacher@edsentre.demo' : 'parent@edsentre.demo',
        fullName: isTeacher ? 'أ. أحمد السيد (تجريبي)' : 'أبو محمد (تجريبي)',
        role: isTeacher ? UserRole.teacher : UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (isTeacher) {
        _teacherProfile = TeacherModel(
          id: 'teacher_0',
          userId: 'demo_teacher_id',
          fullName: 'أ. أحمد السيد (تجريبي)',
          phone: '01012345678',
          createdAt: DateTime.now().subtract(const Duration(days: 100)),
          updatedAt: DateTime.now(),
        );
      } else {
        _parentProfile = {
          'id': 'demo_parent_id',
          'name': 'أبو محمد (تجريبي)',
          'phone': '01112345678',
        };
      }
      
      _needsInvitationCode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      await _repository.signInWithIdentifier(identifier, password);
      // Ensure we have a session before loading profile
      if (_repository.client.auth.currentSession == null) {
        throw const AuthException('Login failed: No session created');
      }

      // Mark as potentially needing an invitation code if not verified
      // Verify role logic will handle the rest
      await _loadUserProfile();

      log.auth('Sign In Success', data: {'identifier': identifier});
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      log.auth('Sign In Failed (AuthException)', data: {'error': e.message});
      _error = _getAuthErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ أثناء تسجيل الدخول';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    if (AppConfig.isDemoMode) {
      _currentUser = null;
      _teacherProfile = null;
      _parentProfile = null;
      _isUnauthorizedRole = false;
      _needsInvitationCode = false;
      _pendingInvitationInfo = null;
      _error = null;
      _isLoading = false;
      AppConfig.isDemoMode = false;
      notifyListeners();
      return;
    }

    try {
      await _repository.signOut();
      _currentUser = null;
      _teacherProfile = null;
      _parentProfile = null;
      _isUnauthorizedRole = false;
      _needsInvitationCode = false; // مسح حالة الكود
      _pendingInvitationInfo = null; // مسح معلومات الكود المعلق
      _error = null; // مسح الأخطاء السابقة
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      await _repository.updateUserProfile(data);
      await _loadUserProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INVITATION CODE METHODS - نظام أكواد الدعوة
  // ═══════════════════════════════════════════════════════════════════════

  /// تسجيل حساب جديد برقم هاتف وكود دعوة
  Future<bool> signUp({
    required String invitationCode,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.signUp(
        invitationCode: invitationCode,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (response.user != null) {
        // تحديث حالة المستخدم لجلب البروفايل المبدئي
        _currentUser = await _repository.getUserProfile();
        // بمجرد التسجيل بنجاح، نقوم بربط كود الدعوة تلقائياً
        final bindSuccess = await useInvitationCode(invitationCode);
        if (bindSuccess) {
          _needsInvitationCode = false;
          return true; // UseInvitationCode already set isLoading to false
        } else {
          return false; // Error set by useInvitationCode
        }
      } else {
        _error = 'فشل التسجيل';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _error = _getAuthErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ أثناء التسجيل: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// التحقق من كود الدعوة قبل استخدامه
  Future<Map<String, dynamic>?> verifyInvitationCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.verifyInvitationCode(code);

      _isLoading = false;

      if (result['valid'] == true) {
        _pendingInvitationInfo = result;
        notifyListeners();
        return result;
      } else {
        _error = result['error'] ?? result['message'] ?? 'كود غير صحيح';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'خطأ في التحقق من الكود';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// استخدام كود الدعوة للربط
  Future<bool> useInvitationCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    if (kDebugMode) {
      debugPrint(
        '🔍 [Auth] Use Code: $code - CurrentUser: ${_currentUser?.id}',
      );
    }

    try {
      // تحديد نوع الكود
      final codeType = code.toUpperCase().startsWith('P')
          ? 'parent'
          : 'teacher';

      if (kDebugMode) debugPrint('🔍 [Auth] Code Type: $codeType');

      // ensure user has phone (required for link_parent_to_child / parents table)
      if (_currentUser?.phone == null || _currentUser!.phone!.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ [Auth] User has no phone. Attempting to set placeholder...',
          );
        }
        final phone =
            _repository.client.auth.currentUser?.userMetadata?['phone']
                as String? ??
            '0000000000'; // Default placeholder if absolutely nothing found

        await _repository.client
            .from('users')
            .update({'phone': phone})
            .eq('id', _currentUser!.id);

        // Reload profile to reflect changes locally
        _currentUser = await _repository.getUserProfile();
      }

      Map<String, dynamic> result;

      if (codeType == 'parent') {
        result = await _repository.linkParentToChild(code);
      } else {
        result = await _repository.claimTeacherInvitation(code);
      }

      if (kDebugMode) debugPrint('✅ [Auth] Use Code Result: $result');

      _isLoading = false;

      if (result['success'] == true) {
        _needsInvitationCode = false;
        // إعادة تحميل بيانات المستخدم
        await _loadUserProfile();
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'فشل في استخدام الكود';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// إضافة طفل آخر (لولي الأمر)
  Future<bool> addAnotherChild(String code) async {
    return await useInvitationCode(code);
  }

  /// تخطي إدخال الكود (للاختبار فقط أو الإلغاء)
  void skipInvitationCode() {
    _needsInvitationCode = false;
    _pendingInvitationInfo = null;
    notifyListeners();
  }

  /// Get localized auth error message
  String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'بيانات تسجيل الدخول غير صحيحة';
    }
    if (message.contains('Email not confirmed')) {
      return 'البريد الإلكتروني غير مؤكد';
    }
    if (message.contains('User not found')) {
      return 'المستخدم غير موجود';
    }
    return 'حدث خطأ أثناء تسجيل الدخول';
  }
}
