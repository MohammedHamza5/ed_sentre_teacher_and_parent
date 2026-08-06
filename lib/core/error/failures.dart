sealed class Failure {
  final String message;
  const Failure({required this.message});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'لا يوجد اتصال بالإنترنت'});
}

class ServerFailure extends Failure {
  final String? code;
  const ServerFailure({super.message = 'حدث خطأ في الخادم', this.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'انتهت الجلسة، يرجى تسجيل الدخول مجدداً'});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'البيانات المطلوبة غير موجودة'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'بيانات غير صالحة'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'خطأ في الذاكرة المؤقتة'});
}

class RlsViolationFailure extends Failure {
  const RlsViolationFailure({super.message = 'لا تملك الصلاحية للوصول إلى هذه البيانات'});
}

class AiQuotaFailure extends Failure {
  const AiQuotaFailure({super.message = 'نفد رصيد المحاولات الذكية'});
}

class AiTimeoutFailure extends Failure {
  const AiTimeoutFailure({super.message = 'تأخر الخادم في الرد، يرجى المحاولة لاحقاً'});
}

class AiParseFailure extends Failure {
  const AiParseFailure({super.message = 'تعذر تحليل استجابة الذكاء الاصطناعي'});
}

class SyncConflictFailure extends Failure {
  const SyncConflictFailure({super.message = 'تعارض في مزامنة البيانات'});
}

class UnknownFailure extends Failure {
  final Object? originalError;
  const UnknownFailure({super.message = 'حدث خطأ غير معروف', this.originalError});
}
