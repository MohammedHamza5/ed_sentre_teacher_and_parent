import 'enums.dart';

/// Message Model - Maps to public.messages table
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final MessageType messageType;
  final String? fileUrl;
  final bool isRead;
  final DateTime createdAt;

  // Additional fields
  final String? senderName;
  final String? senderAvatar;
  final bool isMine;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.messageType = MessageType.text,
    this.fileUrl,
    this.isRead = false,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.isMine = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      fileUrl: json['file_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      isMine: currentUserId != null && json['sender_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType.name,
      'file_url': fileUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
