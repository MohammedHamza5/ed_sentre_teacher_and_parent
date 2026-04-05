/// Result Pattern - نمط النتيجة للتعامل مع العمليات
/// بديل أنيق لـ try-catch في كل مكان
library;

import 'app_exceptions.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Result Class - نتيجة العملية
// ═══════════════════════════════════════════════════════════════════════════

/// نتيجة عملية - إما نجاح أو فشل
sealed class Result<T> {
  const Result();

  /// إنشاء نتيجة ناجحة
  factory Result.success(T data) = Success<T>;

  /// إنشاء نتيجة فاشلة
  factory Result.failure(AppException exception) = Failure<T>;

  /// هل العملية ناجحة؟
  bool get isSuccess => this is Success<T>;

  /// هل العملية فاشلة؟
  bool get isFailure => this is Failure<T>;

  /// الحصول على البيانات (null إذا فشلت)
  T? get data => switch (this) {
    Success<T> s => s.data,
    Failure<T> _ => null,
  };

  /// الحصول على الخطأ (null إذا نجحت)
  AppException? get exception => switch (this) {
    Success<T> _ => null,
    Failure<T> f => f.exception,
  };

  /// تحويل النتيجة
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success<T> s => success(s.data),
      Failure<T> f => failure(f.exception),
    };
  }

  /// تحويل مع قيمة افتراضية للفشل
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success<T> s => s.data,
      Failure<T> _ => defaultValue(),
    };
  }

  /// تحويل مع قيمة افتراضية ثابتة
  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success<T> s => s.data,
      Failure<T> _ => defaultValue,
    };
  }

  /// تحويل البيانات مع الحفاظ على نوع النتيجة
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T> s => Result.success(transform(s.data)),
      Failure<T> f => Result.failure(f.exception),
    };
  }

  /// تحويل مسطح (للعمليات المتسلسلة)
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T> s => transform(s.data),
      Failure<T> f => Result.failure(f.exception),
    };
  }

  /// تنفيذ كود عند النجاح
  Result<T> onSuccess(void Function(T data) action) {
    if (this is Success<T>) {
      action((this as Success<T>).data);
    }
    return this;
  }

  /// تنفيذ كود عند الفشل
  Result<T> onFailure(void Function(AppException exception) action) {
    if (this is Failure<T>) {
      action((this as Failure<T>).exception);
    }
    return this;
  }
}

/// نتيجة ناجحة
final class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// نتيجة فاشلة
final class Failure<T> extends Result<T> {
  @override
  final AppException exception;

  const Failure(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception.code == other.exception.code;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure(${exception.code}: ${exception.message})';
}

// ═══════════════════════════════════════════════════════════════════════════
// AsyncResult - للعمليات غير المتزامنة
// ═══════════════════════════════════════════════════════════════════════════

/// نوع مختصر للعمليات غير المتزامنة
typedef AsyncResult<T> = Future<Result<T>>;

/// امتدادات للعمليات غير المتزامنة
extension AsyncResultExtension<T> on AsyncResult<T> {
  /// تحويل النتيجة غير المتزامنة
  AsyncResult<R> mapAsync<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// تحويل مسطح غير متزامن
  AsyncResult<R> flatMapAsync<R>(
    AsyncResult<R> Function(T data) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success<T> s => transform(s.data),
      Failure<T> f => Result.failure(f.exception),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Result Extensions - امتدادات مساعدة
// ═══════════════════════════════════════════════════════════════════════════

/// امتداد لتحويل Future عادي إلى Result
extension FutureToResult<T> on Future<T> {
  /// تحويل Future إلى Result مع معالجة الأخطاء
  AsyncResult<T> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(
        UnexpectedException(
          message: e.toString(),
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

/// امتداد لقائمة النتائج
extension ResultListExtension<T> on List<Result<T>> {
  /// الحصول على كل النتائج الناجحة
  List<T> get successes => whereType<Success<T>>().map((s) => s.data).toList();

  /// الحصول على كل الأخطاء
  List<AppException> get failures =>
      whereType<Failure<T>>().map((f) => f.exception).toList();

  /// هل كل العمليات نجحت؟
  bool get allSucceeded => every((r) => r.isSuccess);

  /// هل أي عملية نجحت؟
  bool get anySucceeded => any((r) => r.isSuccess);
}

// ═══════════════════════════════════════════════════════════════════════════
// Unit Type - للعمليات بدون قيمة إرجاع
// ═══════════════════════════════════════════════════════════════════════════

/// نوع الوحدة - للعمليات التي لا ترجع قيمة
class Unit {
  const Unit._();
  static const Unit value = Unit._();

  @override
  String toString() => 'Unit';
}

/// نتيجة بدون قيمة
typedef UnitResult = Result<Unit>;

/// نتيجة بدون قيمة غير متزامنة
typedef AsyncUnitResult = AsyncResult<Unit>;

/// إنشاء نتيجة وحدة ناجحة
UnitResult successUnit() => Result.success(Unit.value);
