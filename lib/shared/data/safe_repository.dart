/// Safe Repository - Repository مع Error Handling مدمج
/// يستخدم Result Pattern لإرجاع نتائج آمنة
library;

import 'dart:io';

import '../../core/errors/errors.dart';
import '../../core/services/network_monitor.dart';
import '../../core/utils/app_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Safe Repository Mixin - لإضافة Error Handling لأي Repository
// ═══════════════════════════════════════════════════════════════════════════

/// Mixin يضيف معالجة الأخطاء الآمنة
mixin SafeRepositoryMixin {
  /// تنفيذ عملية بشكل آمن مع معالجة الأخطاء
  Future<Result<T>> safeExecute<T>(
    Future<T> Function() action, {
    bool checkNetwork = true,
    int retryCount = 0,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    // التحقق من الشبكة
    if (checkNetwork && !NetworkMonitor.instance.isConnected) {
      log.network('❌ No Internet Connection - Action blocked');
      return  Result.failure(NoInternetException());
    }

    int attempts = 0;
    AppException? lastError;

    while (attempts <= retryCount) {
      try {
        final result = await action();
        log.data('✅ Action Success (Attempt ${attempts + 1})', data: {'result_type': T.toString()});
        return Result.success(result);
      } on SocketException {
        lastError = const NoInternetException();
      } on TimeoutException {
        lastError = const TimeoutException();
      } on AppException catch (e) {
        lastError = e;
        // لا نعيد المحاولة للأخطاء غير القابلة للإعادة
        if (!e.canRetry) break;
      } catch (e, stackTrace) {
        log.error('❌ Action Failed (Attempt ${attempts + 1})', error: e, stackTrace: stackTrace);
        lastError = ErrorHandler.instance.handle(e, stackTrace);
        if (!lastError.canRetry) break;
      }

      attempts++;
      if (attempts <= retryCount) {
        log.warning('⚠️ Retrying action... (Attempt $attempts of $retryCount)');
        await Future.delayed(retryDelay * attempts);
      }
    }

    return Result.failure(lastError ?? const UnexpectedException());
  }

  /// تنفيذ عملية مع timeout
  Future<Result<T>> safeExecuteWithTimeout<T>(
    Future<T> Function() action, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final result = await action().timeout(timeout);
      return Result.success(result);
    } on TimeoutException {
      return  Result.failure(TimeoutException());
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.instance.handle(e, stackTrace));
    }
  }

  /// تنفيذ قائمة عمليات بالتوازي
  Future<List<Result<T>>> safeExecuteAll<T>(
    List<Future<T> Function()> actions,
  ) async {
    return Future.wait(actions.map((action) => safeExecute(action)));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Retry Policy - سياسة إعادة المحاولة
// ═══════════════════════════════════════════════════════════════════════════

/// سياسة إعادة المحاولة
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffFactor;
  final Duration maxDelay;
  final bool Function(AppException)? shouldRetry;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffFactor = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });

  /// السياسة الافتراضية
  static const RetryPolicy defaultPolicy = RetryPolicy();

  /// سياسة سريعة
  static const RetryPolicy fast = RetryPolicy(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 500),
  );

  /// سياسة صبورة
  static const RetryPolicy patient = RetryPolicy(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 2),
    backoffFactor: 1.5,
  );

  /// حساب مدة الانتظار للمحاولة
  Duration getDelayForAttempt(int attempt) {
    final delay = initialDelay * (backoffFactor * attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  /// هل يجب إعادة المحاولة؟
  bool canRetry(int attempt, AppException error) {
    if (attempt >= maxAttempts) return false;
    if (shouldRetry != null) return shouldRetry!(error);
    return error.canRetry;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cached Result - نتيجة مخزنة مؤقتاً
// ═══════════════════════════════════════════════════════════════════════════

/// نتيجة مخزنة مع وقت انتهاء الصلاحية
class CachedResult<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  CachedResult({
    required this.data,
    DateTime? cachedAt,
    this.ttl = const Duration(minutes: 5),
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// هل انتهت الصلاحية؟
  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;

  /// هل لا تزال صالحة؟
  bool get isValid => !isExpired;

  /// الوقت المتبقي
  Duration get remainingTime {
    final elapsed = DateTime.now().difference(cachedAt);
    final remaining = ttl - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// مدير التخزين المؤقت
class ResultCache<K, V> {
  final Map<K, CachedResult<V>> _cache = {};
  final Duration defaultTtl;

  ResultCache({this.defaultTtl = const Duration(minutes: 5)});

  /// الحصول على قيمة من التخزين المؤقت
  V? get(K key) {
    final cached = _cache[key];
    if (cached == null || cached.isExpired) {
      _cache.remove(key);
      return null;
    }
    return cached.data;
  }

  /// تخزين قيمة
  void set(K key, V value, {Duration? ttl}) {
    _cache[key] = CachedResult(data: value, ttl: ttl ?? defaultTtl);
  }

  /// حذف قيمة
  void remove(K key) => _cache.remove(key);

  /// مسح كل التخزين المؤقت
  void clear() => _cache.clear();

  /// مسح القيم المنتهية الصلاحية
  void cleanup() {
    _cache.removeWhere((_, v) => v.isExpired);
  }

  /// عدد العناصر المخزنة
  int get length => _cache.length;

  /// هل يوجد مفتاح؟
  bool containsKey(K key) {
    final cached = _cache[key];
    return cached != null && cached.isValid;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Example Usage - مثال للاستخدام
// ═══════════════════════════════════════════════════════════════════════════

/*
// في Repository:
class MyRepository with SafeRepositoryMixin {
  Future<Result<User>> getUser(String id) async {
    return safeExecute(() async {
      final response = await _client.from('users').select().eq('id', id).single();
      return User.fromJson(response);
    });
  }
  
  Future<Result<List<Student>>> getStudents() async {
    return safeExecute(
      () async {
        final response = await _client.from('students').select();
        return (response as List).map((e) => Student.fromJson(e)).toList();
      },
      retryCount: 2, // إعادة المحاولة مرتين
    );
  }
}

// في Provider أو UI:
final result = await repository.getUser(userId);

result.when(
  success: (user) {
    // عرض بيانات المستخدم
    setState(() => _user = user);
  },
  failure: (error) {
    // عرض رسالة الخطأ
    ErrorHandler.instance.showErrorSnackBar(context, error);
  },
);

// أو استخدام الاختصارات:
final user = result.getOrElse(() => User.empty());
final user = result.data; // null إذا فشل

// سلسلة العمليات:
final result = await repository.getUser(userId)
  .then((r) => r.flatMap((user) async {
    // عملية أخرى تعتمد على المستخدم
    return await repository.getUserDetails(user.id);
  }));

// مع AsyncContentBuilder في UI:
AsyncContentBuilder<User>(
  state: _state,
  data: _user,
  error: _error,
  onRetry: _loadUser,
  builder: (user) {
    return Text(user.name);
  },
);
*/
