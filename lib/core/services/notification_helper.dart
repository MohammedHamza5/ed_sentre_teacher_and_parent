import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// NotificationHelper — Teacher App
///
/// دوال مساعدة لإرسال إشعارات من تطبيق المعلم.
/// كل INSERT في notifications → Trigger → Edge Function → Push
class NotificationHelper {
  NotificationHelper._();

  static SupabaseClient get _client => Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // إشعارات الحضور
  // ═══════════════════════════════════════════════════════════════════════════

  /// إشعار: تسجيل حضور لمجموعة — يُرسل لأولياء الأمور
  static Future<void> notifyAttendanceRecorded({
    required String groupId,
    required String groupName,
    required String courseName,
    required String date,
  }) async {
    try {
      await _client.rpc(
        'create_notification_for_group',
        params: {
          'p_group_id': groupId,
          'p_title': '📋 تم تسجيل حضور اليوم',
          'p_body': 'تم تسجيل حضور $groupName لمادة $courseName ($date)',
          'p_type': 'attendance',
          'p_target_app': 'student',
          'p_data': {'route': '/attendance', 'date': date},
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationHelper] Attendance notification failed: $e');
    }
  }

  /// إشعار: غياب طالب — يُرسل لولي الأمر
  static Future<void> notifyStudentAbsent({
    required String studentId,
    required String studentName,
    required String courseName,
    required String centerId,
    required String date,
  }) async {
    try {
      await _client.rpc(
        'create_notification_for_student_parents',
        params: {
          'p_student_id': studentId,
          'p_center_id': centerId,
          'p_title': '⚠️ غياب $studentName',
          'p_body': 'تغيب $studentName عن حصة $courseName يوم $date',
          'p_type': 'attendance',
          'p_data': {'route': '/attendance', 'date': date},
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationHelper] Absence notification failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إشعارات الدرجات
  // ═══════════════════════════════════════════════════════════════════════════

  /// إشعار: رصد درجة امتحان
  static Future<void> notifyExamGradeRecorded({
    required String studentUserId,
    required String studentName,
    required String examName,
    required double grade,
    required String centerId,
  }) async {
    await _createNotification(
      userId: studentUserId,
      centerId: centerId,
      title: '📝 درجة امتحان جديدة',
      body: 'حصلت على $grade في امتحان $examName',
      type: 'grade',
      targetApp: 'student',
      data: {'route': '/grades'},
    );
  }

  /// إشعار: رصد درجات لمجموعة كاملة
  static Future<void> notifyGroupGrades({
    required String groupId,
    required String examName,
  }) async {
    try {
      await _client.rpc(
        'create_notification_for_group',
        params: {
          'p_group_id': groupId,
          'p_title': '📝 تم رصد درجات $examName',
          'p_body': 'تم رصد درجات الامتحان. اطلع على نتيجتك الآن!',
          'p_type': 'grade',
          'p_target_app': 'student',
          'p_data': {'route': '/grades'},
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationHelper] Grade notification failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إشعارات الواجبات
  // ═══════════════════════════════════════════════════════════════════════════

  /// إشعار: واجب جديد لمجموعة
  static Future<void> notifyNewHomework({
    required String groupId,
    required String courseName,
    required String homeworkTitle,
    String? deadline,
  }) async {
    try {
      await _client.rpc(
        'create_notification_for_group',
        params: {
          'p_group_id': groupId,
          'p_title': '📚 واجب جديد: $courseName',
          'p_body': deadline != null
              ? '$homeworkTitle — آخر موعد: $deadline'
              : homeworkTitle,
          'p_type': 'homework',
          'p_target_app': 'student',
          'p_data': {'route': '/homework'},
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationHelper] Homework notification failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إشعارات الرسائل
  // ═══════════════════════════════════════════════════════════════════════════

  /// إشعار: رسالة جديدة لولي أمر
  static Future<void> notifyParentMessage({
    required String parentUserId,
    required String teacherName,
    required String message,
    required String centerId,
  }) async {
    await _createNotification(
      userId: parentUserId,
      centerId: centerId,
      title: '💬 رسالة من مستر $teacherName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      type: 'message',
      targetApp: 'parent',
      data: {'route': '/messages'},
    );
  }

  /// إشعار: رسالة جديدة لطالب
  static Future<void> notifyStudentMessage({
    required String studentUserId,
    required String teacherName,
    required String message,
    required String centerId,
  }) async {
    await _createNotification(
      userId: studentUserId,
      centerId: centerId,
      title: '💬 رسالة من مستر $teacherName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      type: 'message',
      targetApp: 'student',
      data: {'route': '/chat_list'},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إشعارات المحتوى العلمي والملازم
  // ═══════════════════════════════════════════════════════════════════════════

  /// إشعار: ملزمة جديدة لمجموعة
  static Future<void> notifyMaterialUploaded({
    required String groupId,
    required String courseName,
    required String materialTitle,
  }) async {
    try {
      await _client.rpc(
        'create_notification_for_group',
        params: {
          'p_group_id': groupId,
          'p_title': '📚 ملزمة جديدة: $courseName',
          'p_body': 'تم رفع: $materialTitle',
          'p_type': 'materials',
          'p_target_app': 'student',
          'p_data': {'route': '/curriculum'},
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationHelper] Material notification failed: $e');
    }
  }

  /// إشعار: واجب / اختبار جديد لمجموعة
  static Future<void> notifyAssignmentCreated({
    required String groupId,
    required String courseName,
    required String assignmentTitle,
    required String assignmentType, // 'homework' or 'exam'
  }) async {
    try {
      final titlePrefix = assignmentType == 'exam' ? '📝 اختبار جديد' : '✍️ واجب جديد';
      final route = assignmentType == 'exam' ? '/exam' : '/homework';
      await _client.rpc(
        'create_notification_for_group',
        params: {
          'p_group_id': groupId,
          'p_title': '$titlePrefix: $courseName',
          'p_body': 'تم إضافة: $assignmentTitle',
          'p_type': 'assignment',
          'p_target_app': 'student',
          'p_data': {'route': route},
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationHelper] Assignment creation notification failed: $e');
    }
  }

  /// إشعار: تقييم واجب لطالب
  static Future<void> notifyAssignmentGraded({
    required String studentUserId,
    required String assignmentTitle,
    required double grade,
    required String centerId,
  }) async {
    await _createNotification(
      userId: studentUserId,
      centerId: centerId,
      title: '✅ تم تقييم واجبك',
      body: 'حصلت على $grade في واجب $assignmentTitle',
      type: 'grade',
      targetApp: 'student',
      data: {'route': '/homework'},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _createNotification({
    required String userId,
    required String centerId,
    required String title,
    required String body,
    required String type,
    String priority = 'normal',
    String targetApp = 'all',
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'center_id': centerId,
        'sender_id': _client.auth.currentUser?.id,
        'title': title,
        'body': body,
        'type': type,
        'priority': priority,
        'target_app': targetApp,
        'data_payload': data ?? {},
        'is_read': false,
      });
    } catch (e) {
      debugPrint('⚠️ [NotificationHelper] Failed to create notification: $e');
    }
  }
}
