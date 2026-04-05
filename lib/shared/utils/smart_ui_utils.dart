/// Smart UI Utils - أدوات ذكية للواجهة
/// تحسينات على تجربة المستخدم
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/errors/error_handler.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Smart Snackbar - رسائل ذكية
// ═══════════════════════════════════════════════════════════════════════════

/// رسائل ذكية مع أنواع مختلفة
class SmartSnackbar {
  SmartSnackbar._();

  /// نجاح ✓
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green[700]!,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// خطأ ✗
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red[700]!,
      duration: duration,
      onAction: onRetry,
      actionLabel: onRetry != null ? 'إعادة' : null,
    );
  }

  /// تحذير ⚠
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber,
      backgroundColor: Colors.orange[700]!,
      duration: duration,
    );
  }

  /// معلومات ℹ
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: Colors.blue[700]!,
      duration: duration,
    );
  }

  /// تحميل ⏳
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> loading(
    BuildContext context,
    String message,
  ) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(minutes: 5),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// من AppException
  static void fromException(
    BuildContext context,
    AppException exception, {
    VoidCallback? onRetry,
  }) {
    ErrorHandler.instance.showErrorSnackBar(
      context,
      exception,
      onRetry: onRetry,
    );
  }

  /// عرض مخصص
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // إهتزاز خفيف للفت الانتباه
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? 'تم',
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Loading Overlay - طبقة تحميل
// ═══════════════════════════════════════════════════════════════════════════

/// طبقة تحميل فوق الشاشة
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// إظهار طبقة التحميل
  static void show(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    if (_isShowing) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;
  }

  /// إخفاء طبقة التحميل
  static void hide() {
    if (!_isShowing) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  /// تنفيذ عملية مع طبقة تحميل
  static Future<T?> run<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? message,
    void Function(dynamic error)? onError,
  }) async {
    show(context, message: message);
    try {
      final result = await action();
      return result;
    } catch (e) {
      onError?.call(e);
      return null;
    } finally {
      hide();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Confirm Dialog - مربع تأكيد
// ═══════════════════════════════════════════════════════════════════════════

/// مربعات حوار التأكيد
class ConfirmDialog {
  ConfirmDialog._();

  /// تأكيد عادي
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    Color? confirmColor,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  confirmColor ?? (isDangerous ? Colors.red : null),
              foregroundColor: isDangerous ? Colors.white : null,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// تأكيد حذف
  static Future<bool> delete(BuildContext context, {required String itemName}) {
    return show(
      context,
      title: 'حذف $itemName',
      message:
          'هل أنت متأكد من حذف $itemName؟\nلا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      isDangerous: true,
    );
  }

  /// تأكيد تسجيل خروج
  static Future<bool> logout(BuildContext context) {
    return show(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد من تسجيل الخروج؟',
      confirmLabel: 'خروج',
      isDangerous: true,
    );
  }

  /// تأكيد إلغاء التغييرات
  static Future<bool> discardChanges(BuildContext context) {
    return show(
      context,
      title: 'إلغاء التغييرات',
      message: 'لديك تغييرات غير محفوظة.\nهل تريد إلغاءها؟',
      confirmLabel: 'إلغاء التغييرات',
      isDangerous: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Debouncer - مؤجل للعمليات
// ═══════════════════════════════════════════════════════════════════════════

/// مؤجل لمنع التكرار السريع
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// تشغيل مؤجل
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// تشغيل فوري مع منع التكرار
  void runImmediate(VoidCallback action) {
    if (_timer?.isActive ?? false) return;
    action();
    _timer = Timer(delay, () {});
  }

  /// إلغاء
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// هل يعمل؟
  bool get isRunning => _timer?.isActive ?? false;

  /// التخلص
  void dispose() => cancel();
}

// ═══════════════════════════════════════════════════════════════════════════
// Throttler - خانق للعمليات
// ═══════════════════════════════════════════════════════════════════════════

/// خانق لتحديد معدل العمليات
class Throttler {
  final Duration interval;
  DateTime? _lastRun;

  Throttler({this.interval = const Duration(milliseconds: 500)});

  /// تشغيل مع خنق
  bool run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      _lastRun = now;
      action();
      return true;
    }
    return false;
  }

  /// إعادة تعيين
  void reset() => _lastRun = null;
}

// ═══════════════════════════════════════════════════════════════════════════
// Form Validators - مدققات النماذج
// ═══════════════════════════════════════════════════════════════════════════

/// مدققات مدمجة للنماذج
class FormValidators {
  FormValidators._();

  /// حقل مطلوب
  static String? required(String? value, [String fieldName = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  /// بريد إلكتروني
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'بريد إلكتروني غير صحيح';
    return null;
  }

  /// رقم هاتف
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'رقم الهاتف مطلوب';
    final regex = RegExp(r'^[0-9]{10,15}$');
    if (!regex.hasMatch(value)) return 'رقم هاتف غير صحيح';
    return null;
  }

  /// كلمة مرور
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < minLength) {
      return 'كلمة المرور يجب أن تكون $minLength أحرف على الأقل';
    }
    return null;
  }

  /// تأكيد كلمة المرور
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) return 'تأكيد كلمة المرور مطلوب';
    if (value != password) return 'كلمات المرور غير متطابقة';
    return null;
  }

  /// رقم
  static String? number(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) return 'الرقم مطلوب';
    final num = double.tryParse(value);
    if (num == null) return 'أدخل رقماً صحيحاً';
    if (min != null && num < min) return 'يجب أن يكون $min على الأقل';
    if (max != null && num > max) return 'يجب أن يكون $max كحد أقصى';
    return null;
  }

  /// طول محدد
  static String? length(
    String? value, {
    required int min,
    int? max,
    String fieldName = 'النص',
  }) {
    if (value == null || value.isEmpty) return '$fieldName مطلوب';
    if (value.length < min) return '$fieldName يجب أن يكون $min أحرف على الأقل';
    if (max != null && value.length > max) {
      return '$fieldName يجب ألا يتجاوز $max حرف';
    }
    return null;
  }

  /// دمج عدة مدققات
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pull To Refresh Wrapper - لف السحب للتحديث
// ═══════════════════════════════════════════════════════════════════════════

/// تغليف سهل للسحب للتحديث
class PullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;

  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}
