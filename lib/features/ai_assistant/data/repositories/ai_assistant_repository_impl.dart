import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/entities/chat_message.dart';

class AIAssistantRepositoryImpl implements AIAssistantRepository {
  final SupabaseClient _client = Supabase.instance.client;

  AIAssistantRepositoryImpl();

  @override
  AsyncResult<List<ChatMessage>> sendMessage({
    required String teacherId,
    required String centerId,
    required List<ChatMessage> history,
    required String message,
    required Map<String, dynamic> contextPayload,
  }) async {
    try {
      // 1. Fetch current daily usage count from Supabase
      int todayExamCount = 0;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      try {
        final usageRes = await _client
            .from('ai_usage_log')
            .select('id')
            .eq('teacher_id', teacherId)
            .inFilter('action_type', [
              'generate_exam',
              'generate_assignment',
              'analyze_student',
              'analyze_group',
            ])
            .gte('created_at', startOfDay.toIso8601String());
        todayExamCount = (usageRes as List).length;
      } catch (e) {
        debugPrint('Error fetching daily usage in repository: $e');
      }

      const int maxDailyLimit = 5;
      final bool canGenerate = todayExamCount < maxDailyLimit;
      final int remainingQuota = (maxDailyLimit - todayExamCount).clamp(0, maxDailyLimit);

      final enrichedContext = Map<String, dynamic>.from(contextPayload)..addAll({
        'can_generate_exam': canGenerate,
        'remaining_exam_quota': remainingQuota,
        'daily_exam_limit': maxDailyLimit,
      });

      final messagesJson = history.map((m) => m.toJson()).toList();
      
      final edgeResponse = await _client.functions.invoke(
        'ai-teacher-assistant',
        body: {
          'teacher_id': teacherId,
          'center_id': centerId,
          'message': message,
          'history': messagesJson,
          'context': enrichedContext,
        },
      );

      final data = edgeResponse.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final newMessages = (data['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        
        final processedMessages = <ChatMessage>[];

        for (final msg in newMessages) {
          if (msg.type == ChatMessageType.toolCall && msg.toolName == 'generate_exam') {
            if (!canGenerate) {
              // Override tool call response with daily quota refusal message
              processedMessages.add(ChatMessage(
                id: msg.id,
                role: ChatMessageRole.assistant,
                type: ChatMessageType.text,
                content: 'عذراً يا أستاذ، لقد استنفدت حدك اليومي المتاح لتوليد الامتحانات ($maxDailyLimit امتحانات/يوم). يمكنك مواصلة النقاش وطرح الاستفسارات هنا، ولتوليد امتحانات جديدة ننتظرك غداً! 🎯',
                createdAt: DateTime.now(),
              ));
              continue;
            } else {
              // Log tool call exam generation to ai_usage_log
              try {
                await _client.from('ai_usage_log').insert({
                  'teacher_id': teacherId,
                  'action_type': 'generate_exam',
                  'credits_used': 0,
                  'input_data': msg.toolArgs ?? {'source': 'ai_chat'},
                  'output_data': {'title': msg.toolArgs?['title'] ?? 'امتحان من المحادثة'},
                });
              } catch (e) {
                debugPrint('Error logging chat exam to ai_usage_log: $e');
              }
            }
          }
          processedMessages.add(msg);
        }

        return Result.success(processedMessages);
      } else {
        return Result.failure(ServerException(message: data['message'] ?? 'فشل في الاتصال بالمساعد الذكي'));
      }
    } catch (e, st) {
      debugPrint('Error sending message to AI: $e');
      return Result.failure(UnexpectedException(message: e.toString(), stackTrace: st, originalError: e));
    }
  }

  @override
  AsyncResult<void> clearSession() async {
    return Result.success(null);
  }
}
