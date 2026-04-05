import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../provider/auth_provider.dart';

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
      backgroundColor: AppColors.forestDeep,
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
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emeraldGreen.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'EdSentre',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDisplay,
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
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 48.h),

                  // Login Form in Glass Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: AppColors.darkBorder),
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
                                color: AppColors.textMuted,
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
                                  color: AppColors.accentVivid,
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
                                backgroundColor: AppColors.accentVivid,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: const CircularProgressIndicator(
                                        color: AppColors.forestDeep,
                                        strokeWidth: 3,
                                      ),
                                    )
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
                                  color: AppColors.textMuted,
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
                                    color: AppColors.emeraldGreen,
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
                      icon: const Icon(
                        Icons.support_agent_outlined,
                        color: AppColors.textMuted,
                      ),
                      label: Text(
                        'تواصل مع الدعم الفني',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textMuted,
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
      style: const TextStyle(color: AppColors.textDisplay),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.forestDeep.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.glassBorderHighlight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.glassBorderHighlight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.accentVivid),
        ),
        errorStyle: const TextStyle(color: AppColors.errorRed),
      ),
      validator: validator,
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'نسيت كلمة المرور؟',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: AppColors.textDisplay,
          ),
        ),
        content: Text(
          'الرجاء التواصل مع إدارة النظام عبر منصة الإدارة أو الدعم الفني لإعادة تعيين كلمة المرور بصلاحياتك.',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(color: AppColors.accentVivid),
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
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'التواصل مع الدعم الفني',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: AppColors.textDisplay,
          ),
        ),
        content: Text(
          'يرجى التواصل مع إدارة النظام عبر البريد الإلكتروني support@edsentre.com أو عبر الواتس آب للإبلاغ عن أي مشكلات فنية.',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(color: AppColors.accentVivid),
            ),
          ),
        ],
      ),
    );
  }
}
