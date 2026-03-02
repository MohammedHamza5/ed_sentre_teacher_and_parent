import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';

/// شاشة إدخال كود الدعوة
/// تُستخدم بعد التسجيل لربط المستخدم بالسنتر/الطالب
class InvitationCodeScreen extends StatefulWidget {
  const InvitationCodeScreen({super.key});

  @override
  State<InvitationCodeScreen> createState() => _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends State<InvitationCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  Map<String, dynamic>? _verifiedInfo;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    final authProvider = context.read<AuthProvider>();
    final code = _codeController.text.trim().toUpperCase();

    final result = await authProvider.verifyInvitationCode(code);

    setState(() {
      _isVerifying = false;
      // Only set info if valid
      if (result != null && result['valid'] == true) {
        _verifiedInfo = result;
      } else {
        _verifiedInfo = null;
      }
    });

    if (!mounted) return;

    if (result == null || result['valid'] != true) {
      final error = result?['error'] ?? authProvider.error ?? 'كود غير صحيح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _useCode() async {
    final authProvider = context.read<AuthProvider>();
    final code = _codeController.text.trim().toUpperCase();

    final success = await authProvider.useInvitationCode(code);

    if (success && mounted) {
      // التوجيه حسب نوع المستخدم
      final role = authProvider.userRole;
      if (role?.name == 'teacher') {
        context.go('/teacher');
      } else if (role?.name == 'parent') {
        context.go('/parent');
      } else {
        context.go('/login');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'فشل في استخدام الكود'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('كود الدعوة'),
        centerTitle: true,
        actions: [
          // زر تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // أيقونة
                Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // عنوان
                Text(
                  'أدخل كود الدعوة',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // وصف
                Text(
                  'أدخل الكود الذي حصلت عليه من إدارة السنتر\nللربط بحسابك',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // حقل الكود
                TextFormField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'P1A2B3C4',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      letterSpacing: 4,
                    ),
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'أدخل الكود';
                    }
                    if (value.length < 8) {
                      return 'الكود يجب أن يكون 8 أحرف';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    // إعادة تعيين التحقق عند تغيير الكود
                    if (_verifiedInfo != null) {
                      setState(() => _verifiedInfo = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // معلومات الكود المُتحقق منه
                if (_verifiedInfo != null) ...[
                  _buildVerifiedInfoCard(),
                  const SizedBox(height: 16),
                ],

                // زر التحقق
                if (_verifiedInfo == null)
                  ElevatedButton.icon(
                    onPressed: _isVerifying ? null : _verifyCode,
                    icon: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      _isVerifying ? 'جارٍ التحقق...' : 'تحقق من الكود',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                // زر تأكيد الربط
                if (_verifiedInfo != null) ...[
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton.icon(
                        onPressed: auth.isLoading ? null : _useCode,
                        icon: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          auth.isLoading ? 'جارٍ الربط...' : 'تأكيد الربط',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // ملاحظة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'الكود يبدأ بـ P لولي الأمر أو T للمعلم',
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedInfoCard() {
    final info = _verifiedInfo!;
    final type = info['type'] as String?;
    final isParent = type == 'parent';

    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // أيقونة النجاح
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  'كود صحيح!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // نوع الحساب
            _buildInfoRow(
              'نوع الحساب',
              isParent ? 'ولي أمر' : 'معلم',
              isParent ? Icons.family_restroom : Icons.school,
            ),

            // اسم السنتر
            if (info['center_name'] != null)
              _buildInfoRow('السنتر', info['center_name'], Icons.business),

            // اسم الطالب (لولي الأمر)
            if (isParent && info['student_name'] != null)
              _buildInfoRow('الطالب', info['student_name'], Icons.person),

            // اسم المعلم
            if (!isParent && info['teacher_name'] != null)
              _buildInfoRow('الاسم', info['teacher_name'], Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// تنسيق النص للأحرف الكبيرة
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
