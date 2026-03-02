/// استثناءات مخصصة للتطبيق
/// كل استثناء له رسالة واضحة للمستخدم ورمز للتتبع
library;

// ═══════════════════════════════════════════════════════════════════════════
// الاستثناء الأساسي
// ═══════════════════════════════════════════════════════════════════════════

/// الاستثناء الأساسي للتطبيق
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// رسالة للمستخدم (بالعربية)
  String get userMessage;

  /// أيقونة الخطأ
  String get icon => '⚠️';

  /// هل يمكن إعادة المحاولة؟
  bool get canRetry => false;

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════════
// أخطاء الشبكة
// ═══════════════════════════════════════════════════════════════════════════

/// خطأ عدم الاتصال بالإنترنت
class NoInternetException extends AppException {
  const NoInternetException({
    super.message = 'No internet connection',
    super.code = 'NO_INTERNET',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'لا يوجد اتصال بالإنترنت\nتحقق من اتصالك وحاول مرة أخرى';

  @override
  String get icon => '📡';

  @override
  bool get canRetry => true;
}

/// خطأ انتهاء مهلة الاتصال
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Connection timeout',
    super.code = 'TIMEOUT',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'انتهت مهلة الاتصال\nالخادم لا يستجيب، حاول مرة أخرى';

  @override
  String get icon => '⏱️';

  @override
  bool get canRetry => true;
}

/// خطأ في الخادم
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error',
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'حدث خطأ في الخادم\nنعمل على إصلاحه، حاول لاحقاً';

  @override
  String get icon => '🔧';

