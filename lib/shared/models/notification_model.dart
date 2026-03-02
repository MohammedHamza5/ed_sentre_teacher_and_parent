/// Notification Model - Maps to public.notifications table
class NotificationModel {
  final String id;
  final String userId;
  final String? centerId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String priority;
  final DateTime createdAt;

  // Additional fields
  final String? centerName;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.centerId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.data,
    this.priority = 'normal',
    required this.createdAt,
    this.centerName,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? centerId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    Map<String, dynamic>? data,
    String? priority,
    DateTime? createdAt,
    String? centerName,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      centerId: centerId ?? this.centerId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      centerName: centerName ?? this.centerName,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      centerId: json['center_id'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      priority: json['priority'] as String? ?? 'normal',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      centerName: json['center_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'center_id': centerId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'data': data,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeIcon {
    switch (type) {
      case 'attendance':
        return '📋';
      case 'grade':
        return '📊';
      case 'payment':
        return '💰';
      case 'assignment':
        return '📝';
      case 'message':
        return '💬';
      case 'announcement':
        return '📢';
      default:
        return '🔔';
    }
  }

  bool get isHighPriority => priority == 'high' || priority == 'urgent';
}
