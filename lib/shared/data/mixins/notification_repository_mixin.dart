import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/models.dart';
import '../base_repository.dart';

/// Notification Repository Mixin
/// Handles notification CRUD and realtime subscriptions
mixin NotificationRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get notifications
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
      final userId = currentUserId;
      if (userId == null) return;
      
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Subscribe to notifications
  RealtimeChannel subscribeToNotifications(
    String userId,
    void Function(Map<String, dynamic>) onNotification,
  ) {
    return client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
          },
        )
        .subscribe();
  }
}
