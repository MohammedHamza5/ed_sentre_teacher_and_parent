import '../../../domain/entities/chat_message.dart';

sealed class AIAssistantState {
  const AIAssistantState();
}

class AIAssistantInitial extends AIAssistantState {
  const AIAssistantInitial();
}

class AIAssistantLoading extends AIAssistantState {
  final List<ChatMessage> messages;
  const AIAssistantLoading({required this.messages});
}

class AIAssistantSuccess extends AIAssistantState {
  final List<ChatMessage> messages;
  const AIAssistantSuccess({required this.messages});
}

class AIAssistantFailure extends AIAssistantState {
  final String message;
  final List<ChatMessage> messages;
  const AIAssistantFailure({required this.message, required this.messages});
}
