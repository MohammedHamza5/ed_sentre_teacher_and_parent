import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/ai_config.dart';
import '../models/ai_models.dart';

class AiService {
  final SupabaseClient _client;

  AiService(this._client);

  late final AiRouterService router = AiRouterService(this);

  /// Send a task-based request to the AI Teacher Edge Function
  Future<String?> sendTaskRequest({
    required String task,
    required String content,
    Map<String, dynamic> params = const {},
    String? model,
  }) async {
    try {
      if (kDebugMode) {
        print('🧠 AI Teacher Task: $task | model=${model ?? "auto"}');
      }
      final response = await _client.functions.invoke(
        'ai-teacher',
        body: {
          'task': task,
          'content': content,
          'params': params,
          'model': model,
        },
      );

      if (response.data != null && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        return data['content'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ AI Teacher Task Error: $e');
      return null;
    }
  }
}

class AiRouterService {
  final AiService _aiService;
  final AiQualityValidator _validator;

  AiRouterService(this._aiService) : _validator = AiQualityValidator();

  Future<AiRouterResponse> executeTask({
    required EdSentreTask task,
    required String content,
    Map<String, dynamic> params = const {},
    bool? expectsJson,
    List<String>? requiredKeys,
  }) async {
    final jsonRequired = expectsJson ?? _defaultJsonForTask(task);
    final keys = requiredKeys ?? _requiredKeysForTask(task);
    final model = AiConfig.resolveModelForTask(task);

    final raw = await _aiService.sendTaskRequest(
      task: task.name,
      content: content,
      params: params,
      model: model,
    );

    final validation = _validator.validate(
      raw: raw,
      expectsJson: jsonRequired,
      requiredKeys: keys,
    );

    return AiRouterResponse(
      raw: raw,
      json: validation.json,
      model: model,
      usedLongContext: false,
      isValid: validation.isValid,
      error: validation.error,
    );
  }

  bool _defaultJsonForTask(EdSentreTask task) {
    switch (task) {
      case EdSentreTask.teacherGenerateExam:
      case EdSentreTask.teacherGenerateAssignment:
      case EdSentreTask.teacherAnalyzeClassPerformance:
      case EdSentreTask.teacherExtractConceptsFromBook:
        return true;
      default:
        return false;
    }
  }

  List<String> _requiredKeysForTask(EdSentreTask task) {
    switch (task) {
      case EdSentreTask.teacherGenerateExam:
        return ['questions', 'total_marks'];
      case EdSentreTask.teacherGenerateAssignment:
        return ['questions'];
      case EdSentreTask.teacherAnalyzeClassPerformance:
        return ['insights'];
      case EdSentreTask.teacherExtractConceptsFromBook:
        return ['concepts'];
      default:
        return const [];
    }
  }
}

class AiQualityResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? json;

  const AiQualityResult({required this.isValid, this.error, this.json});
}

class AiQualityValidator {
  AiQualityResult validate({
    required String? raw,
    required bool expectsJson,
    required List<String> requiredKeys,
  }) {
    if (raw == null || raw.isEmpty) {
      return const AiQualityResult(isValid: false, error: 'empty_response');
    }

    if (!expectsJson) {
      return const AiQualityResult(isValid: true);
    }

    try {
      final cleaned = _cleanJson(raw);
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        for (final key in requiredKeys) {
          if (!decoded.containsKey(key)) {
            return AiQualityResult(isValid: false, error: 'missing_$key');
          }
        }
        return AiQualityResult(isValid: true, json: decoded);
      }
      if (decoded is List && requiredKeys.isEmpty) {
        return AiQualityResult(isValid: true, json: {'items': decoded});
      }
      return const AiQualityResult(isValid: false, error: 'invalid_shape');
    } catch (_) {
      return const AiQualityResult(isValid: false, error: 'invalid_json');
    }
  }

  String _cleanJson(String text) {
    var clean = text.trim();
    if (clean.startsWith('```json')) {
      clean = clean.replaceAll('```json', '').replaceAll('```', '');
    } else if (clean.startsWith('```')) {
      clean = clean.replaceAll('```', '');
    }
    return clean.trim();
  }
}
