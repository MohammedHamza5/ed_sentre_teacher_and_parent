import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// NotificationService — Teacher & Parent App
///
/// استراتيجية:
/// 1. Supabase Realtime: يستمع لإشعارات جديدة عبر Postgres Changes
/// 2. Local Notifications: يعرض إشعار محلي عندما يكون التطبيق مفتوحاً
/// 3. Device Token: يسجل التوكن لربط الجهاز بالمستخدم
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  RealtimeChannel? _channel;
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  Stream<int> get unreadCountStream => _unreadCountController.stream;

  bool _initialized = false;

  /// تهيئة النظام
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. إعداد Local Notifications
    await _initLocalNotifications();

    // 2. تسجيل device token
    await _registerDeviceToken();

    // 3. بدء الاستماع لـ Realtime
    _startRealtimeListener();

    // 4. جلب عدد الإشعارات غير المقروءة
    await _updateUnreadCount();

    _initialized = true;
    debugPrint('🔔 [NotificationService] Initialized for Teacher/Parent');
  }

  /// إعداد Local Notifications
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse details) {
    // NOTE: سيتم ربط هذا بالـ GoRouter لاحقاً
    debugPrint('🔔 Notification tapped: ${details.payload}');
  }

  /// تسجيل توكن الجهاز في Supabase
  Future<void> _registerDeviceToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // NOTE: بدون FCM نستخدم user_id + platform كمعرف
      // عندما نضيف FCM لاحقاً سنستبدل هذا بـ FCM Token
      final deviceToken =
          '${user.id}_mobile_${Platform.operatingSystem}';

      await Supabase.instance.client.rpc('upsert_device_token', params: {
        'p_token': deviceToken,
        'p_platform': Platform.operatingSystem,
        'p_device_type': 'mobile',
        'p_app_type': 'teacher',
      });
      debugPrint('✅ [NotificationService] Device token registered');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to register token: $e');
    }
  }

  /// إلغاء توكن الجهاز عند تسجيل الخروج
  Future<void> deactivateToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final deviceToken =
          '${user.id}_mobile_${Platform.operatingSystem}';
      await Supabase.instance.client
          .rpc('deactivate_device_token', params: {'p_token': deviceToken});
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to deactivate token: $e');
    }
  }

  /// بدء الاستماع لإشعارات جديدة عبر Realtime Postgres Changes
  void _startRealtimeListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _channel?.unsubscribe();

    _channel = Supabase.instance.client
        .channel('notifications_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              _showLocalNotification(newRecord);
              _updateUnreadCount();
            }
          },
        )
        .subscribe();
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    const androidDetails = AndroidNotificationDetails(
      'edsentre_teacher_channel',
      'EdSentre Teacher',
      channelDescription: 'إشعارات المعلم وولي الأمر',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification['id'].toString().hashCode,
      notification['title'] ?? 'إشعار جديد',
      notification['body'] ?? '',
      details,
      payload: notification['data']?.toString(),
    );
  }

  /// تحديث عدد الإشعارات غير المقروءة
  Future<void> _updateUnreadCount() async {
    try {
      final count = await Supabase.instance.client.rpc(
        'get_unread_notifications_count',
      );
      _unreadCountController.add(count as int);
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to update count: $e');
    }
  }

  /// إعادة الاتصال (بعد تسجيل الدخول)
  Future<void> reconnect() async {
    await _registerDeviceToken();
    _startRealtimeListener();
    await _updateUnreadCount();
  }

  /// تنظيف الموارد
  void dispose() {
    _channel?.unsubscribe();
    _unreadCountController.close();
  }
}
