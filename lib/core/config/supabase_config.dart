/// Supabase Configuration — App 3 (Teacher & Parent)
///
/// ⚠️  SECURITY NOTICE:
/// ─────────────────────────────────────────────────────────────────────────
/// القيم الـ defaultValue هنا مخصصة للـ Development فقط.
/// في الـ Production Build، يجب تمرير القيم عبر --dart-define:
///
///   flutter build apk \
///     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
///
/// ⚠️  لا تضع مفاتيح الإنتاج الحقيقية في هذا الملف على Git.
/// ─────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/foundation.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // ─── Supabase Credentials ──────────────────────────────────────────────

  /// Supabase Project URL — يُقرأ من dart-define أولاً
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mbmqrmgdgygznbqvvfqi.supabase.co',
  );

  /// Supabase Anonymous Key — آمن للاستخدام في Flutter
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ibXFybWdkZ3lnem5icXZ2ZnFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2ODM5MjYsImV4cCI6MjA3MDI1OTkyNn0'
        '.S9cGzmAzAsKLfVQz58a-g1dj9Bm8_xeFbpG5LlH5PRs',
  );

  // ─── Storage Buckets ───────────────────────────────────────────────────

  static const String avatarsBucket = 'avatars';
  static const String materialsBucket = 'study-materials';
  static const String assignmentsBucket = 'assignments';
  static const String submissionsBucket = 'submissions';

  // ─── Environment Helpers ───────────────────────────────────────────────

  /// هل القيم جاية من dart-define (إنتاج) أم من الـ defaultValue (تطوير)؟
  static bool get isUsingEnvCredentials =>
      const String.fromEnvironment('SUPABASE_URL').isNotEmpty;

  /// طباعة تحذير في Debug إذا كانت القيم الـ hardcoded هي المُستخدمة
  static void warnIfUsingDefaults() {
    if (kDebugMode && !isUsingEnvCredentials) {
      debugPrint('');
      debugPrint('⚠️  ════════════════════════════════════════════════════');
      debugPrint('⚠️  [App3] SUPABASE: Using HARDCODED dev credentials');
      debugPrint('⚠️  Pass --dart-define=SUPABASE_URL=... for production');
      debugPrint('⚠️  ════════════════════════════════════════════════════');
      debugPrint('');
    }
  }

  /// التحقق من صحة الإعدادات — يرمي Exception إذا القيم فارغة
  static void validate() {
    if (url.isEmpty) {
      throw Exception(
        '❌ SupabaseConfig.url is empty.\n'
        'Pass --dart-define=SUPABASE_URL=https://... during build.',
      );
    }
    if (anonKey.isEmpty) {
      throw Exception(
        '❌ SupabaseConfig.anonKey is empty.\n'
        'Pass --dart-define=SUPABASE_ANON_KEY=eyJ... during build.',
      );
    }
  }
}
