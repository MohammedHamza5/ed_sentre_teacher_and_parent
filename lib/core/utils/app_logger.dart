/// App Logger - نظام تسجيل شامل لكل ما يحدث في التطبيق
/// يسجل كل خطوة، بيانات، أخطاء، وأحداث
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Log Level - مستويات التسجيل
// ═══════════════════════════════════════════════════════════════════════════

enum LogLevel {
  /// معلومات عامة ℹ️
  info(0, '📘', 'INFO'),

  /// تحذير ⚠️
  warning(1, '⚠️', 'WARN'),

  /// خطأ ❌
  error(2, '❌', 'ERROR'),

  /// خطأ فادح 💥
  fatal(3, '💥', 'FATAL'),

  /// تصحيح أخطاء 🐛
  debug(4, '🐛', 'DEBUG'),

  /// أداء ⚡
  performance(5, '⚡', 'PERF'),

  /// شبكة 🌐
  network(6, '🌐', 'NET'),

  /// قاعدة بيانات 💾
  database(7, '💾', 'DB'),

  /// واجهة المستخدم 🎨
  ui(8, '🎨', 'UI'),

  /// مصادقة 🔐
  auth(9, '🔐', 'AUTH'),

  /// بيانات 📊
  data(10, '📊', 'DATA');

  final int priority;
  final String emoji;
  final String label;

  const LogLevel(this.priority, this.emoji, this.label);
}

// ═══════════════════════════════════════════════════════════════════════════
// App Logger - المسجل الرئيسي
// ═══════════════════════════════════════════════════════════════════════════

class AppLogger {
  AppLogger._();
  static final instance = AppLogger._();

  /// قائمة السجلات
  final List<LogEntry> _logs = [];

  /// مستمعو السجلات
  final _logStreamController = StreamController<LogEntry>.broadcast();

  /// مستوى التسجيل الأدنى
  LogLevel minLevel = LogLevel.info;

  /// هل التسجيل مفعل؟
  bool isEnabled = true;

  /// هل الحفظ في ملف مفعل؟
  bool saveToFile = true;

  /// الحد الأقصى لعدد السجلات في الذاكرة
  int maxLogsInMemory = 1000;

  /// الحد الأقصى لحجم ملف السجل (بالميجابايت)
  int maxLogFileSizeMB = 10;

  /// مسار ملف السجل
  File? _logFile;

  /// استماع للسجلات
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// الحصول على كل السجلات
  List<LogEntry> get logs => List.unmodifiable(_logs);

  // ─────────────────────────────────────────────────────────────────────────
  // التهيئة
  // ─────────────────────────────────────────────────────────────────────────

  /// تهيئة المسجل
  Future<void> initialize() async {
    if (saveToFile) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final logDir = Directory('${dir.path}/logs');
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }

        final now = DateTime.now();
        final fileName = 'app_log_${DateFormat('yyyy-MM-dd').format(now)}.txt';
        _logFile = File('${logDir.path}/$fileName');

