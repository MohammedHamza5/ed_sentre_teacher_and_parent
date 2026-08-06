import '../../../../core/errors/result.dart';
import '../entities/chat_message.dart';

abstract class AIAssistantRepository {
  /// Send a message to the AI Assistant and get the response stream or full result
  /// For this MVP, we'll return a single AsyncResult with the new messages (or tool calls)
  AsyncResult<List<ChatMessage>> sendMessage({
    required String teacherId,
    required String centerId,
    required List<ChatMessage> history,
    required String message,
    required Map<String, dynamic> contextPayload,
  });

  /// Clear the session or reset memory
  AsyncResult<void> clearSession();
}
