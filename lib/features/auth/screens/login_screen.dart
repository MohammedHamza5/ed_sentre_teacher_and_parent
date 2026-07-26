import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../provider/auth_provider.dart';
import '../../../../core/config/app_config.dart';

/// Login Screen - User authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUpMode = false; // هل نحن في وضع التسجيل الجديد؟

  @override
  void dispose() {
    _identifierController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    if (_isSignUpMode) {
      // تسجيل حساب جديد
      final success = await authProvider.signUp(
        invitationCode: _identifierController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // بمجرد نجاح الدخول والتسجيل نذهب للوجهة مباشرة
        if (authProvider.isTeacher) {
          context.go('/teacher');
        } else if (authProvider.isParent) {
          context.go('/parent');
        }
      } else if (mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
        authProvider.clearError();
      }
    } else {
      // تسجيل دخول
      final success = await authProvider.signInWithIdentifier(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        if (authProvider.isTeacher) {
          context.go('/teacher');
        } else if (authProvider.isParent) {
          context.go('/parent');
        }
      } else if (mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
        authProvider.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 110.w,
                          height: 110.w,
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'EdSentre',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _isSignUpMode
                              ? 'إنشاء حساب جديد'
                              : 'تسجيل الدخول للنظام',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 48.h),

                  // Login Form in Glass Card
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(24.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSignUpMode) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'الاسم الكامل',
                              hint: 'أدخل اسمك الكامل',
                              icon: Icons.person_outlined,
                              action: TextInputAction.next,
                              validator: (value) {
                                if (_isSignUpMode &&
                                    (value == null || value.isEmpty)) {
                                  return 'الرجاء إدخال الاسم';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),
                          ],

                          _buildTextField(
                            controller: _identifierController,
                            label: _isSignUpMode
                                ? 'كود الدعوة'
                                : 'كود الدعوة أو رقم الهاتف',
                            hint: _isSignUpMode
                                ? 'أدخل كود الدعوة (مثال: T12345)'
                                : 'أدخل كود الدعوة أو رقم هاتفك',
                            icon: Icons.badge_outlined,
                            keyboardType: _isSignUpMode
                                ? TextInputType.text
                                : TextInputType.visiblePassword,
                            action: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return _isSignUpMode
                                    ? 'الرجاء إدخال كود الدعوة'
                                    : 'الرجاء إدخال الكود أو رقم الهاتف';
                              }
                              if (_isSignUpMode && value.trim().length < 6) {
                                return 'كود الدعوة غير صحيح';
                              }
                              return null;
                            },
                          ),

                          if (_isSignUpMode) ...[
                            SizedBox(height: 16.h),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'رقم الهاتف',
                              hint: 'أدخل رقم هاتفك الخاص',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              action: TextInputAction.next,
                              validator: (value) {
                                if (_isSignUpMode &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'الرجاء إدخال رقم الهاتف';
                                }
                                return null;
                              },
                            ),
                          ],

                          SizedBox(height: 16.h),

                          _buildTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: 'أدخل كلمة المرور',
                            icon: Icons.lock_outlined,
                            obscureText: _obscurePassword,
                            action: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال كلمة المرور';
                              }
                              if (value.length < 6) {
                                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 12.h),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () =>
                                  _showForgotPasswordDialog(context),
                              child: Text(
                                'نسيت كلمة المرور؟',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 24.h),

                          SizedBox(
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.sync_rounded, color: AppColors.forestDeep, size: 22.sp),
                                        SizedBox(width: 8.w),
                                        Text(
                                          _isSignUpMode ? 'جاري التسجيل...' : 'جاري التحقق...',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.forestDeep,
                                          ),
                                        ),
                                      ],
                                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 600.ms)
                                  : Text(
                                      _isSignUpMode
                                          ? 'إنشاء حساب'
                                          : 'تسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors
                                            .forestDeep, // Very dark text against vivid accent
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 16.h),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUpMode ? 'لديك حساب؟' : 'ليس لديك حساب؟',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                    _formKey.currentState?.reset();
                                  });
                                },
                                child: Text(
                                  _isSignUpMode
                                      ? 'تسجيل الدخول'
                                      : 'إنشاء حساب جديد',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 24.h),
                          const Divider(),
                          SizedBox(height: 16.h),
                          Text(
                            'الدخول التجريبي السريع (Demo Mode)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    setState(() => _isLoading = true);
                                    AppConfig.isDemoMode = true;
                                    final success = await context.read<AuthProvider>().signInWithIdentifier('demo_teacher', 'demo');
                                    setState(() => _isLoading = false);
                                    if (success && mounted) {
                                      context.go('/teacher');
                                    }
                                  },
                                  icon: const Icon(Icons.school, size: 18),
                                  label: const Text('معلم تجريبي'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    side: BorderSide(color: Colors.green[300]!),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    setState(() => _isLoading = true);
                                    AppConfig.isDemoMode = true;
                                    final success = await context.read<AuthProvider>().signInWithIdentifier('demo_parent', 'demo');
                                    setState(() => _isLoading = false);
                                    if (success && mounted) {
                                      context.go('/parent');
                                    }
                                  },
                                  icon: const Icon(Icons.family_restroom, size: 18),
                                  label: const Text('ولي أمر تجريبي'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    side: BorderSide(color: Colors.green[300]!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showSupportDialog(context),
                      icon: Icon(
                        Icons.support_agent_outlined,
                        color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                      ),
                      label: Text(
                        'تواصل مع الدعم الفني',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? action,
    void Function(String)? onSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
        hintStyle: TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.5)),
        hintText: hint,
        prefixIcon: Icon(icon, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorStyle: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      validator: validator,
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'نسيت كلمة المرور؟',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'الرجاء التواصل مع إدارة النظام عبر منصة الإدارة أو الدعم الفني لإعادة تعيين كلمة المرور بصلاحياتك.',
          style: TextStyle(fontSize: 14.sp, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.divider),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'حسناً',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'التواصل مع الدعم الفني',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'يرجى التواصل مع إدارة النظام عبر البريد الإلكتروني support@edsentre.com أو عبر الواتس آب للإبلاغ عن أي مشكلات فنية.',
          style: TextStyle(fontSize: 14.sp, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.divider),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'حسناً',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