        // تنظيف الملفات القديمة
        await _cleanOldLogFiles(logDir);
      } catch (e) {
        debugPrint('⚠️ Failed to initialize log file: $e');
      }
    }

    info('App Logger Initialized', tag: 'AppLogger');
  }

  /// تنظيف ملفات السجل القديمة (أكثر من 7 أيام)
  Future<void> _cleanOldLogFiles(Directory logDir) async {
    try {
      final files = await logDir.list().toList();
      final now = DateTime.now();

      for (var file in files) {
        if (file is File && file.path.endsWith('.txt')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;
          if (age > 7) {
            await file.delete();
            debugPrint('🗑️ Deleted old log file: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to clean old log files: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // دوال التسجيل
  // ─────────────────────────────────────────────────────────────────────────

  /// معلومات عامة
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// تحذير
  void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// خطأ
  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// خطأ فادح
  void fatal(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// تصحيح أخطاء
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// أداء
  void performance(
    String message, {
    String? tag,
    Duration? duration,
    Map<String, dynamic>? data,
  }) {
    final perfData = data ?? {};
    if (duration != null) {
      perfData['duration_ms'] = duration.inMilliseconds;
    }
    _log(LogLevel.performance, message, tag: tag, data: perfData);
  }

  /// شبكة
  void network(
    String message, {
    String? tag,
    String? url,
    String? method,
    int? statusCode,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) {
    final netData = <String, dynamic>{};
    if (url != null) netData['url'] = url;
    if (method != null) netData['method'] = method;
    if (statusCode != null) netData['status_code'] = statusCode;
    if (requestData != null) netData['request'] = requestData;
    if (responseData != null) netData['response'] = responseData;

    _log(LogLevel.network, message, tag: tag, data: netData);
  }

  /// قاعدة بيانات
  void database(
    String message, {
    String? tag,
    String? query,
    Map<String, dynamic>? params,
    dynamic result,
  }) {
    final dbData = <String, dynamic>{};
    if (query != null) dbData['query'] = query;
    if (params != null) dbData['params'] = params;
    if (result != null) dbData['result'] = _sanitizeData(result);

    _log(LogLevel.database, message, tag: tag, data: dbData);
  }

  /// واجهة المستخدم
  void ui(
    String message, {
    String? tag,
    String? screen,
    Map<String, dynamic>? data,
  }) {
    final uiData = data ?? {};
    if (screen != null) uiData['screen'] = screen;
    _log(LogLevel.ui, message, tag: tag, data: uiData);
  }

  /// مصادقة
  void auth(
    String message, {
    String? tag,
    String? userId,
    String? action,
    Map<String, dynamic>? data,
  }) {
    final authData = data ?? {};
    if (userId != null) authData['user_id'] = userId;
    if (action != null) authData['action'] = action;
    _log(LogLevel.auth, message, tag: tag, data: authData);
  }

  /// بيانات
  void data(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.data, message, tag: tag, data: data);
  }

  /// تسجيل عام
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (!isEnabled) return;
    if (level.priority < minLevel.priority) return;

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      data: data != null ? _sanitizeData(data) : null,
    );

    // إضافة للذاكرة
    _logs.add(entry);
    if (_logs.length > maxLogsInMemory) {
      _logs.removeAt(0);
    }

    // إرسال للمستمعين
    _logStreamController.add(entry);

    // طباعة في وضع التطوير
    if (kDebugMode) {
      _printLog(entry);
    }

    // حفظ في ملف
    if (saveToFile && _logFile != null) {
      _writeToFile(entry);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // طباعة وحفظ
  // ─────────────────────────────────────────────────────────────────────────

  /// طباعة السجل
  void _printLog(LogEntry entry) {
    final time = DateFormat('HH:mm:ss.SSS').format(entry.timestamp);
    final tag = entry.tag != null ? '[${entry.tag}]' : '';
    final level = entry.level.emoji;

    debugPrint('$level $time $tag ${entry.message}');

    if (entry.data != null) {
      try {
        final json = JsonEncoder.withIndent('  ').convert(entry.data);
        debugPrint('📊 Data:\n$json');
      } catch (e) {
        debugPrint('📊 Data: ${entry.data}');
      }
    }

    if (entry.error != null) {
      debugPrint('⚠️ Error: ${entry.error}');
    }

    if (entry.stackTrace != null) {
      debugPrint('📍 Stack Trace:\n${entry.stackTrace}');
    }
  }

  /// حفظ في ملف
  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFile == null) return;

    try {
      // التحقق من حجم الملف
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > maxLogFileSizeMB * 1024 * 1024) {
          // إنشاء ملف جديد
          final now = DateTime.now();
          final newName =
              'app_log_${DateFormat('yyyy-MM-dd_HHmmss').format(now)}.txt';
          final dir = _logFile!.parent;
          _logFile = File('${dir.path}/$newName');
        }
      }

      final line = entry.toFileString();
      await _logFile!.writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to write log to file: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // تنظيف البيانات الحساسة
  // ─────────────────────────────────────────────────────────────────────────

  /// تنظيف البيانات الحساسة
  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final keyStr = key.toString().toLowerCase();
        if (_isSensitiveKey(keyStr)) {
          sanitized[key] = '***HIDDEN***';
        } else {
          sanitized[key] = _sanitizeData(value);
        }
      });
      return sanitized;
    }

    if (data is List) {
      return data.map((item) => _sanitizeData(item)).toList();
    }

    return data;
  }

  /// هل المفتاح حساس؟
  bool _isSensitiveKey(String key) {
    const sensitiveKeys = [
      'password',
      'token',
      'secret',
      'api_key',
      'apikey',
      'auth',
      'authorization',
      'credit_card',
      'card_number',
      'cvv',
      'ssn',
      'national_id',
    ];

    return sensitiveKeys.any((sensitive) => key.contains(sensitive));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // تصدير واستيراد
  // ─────────────────────────────────────────────────────────────────────────

  /// تصدير كل السجلات إلى JSON
  String exportLogsAsJson() {
    final data = _logs.map((log) => log.toJson()).toList();
    return JsonEncoder.withIndent('  ').convert(data);
  }

  /// تصدير كل السجلات إلى نص
  String exportLogsAsText() {
    return _logs.map((log) => log.toFileString()).join('\n');
  }

  /// الحصول على ملف السجل
  File? getLogFile() => _logFile;

  /// مسح كل السجلات من الذاكرة
  void clearLogs() {
    _logs.clear();
    info('Logs cleared from memory', tag: 'AppLogger');
  }

  /// حذف ملف السجل
  Future<void> deleteLogFile() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
      info('Log file deleted', tag: 'AppLogger');
    }
  }

  /// الحصول على إحصائيات السجلات
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{'total_logs': _logs.length, 'by_level': {}};

    for (final level in LogLevel.values) {
      final count = _logs.where((log) => log.level == level).length;
      stats['by_level'][level.label] = count;
    }

    return stats;
  }

  /// البحث في السجلات
  List<LogEntry> search({
    String? query,
    LogLevel? level,
    String? tag,
    DateTime? from,
    DateTime? to,
  }) {
    return _logs.where((log) {
      if (query != null &&
          !log.message.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      if (level != null && log.level != level) return false;
      if (tag != null && log.tag != tag) return false;
      if (from != null && log.timestamp.isBefore(from)) return false;
      if (to != null && log.timestamp.isAfter(to)) return false;
      return true;
    }).toList();
  }

  /// إغلاق
  void dispose() {
    _logStreamController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Log Entry - إدخال السجل
// ═══════════════════════════════════════════════════════════════════════════

class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.data,
  });

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level.label,
      'message': message,
      if (tag != null) 'tag': tag,
      'timestamp': timestamp.toIso8601String(),
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      if (data != null) 'data': data,
    };
  }

  /// تحويل إلى نص للملف
  String toFileString() {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final tagStr = tag != null ? '[$tag]' : '';
    final sb = StringBuffer();

    sb.write('[$time] ${level.label} $tagStr $message');

    if (data != null) {
      try {
        final json = JsonEncoder.withIndent('  ').convert(data);
        sb.write('\n  Data: $json');
      } catch (e) {
        sb.write('\n  Data: $data');
      }
    }

    if (error != null) {
      sb.write('\n  Error: $error');
    }

    if (stackTrace != null) {
      sb.write('\n  Stack Trace: $stackTrace');
    }

    return sb.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Performance Timer - مؤقت الأداء
// ═══════════════════════════════════════════════════════════════════════════

class PerformanceTimer {
  final String operation;
  final String? tag;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceTimer(this.operation, {this.tag}) {
    _stopwatch.start();
    AppLogger.instance.debug('Started: $operation', tag: tag ?? 'Performance');
  }

  /// إيقاف المؤقت وتسجيل النتيجة
  Duration stop() {
    _stopwatch.stop();
    final duration = _stopwatch.elapsed;

    AppLogger.instance.performance(
      'Completed: $operation',
      tag: tag ?? 'Performance',
      duration: duration,
    );

    return duration;
  }

  /// الحصول على الوقت المنقضي دون إيقاف
  Duration get elapsed => _stopwatch.elapsed;
}

// ═══════════════════════════════════════════════════════════════════════════
// تسجيل مختصر - للاستخدام السريع
// ═══════════════════════════════════════════════════════════════════════════

// استخدام مختصر
final log = AppLogger.instance;

/// قياس وقت تنفيذ عملية
Future<T> measurePerformance<T>(
  String operation,
  Future<T> Function() action, {
  String? tag,
}) async {
  final timer = PerformanceTimer(operation, tag: tag);
  try {
    return await action();
  } finally {
    timer.stop();
  }
}

/// قياس وقت تنفيذ عملية متزامنة
T measurePerformanceSync<T>(
  String operation,
  T Function() action, {
  String? tag,
}) {
  final timer = PerformanceTimer(operation, tag: tag);
  try {
    return action();
  } finally {
    timer.stop();
  }
}
