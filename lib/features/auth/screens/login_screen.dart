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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48.h),

              // Logo and Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: 40.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'EdSentre',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _isSignUpMode ? 'حساب جديد' : 'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 48.h),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // حقل الاسم (للتسجيل الجديد فقط)
                    if (_isSignUpMode) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'الاسم الكامل',
                          hintText: 'أدخل اسمك الكامل',
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
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

                    // Identifier Field
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: _isSignUpMode ? TextInputType.text : TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _isSignUpMode ? 'كود الدعوة' : 'كود الدعوة أو رقم الهاتف',
                        hintText: _isSignUpMode ? 'أدخل كود الدعوة (مثال: T12345)' : 'أدخل كود الدعوة أو رقم هاتفك',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _isSignUpMode ? 'الرجاء إدخال كود الدعوة' : 'الرجاء إدخال الكود أو رقم الهاتف';
                        }
                        if (_isSignUpMode && value.trim().length < 6) {
                          return 'كود الدعوة غير صحيح';
                        }
                        return null;
                      },
                    ),

                    if (_isSignUpMode) ...[
                      SizedBox(height: 16.h),
                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف',
                          hintText: 'أدخل رقم هاتفك الخاص لاستخدامه للدخول لاحقاً',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        validator: (value) {
                          if (_isSignUpMode && (value == null || value.trim().isEmpty)) {
                            return 'الرجاء إدخال رقم الهاتف';
                          }
                          return null;
                        },
                      ),
                    ],

                    SizedBox(height: 16.h),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: 'أدخل كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
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

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('سيتم إضافة هذه الخاصية قريباً'),
                            ),
                          );
                        },
                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Login Button
                    SizedBox(
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isSignUpMode ? 'إنشاء حساب' : 'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // التبديل بين تسجيل الدخول وإنشاء حساب
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUpMode ? 'لديك حساب؟' : 'ليس لديك حساب؟',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
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
                            _isSignUpMode ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Contact Support
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: Open support chat or email
                  },
                  icon: const Icon(Icons.support_agent_outlined),
                  label: Text(
                    'تواصل مع الدعم الفني',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
