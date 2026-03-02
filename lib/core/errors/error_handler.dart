/// Error Handler Service - خدمة معالجة الأخطاء المركزية
/// تتعامل مع تحويل الأخطاء وتسجيلها وعرضها
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../utils/app_logger.dart';

import 'app_exceptions.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Error Handler - معالج الأخطاء
// ═══════════════════════════════════════════════════════════════════════════

class ErrorHandler {
  ErrorHandler._();
  static final instance = ErrorHandler._();

  /// تسجيل الأخطاء
  final List<ErrorLog> _errorLogs = [];

  /// المشتركون في أحداث الأخطاء
  final _errorStreamController = StreamController<AppException>.broadcast();

  /// استماع للأخطاء
  Stream<AppException> get errorStream => _errorStreamController.stream;

  /// سجل الأخطاء
  List<ErrorLog> get errorLogs => List.unmodifiable(_errorLogs);

  // ─────────────────────────────────────────────────────────────────────────
  // تحويل الأخطاء
  // ─────────────────────────────────────────────────────────────────────────

  /// تحويل أي خطأ إلى AppException
  AppException handle(dynamic error, [StackTrace? stackTrace]) {
    AppException appException;

    if (error is AppException) {
      appException = error;
    } else if (error is supabase.AuthException) {
      appException = _handleSupabaseAuthError(error);
    } else if (error is supabase.PostgrestException) {
      appException = _handlePostgrestError(error);
    } else if (error is supabase.StorageException) {
      appException = _handleStorageError(error);
    } else if (error is SocketException) {
      appException = const NoInternetException();
    } else if (error is TimeoutException) {
      appException = const TimeoutException();
    } else if (error is FormatException) {
      appException = DataFormatException(
        message: error.message,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else {
      appException = UnexpectedException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // تسجيل الخطأ
    _logError(appException, stackTrace);

    // إرسال للمشتركين
    _errorStreamController.add(appException);

    return appException;
  }

  /// معالجة أخطاء Supabase Auth
  AppException _handleSupabaseAuthError(supabase.AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email') ||
        message.contains('invalid password')) {
      return InvalidCredentialsException(
        message: error.message,
        originalError: error,
      );
    }

    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return UserExistsException(message: error.message, originalError: error);
    }

    if (message.contains('session') || message.contains('expired')) {
      return SessionExpiredException(
        message: error.message,
        originalError: error,
      );
    }

    if (message.contains('not authorized') ||
        message.contains('unauthorized')) {
      return UnauthorizedException(
        message: error.message,
        originalError: error,
      );
    }

    return AppAuthException(message: error.message, originalError: error);
  }

  /// معالجة أخطاء Postgrest
  AppException _handlePostgrestError(supabase.PostgrestException error) {
    final code = error.code;

    // خطأ البيانات غير موجودة
    if (code == 'PGRST116' || error.message.contains('not found')) {
      return NotFoundException(message: error.message, originalError: error);
    }

    // خطأ التكرار
    if (code == '23505' || error.message.contains('duplicate')) {
      return ValidationException(
        message: 'البيانات موجودة مسبقاً',
        code: 'DUPLICATE',
        originalError: error,
      );
    }

    // خطأ المرجعية
    if (code == '23503' || error.message.contains('foreign key')) {
      return ValidationException(
        message: 'خطأ في ربط البيانات',
        code: 'FK_ERROR',
        originalError: error,
      );
    }

    // خطأ RLS
    if (code == '42501' ||
        error.message.contains('policy') ||
        error.message.contains('permission')) {
      return UnauthorizedException(
        message: error.message,
        originalError: error,
      );
    }

    return ServerException(message: error.message, originalError: error);
  }

  /// معالجة أخطاء Storage
  AppException _handleStorageError(supabase.StorageException error) {
    final message = error.message.toLowerCase() ?? '';

    if (message.contains('too large') || message.contains('size')) {
      return const FileTooLargeException();
    }

    if (message.contains('type') || message.contains('format')) {
      return const UnsupportedFileTypeException();
    }

    return FileUploadException(
      message: error.message ?? 'Storage error',
      originalError: error,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // تسجيل الأخطاء
  // ─────────────────────────────────────────────────────────────────────────

  void _logError(AppException error, StackTrace? stackTrace) {
    final log = ErrorLog(
      exception: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _errorLogs.add(log);

    // الاحتفاظ بآخر 100 خطأ فقط
    if (_errorLogs.length > 100) {
      _errorLogs.removeAt(0);
    }

    // تسجيل في AppLogger
    AppLogger.instance.error(
      error.message,
      tag: error.code ?? 'ERROR',
      error: error.originalError,
      stackTrace: stackTrace,
      data: {'user_message': error.userMessage, 'can_retry': error.canRetry},
    );

    // طباعة في وضع التطوير
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('${error.icon} ERROR: ${error.code}');
      debugPrint('Message: ${error.message}');
      debugPrint('User Message: ${error.userMessage}');
      if (error.originalError != null) {
        debugPrint('Original: ${error.originalError}');
      }
      if (stackTrace != null) {
        debugPrint('Stack Trace:\n$stackTrace');
      }
      debugPrint('═══════════════════════════════════════════════════');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // عرض الأخطاء للمستخدم
  // ─────────────────────────────────────────────────────────────────────────

  /// عرض SnackBar للخطأ
  void showErrorSnackBar(
    BuildContext context,
    AppException error, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(error.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.userMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: error.canRetry && onRetry != null
            ? SnackBarAction(
                label: 'إعادة',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// عرض Dialog للخطأ
  Future<void> showErrorDialog(
    BuildContext context,
    AppException error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(error.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Text('حدث خطأ'),
          ],
        ),
        content: Text(error.userMessage, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('إغلاق'),
          ),
          if (error.canRetry && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
        ],
      ),
    );
  }

  /// لون الخطأ حسب النوع
  Color _getErrorColor(AppException error) {
    if (error is NoInternetException || error is TimeoutException) {
      return Colors.orange[700]!;
    }
    if (error is AppAuthException) {
      return Colors.red[700]!;
    }
    if (error is ValidationException) {
      return Colors.amber[700]!;
    }
    if (error is AIServiceException) {
      return Colors.purple[700]!;
    }
    return Colors.red[600]!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // أدوات مساعدة
  // ─────────────────────────────────────────────────────────────────────────

  /// تنظيف السجل
  void clearLogs() => _errorLogs.clear();

  /// إغلاق
  void dispose() {
    _errorStreamController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error Log - سجل الخطأ
// ═══════════════════════════════════════════════════════════════════════════

class ErrorLog {
  final AppException exception;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const ErrorLog({
    required this.exception,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${exception.code}: ${exception.message}';
}

// ═══════════════════════════════════════════════════════════════════════════
// Global Error Handler - للأخطاء غير الملتقطة
// ═══════════════════════════════════════════════════════════════════════════

/// تهيئة معالج الأخطاء العام
void setupGlobalErrorHandler() {
  // أخطاء Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorHandler.instance.handle(details.exception, details.stack);
  };

  // أخطاء Dart غير الملتقطة
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.instance.handle(error, stack);
    return true;
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Safe Call Extension - استدعاء آمن
// ═══════════════════════════════════════════════════════════════════════════

/// تنفيذ عملية بشكل آمن مع معالجة الأخطاء
Future<T?> safeCall<T>(
  Future<T> Function() action, {
  void Function(AppException)? onError,
  T? fallback,
}) async {
  try {
    return await action();
  } catch (e, stackTrace) {
    final error = ErrorHandler.instance.handle(e, stackTrace);
    onError?.call(error);
    return fallback;
  }
}

/// تنفيذ عملية متزامنة بشكل آمن
T? safeSync<T>(
  T Function() action, {
  void Function(AppException)? onError,
  T? fallback,
}) {
  try {
    return action();
  } catch (e, stackTrace) {
    final error = ErrorHandler.instance.handle(e, stackTrace);
    onError?.call(error);
    return fallback;
  }
}
