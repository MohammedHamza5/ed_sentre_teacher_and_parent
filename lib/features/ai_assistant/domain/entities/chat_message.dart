enum ChatMessageType { text, toolCall, toolResult }
enum ChatMessageRole { user, assistant, system, tool }

class ChatMessage {
  final String id;
  final ChatMessageRole role;
  final ChatMessageType type;
  final String? content;
  final String? toolCallId;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.type,
    this.content,
    this.toolCallId,
    this.toolName,
    this.toolArgs,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: ChatMessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => ChatMessageRole.user,
      ),
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMessageType.text,
      ),
      content: json['content'] as String?,
      toolCallId: json['toolCallId'] as String?,
      toolName: json['toolName'] as String?,
      toolArgs: json['toolArgs'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'type': type.name,
      if (content != null) 'content': content,
      if (toolCallId != null) 'toolCallId': toolCallId,
      if (toolName != null) 'toolName': toolName,
      if (toolArgs != null) 'toolArgs': toolArgs,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    String? id,
    ChatMessageRole? role,
    ChatMessageType? type,
    String? content,
    String? toolCallId,
    String? toolName,
    Map<String, dynamic>? toolArgs,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      toolArgs: toolArgs ?? this.toolArgs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
