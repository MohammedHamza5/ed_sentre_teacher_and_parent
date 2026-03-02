enum EdSentreTask {
  studentCreateFlashcards,
  studentCreateStudySchedule,
  studentChatTutor,
  studentSummarizeLesson,
  studentGradeMCQ,
  studentGradeEssay,
  teacherGenerateExam,
  teacherGenerateAssignment,
  teacherGradeEssay,
  teacherAnalyzeClassPerformance,
  teacherExtractConceptsFromBook,
  teacherChatAssistant,
  systemIndexDocument,
  systemClassifyContent,
  systemCleanAndFormatText,
}

class AiConfig {
  static const String modelMax = 'qwen-max';
  static const String modelSmart = 'qwen-plus';
  static const String modelFast = 'qwen-flash';
  static const String modelLongDoc = 'qwen-long';
  static const String defaultModel = modelSmart;

  static bool get useSupabaseAiProxy => true;

  // Note: System Prompt is now handled server-side in Edge Function ai-tutor

  static String resolveModel({required String taskType, int? contentLength}) {
    switch (taskType) {
      case 'chat':
        return modelFast;
      case 'flashcards':
      case 'summarize':
      case 'document':
        if (contentLength != null && contentLength > 4000) {
          return modelLongDoc;
        }
        if (contentLength != null && contentLength < 800) {
          return modelFast;
        }
        return modelSmart;
      case 'exam_analysis':
      case 'exam_generation':
      case 'oral_exam':
        return modelMax;
      default:
        return modelSmart;
    }
  }

  static String resolveModelForTask(
    EdSentreTask task, {
    int? contentLength,
    bool isComplex = false,
  }) {
    switch (task) {
      // --- Qwen-Long (The Reader) ---
      case EdSentreTask.studentCreateFlashcards: // If long content
      case EdSentreTask.studentSummarizeLesson: // If long content
      case EdSentreTask.teacherExtractConceptsFromBook:
      case EdSentreTask.systemIndexDocument:
        if (contentLength != null && contentLength > 4000) {
          return modelLongDoc;
        }
        return modelSmart; // Fallback to Plus if content is short

      // --- Qwen-Max (The Expert) ---
      case EdSentreTask.studentGradeEssay:
      case EdSentreTask.teacherGenerateExam:
      case EdSentreTask.teacherGradeEssay:
      case EdSentreTask.teacherAnalyzeClassPerformance:
        return modelMax;

      case EdSentreTask.studentChatTutor:
        return isComplex ? modelMax : modelSmart;

      // --- Qwen-Plus (The Tutor) ---
      case EdSentreTask.studentCreateStudySchedule:
      case EdSentreTask.teacherGenerateAssignment:
      case EdSentreTask.teacherChatAssistant: // New Teacher Chat
        return modelSmart;

      // --- Qwen-Flash (The Fast Worker) ---
      case EdSentreTask.studentGradeMCQ:
      case EdSentreTask.systemClassifyContent:
      case EdSentreTask.systemCleanAndFormatText:
        return modelFast;
    }
  }
}
