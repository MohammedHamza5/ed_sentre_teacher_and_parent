import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/ai_assistant_repository.dart';
import 'ai_assistant_state.dart';

class AIAssistantCubit extends Cubit<AIAssistantState> {
  final AIAssistantRepository _repository;
  
  List<ChatMessage> _messages = [];

  AIAssistantCubit(this._repository) : super(const AIAssistantInitial()) {
    // Initial welcome message
    _messages = [
      ChatMessage(
        id: const Uuid().v4(),
        role: ChatMessageRole.assistant,
        type: ChatMessageType.text,
        content: 'أهلاً بك! أنا مساعدك الذكي 🤖\nكيف يمكنني مساعدتك اليوم؟ (مثال: "اعمل امتحان على الوحدة الثالثة" أو "ما هي نقاط ضعف المجموعة A؟")',
        createdAt: DateTime.now(),
      ),
    ];
    emit(AIAssistantSuccess(messages: List.unmodifiable(_messages)));
  }

  Future<void> sendMessage({
    required String text,
    required String teacherId,
    required String centerId,
    required Map<String, dynamic> contextPayload,
  }) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      role: ChatMessageRole.user,
      type: ChatMessageType.text,
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    _messages = List.from(_messages)..add(userMessage);
    emit(AIAssistantLoading(messages: List.unmodifiable(_messages)));

    final result = await _repository.sendMessage(
      teacherId: teacherId,
      centerId: centerId,
      history: _messages, // send everything
      message: text.trim(),
      contextPayload: contextPayload,
    );

    result.when(
      success: (newMessages) {
        _messages = List.from(_messages)..addAll(newMessages);
        emit(AIAssistantSuccess(messages: List.unmodifiable(_messages)));
      },
      failure: (failure) {
        emit(AIAssistantFailure(
          message: failure.message,
          messages: List.unmodifiable(_messages),
        ));
      },
    );
  }

  void handleToolResult(String toolCallId, Map<String, dynamic> result) {
    final toolResultMessage = ChatMessage(
      id: const Uuid().v4(),
      role: ChatMessageRole.tool,
      type: ChatMessageType.toolResult,
      toolCallId: toolCallId,
      toolArgs: result,
      createdAt: DateTime.now(),
    );
    _messages = List.from(_messages)..add(toolResultMessage);
    emit(AIAssistantSuccess(messages: List.unmodifiable(_messages)));
    
    // Optionally trigger another send to the AI so it continues reasoning
  }

  void clearSession() {
    _messages.clear();
    _repository.clearSession();
    emit(const AIAssistantInitial());
  }
}
