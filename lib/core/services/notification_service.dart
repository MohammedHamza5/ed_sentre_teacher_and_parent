import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _subscription;
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    // 1. Setup Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap
      },
    );

    // 2. Initial Unread Count
    await _updateUnreadCount();

    // 3. Start Listening
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _subscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            if (data.isNotEmpty) {
              final latest = data.first;
              // Simple check: Only notify if created recently (< 20s)
              final createdAt = DateTime.tryParse(
                latest['created_at'].toString(),
              );
              if (createdAt != null &&
                  DateTime.now().difference(createdAt).inSeconds < 20) {
                _showLocalNotification(latest);
              }
            }
            _updateUnreadCount();
          },
          onError: (e) {
            if (kDebugMode) debugPrint('Notification Stream Error: $e');
          },
        );
  }

  Future<void> _updateUnreadCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    final count = response.length;
    _unreadCountController.add(count);
  }

  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'ed_sentre_parent_channel',
          'Ed Sentre Updates',
          channelDescription: 'Important updates for parents',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      (notification['id'] as String).hashCode,
      notification['title'],
      notification['body'],
      platformChannelSpecifics,
      payload: notification['data'].toString(),
    );
  }

  void dispose() {
    _subscription?.cancel();
    _unreadCountController.close();
  }
}
