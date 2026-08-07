import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/models/models.dart';
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
        } else if (authProvider.isCoordinator || authProvider.userRole == UserRole.reception) {
          context.go('/assistant');
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
        } else if (authProvider.isCoordinator || authProvider.userRole == UserRole.reception) {
          context.go('/assistant');
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
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
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
                            SizedBox(height: 22.h),
                          ],

                            _buildTextField(
                              controller: _identifierController,
                              label: 'رقم الهاتف، الإيميل، أو كود الدعوة',
                              hint: 'أدخل بيانات تسجيل الدخول أو كود الدعوة',
                              icon: Icons.badge_outlined,
                            keyboardType: TextInputType.text,
                            action: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'الرجاء إدخال بيانات الدخول';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 22.h),

                          _buildTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: 'كلمة السر الخاصة بك (أو آخر 4 أرقام للمساعدين)',
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
                              final idText = _identifierController.text.trim();
                              final isPhone = RegExp(r'^[0-9+]{10,15}$').hasMatch(idText);
                              if (!isPhone && (value == null || value.trim().isEmpty)) {
                                return 'الرجاء إدخال كلمة المرور (أو إنشاء كلمة سر جديدة إذا كانت مرتك الأولى)';
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
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 4,
                                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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

                          SizedBox(height: 16.h),

                          // Smart Guidance Card
                          Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'إرشادات الدخول السريع:',
                                      style: TextStyle(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '• 🎓 المعلم المستقل: سجل الدخول مباشرة ببيانات حسابك الإداري (الإيميل/الهاتف وكلمة المرور).\n'
                                  '• 👨‍🏫 معلمي المراكز وأولياء الأمور: أدخل كود الدعوة وأنشئ كلمة سر خاصة بك تتيح لك الدخول بها دائماً.\n'
                                  '• 👨‍💼 المساعدين: أدخل رقم الهاتف (كلمة المرور الإفتراضية هي آخر 4 أرقام من رقم الهاتف).',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey.shade800,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
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
                                    final auth = context.read<AuthProvider>();
                                    final router = GoRouter.of(context);
                                    setState(() => _isLoading = true);
                                    AppConfig.isDemoMode = true;
                                    final success = await auth.signInWithIdentifier('demo_teacher', 'demo');
                                    if (!mounted) return;
                                    setState(() => _isLoading = false);
                                    if (success) {
                                      router.go('/teacher');
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
                                    final auth = context.read<AuthProvider>();
                                    final router = GoRouter.of(context);
                                    setState(() => _isLoading = true);
                                    AppConfig.isDemoMode = true;
                                    final success = await auth.signInWithIdentifier('demo_parent', 'demo');
                                    if (!mounted) return;
                                    setState(() => _isLoading = false);
                                    if (success) {
                                      router.go('/parent');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 15.5.sp,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 18.w),
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
        hintStyle: TextStyle(
          fontSize: 13.5.sp,
          height: 1.4,
          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)
              .withValues(alpha: 0.55),
        ),
        hintText: hint,
        hintMaxLines: 2,
        errorMaxLines: 3,
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24.sp,
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 56.w, minHeight: 48.h),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorStyle: TextStyle(
          fontSize: 13.sp,
          height: 1.3,
          color: Theme.of(context).colorScheme.error,
        ),
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