  @override
  bool get canRetry => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// أخطاء المصادقة
// ═══════════════════════════════════════════════════════════════════════════

/// خطأ في المصادقة (تسجيل الدخول)
class AppAuthException extends AppException {
  const AppAuthException({
    super.message = 'Authentication failed',
    super.code = 'AUTH_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'فشل تسجيل الدخول\nتحقق من بياناتك وحاول مرة أخرى';

  @override
  String get icon => '🔐';
}

/// خطأ بيانات الدخول غير صحيحة
class InvalidCredentialsException extends AppAuthException {
  const InvalidCredentialsException({
    super.message = 'Invalid credentials',
    super.code = 'INVALID_CREDENTIALS',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
}

/// خطأ الجلسة منتهية
class SessionExpiredException extends AppAuthException {
  const SessionExpiredException({
    super.message = 'Session expired',
    super.code = 'SESSION_EXPIRED',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'انتهت صلاحية الجلسة\nيرجى تسجيل الدخول مرة أخرى';
}

/// خطأ غير مصرح
class UnauthorizedException extends AppAuthException {
  const UnauthorizedException({
    super.message = 'Unauthorized access',
    super.code = 'UNAUTHORIZED',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'غير مصرح لك بهذا الإجراء';
}

/// خطأ المستخدم موجود مسبقاً
class UserExistsException extends AppAuthException {
  const UserExistsException({
    super.message = 'User already exists',
    super.code = 'USER_EXISTS',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'هذا البريد الإلكتروني مسجل مسبقاً';
}

// ═══════════════════════════════════════════════════════════════════════════
// أخطاء البيانات
// ═══════════════════════════════════════════════════════════════════════════

/// خطأ البيانات غير موجودة
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Data not found',
    super.code = 'NOT_FOUND',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'البيانات غير موجودة';

  @override
  String get icon => '🔍';
}

/// خطأ في تنسيق البيانات
class DataFormatException extends AppException {
  const DataFormatException({
    super.message = 'Invalid data format',
    super.code = 'DATA_FORMAT_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'خطأ في تنسيق البيانات';

  @override
  String get icon => '📋';
}

/// خطأ التحقق من البيانات
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    super.message = 'Validation failed',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'تحقق من البيانات المدخلة';

  @override
  String get icon => '✏️';
}

// ═══════════════════════════════════════════════════════════════════════════
// أخطاء كود الدعوة
// ═══════════════════════════════════════════════════════════════════════════

/// خطأ كود الدعوة
class InvitationCodeException extends AppException {
  const InvitationCodeException({
    super.message = 'Invalid invitation code',
    super.code = 'INVALID_CODE',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'كود الدعوة غير صحيح';

  @override
  String get icon => '🎟️';
}

/// كود الدعوة مستخدم مسبقاً
class CodeAlreadyUsedException extends InvitationCodeException {
  const CodeAlreadyUsedException({
    super.message = 'Invitation code already used',
    super.code = 'CODE_USED',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'كود الدعوة مستخدم مسبقاً';
}

/// كود الدعوة منتهي الصلاحية
class CodeExpiredException extends InvitationCodeException {
  const CodeExpiredException({
    super.message = 'Invitation code expired',
    super.code = 'CODE_EXPIRED',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'كود الدعوة منتهي الصلاحية';
}

// ═══════════════════════════════════════════════════════════════════════════
// أخطاء الملفات
// ═══════════════════════════════════════════════════════════════════════════

/// خطأ في رفع الملف
class FileUploadException extends AppException {
  const FileUploadException({
    super.message = 'File upload failed',
    super.code = 'UPLOAD_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'فشل رفع الملف\nحاول مرة أخرى';

  @override
  String get icon => '📁';

  @override
  bool get canRetry => true;
}

/// حجم الملف كبير جداً
class FileTooLargeException extends FileUploadException {
  final int maxSizeInMB;

  const FileTooLargeException({
    super.message = 'File too large',
    super.code = 'FILE_TOO_LARGE',
    this.maxSizeInMB = 10,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'حجم الملف كبير جداً\nالحد الأقصى $maxSizeInMB ميجابايت';

  @override
  bool get canRetry => false;
}

/// نوع الملف غير مدعوم
class UnsupportedFileTypeException extends FileUploadException {
  const UnsupportedFileTypeException({
    super.message = 'Unsupported file type',
    super.code = 'UNSUPPORTED_FILE',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'نوع الملف غير مدعوم';

  @override
  bool get canRetry => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// أخطاء AI
// ═══════════════════════════════════════════════════════════════════════════

/// خطأ في خدمة AI
class AIServiceException extends AppException {
  const AIServiceException({
    super.message = 'AI service error',
    super.code = 'AI_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'خطأ في خدمة المساعد الذكي\nحاول مرة أخرى';

  @override
  String get icon => '🤖';

  @override
  bool get canRetry => true;
}

/// رصيد AI غير كافي
class InsufficientCreditsException extends AIServiceException {
  final int required;
  final int available;

  const InsufficientCreditsException({
    super.message = 'Insufficient AI credits',
    super.code = 'NO_CREDITS',
    this.required = 0,
    this.available = 0,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'رصيد غير كافٍ\nالمطلوب: $required - المتاح: $available';

  @override
  bool get canRetry => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// أخطاء عامة
// ═══════════════════════════════════════════════════════════════════════════

/// خطأ غير متوقع
class UnexpectedException extends AppException {
  const UnexpectedException({
    super.message = 'Unexpected error',
    super.code = 'UNEXPECTED',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'حدث خطأ غير متوقع\nيرجى المحاولة مرة أخرى';

  @override
  String get icon => '❌';

  @override
  bool get canRetry => true;
}

/// خطأ في التخزين المحلي
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code = 'CACHE_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'خطأ في البيانات المحلية';

  @override
  String get icon => '💾';
}

/// خطأ في الصلاحيات
class PermissionException extends AppException {
  final String permission;

  const PermissionException({
    super.message = 'Permission denied',
    super.code = 'PERMISSION_DENIED',
    this.permission = '',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'يرجى السماح بالوصول للتطبيق';

  @override
  String get icon => '🔒';
}
