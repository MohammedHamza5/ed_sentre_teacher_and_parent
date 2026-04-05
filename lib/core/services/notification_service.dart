import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../app_router.dart';

/// NotificationService — Teacher & Parent App
///
/// استراتيجية:
/// 1. FCM Push: يستلم إشعارات حقيقية حتى لو التطبيق مغلق
/// 2. Supabase Realtime: يحدّث عداد الإشعارات غير المقروءة فوراً
/// 3. Local Notifications: يعرض إشعار محلي عند استلام FCM في الـ Foreground
/// 4. Device Token: يسجل الـ FCM Token في قاعدة البيانات
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

  // NOTE: تخزين الـ subscriptions لمنع تسريب الذاكرة
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  /// تهيئة النظام
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. إعداد Local Notifications
    await _initLocalNotifications();

    // 2. تسجيل FCM token
    await _registerDeviceToken();

    // 3. بدء الاستماع لـ Realtime (لتحديث العداد فقط)
    _startRealtimeListener();

    // 4. جلب عدد الإشعارات غير المقروءة
    await _updateUnreadCount();

    _initialized = true;
    debugPrint('🔔 [NotificationService] Initialized for Teacher/Parent');
  }

  /// إعداد Local Notifications
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

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
    debugPrint('🔔 Notification tapped: ${details.payload}');
    _navigateToNotifications();
  }

  Future<void> _navigateToNotifications() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final data = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
          
      final role = data['role'] as String?;
      // Small delay to ensure router is ready
      await Future.delayed(const Duration(milliseconds: 300));
      if (role == 'teacher') {
        AppRouter.router.push('/teacher/notifications');
      } else if (role == 'parent') {
        AppRouter.router.push('/parent/notifications');
      }
    } catch (e) {
      debugPrint('⚠️ Error navigating to notifications: $e');
    }
  }

  /// تسجيل توكن الجهاز في Supabase عبر FCM
  Future<void> _registerDeviceToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // طلب الإذن (مهم جداً للـ iOS و Android 13+)
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ [NotificationService] User declined notifications permission.');
        return;
      }

      // جلب توكن الفايربيز الفعلي
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await _saveTokenToSupabase(fcmToken, user.id);
      }

      // NOTE: إلغاء الاشتراك القديم أولاً لمنع التكرار
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken, user.id);
      });

      // NOTE: إلغاء Foreground listener القديم أولاً لمنع إشعارات مكررة
      _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM] Foreground message received');
        if (message.notification != null) {
          _showLocalNotification(
            title: message.notification!.title ?? 'إشعار جديد',
            body: message.notification!.body ?? '',
            id: message.hashCode,
          );
          _updateUnreadCount();
        }
      });

      // Handle notification tapped from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM] Notification Tapped from Background');
        _navigateToNotifications();
      });

      // Handle notification tapped from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 [FCM] Notification Tapped from Terminated State');
        _navigateToNotifications();
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to register FCM token: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token, String userId) async {
    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.operatingSystem,
        'app_type': 'teacher_parent',
        'last_active': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');

      debugPrint('✅ [NotificationService] FCM Token saved to Supabase');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Supabase token save error: $e');
    }
  }

  /// إلغاء توكن الجهاز عند تسجيل الخروج
  Future<void> deactivateToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await Supabase.instance.client
            .from('device_tokens')
            .delete()
            .eq('fcm_token', fcmToken);
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to deactivate token: $e');
    }
  }

  /// بدء الاستماع لإشعارات جديدة عبر Realtime Postgres Changes
  /// NOTE: يُستخدم فقط لتحديث عداد غير المقروءة — FCM يتكفل بعرض الإشعار
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
            // NOTE: تحديث العداد فقط — بدون إشعار محلي لتجنب التكرار مع FCM
            _updateUnreadCount();
          },
        )
        .subscribe();
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
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

    await _localNotifications.show(id, title, body, details);
  }

  /// تحديث عدد الإشعارات غير المقروءة
  Future<void> _updateUnreadCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false);

      _unreadCountController.add((data as List).length);
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
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _channel?.unsubscribe();
    _unreadCountController.close();
  }
}
