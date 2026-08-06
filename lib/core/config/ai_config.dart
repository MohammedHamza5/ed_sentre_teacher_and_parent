enum EdSentreTask {
  teacherGenerateExam,
  teacherGenerateDeepExam,
  teacherGenerateAssignment,
  teacherGradeEssay,
  teacherAnalyzeClassPerformance,
  teacherExtractConceptsFromBook,
  teacherChatAssistant,
  autoNameConversation,
}

class AiConfig {
  static const String modelMax = 'qwen-max';
  static const String modelSmart = 'qwen-plus';
  static const String modelFast = 'qwen-turbo';
  static const String defaultModel = modelSmart;

  /// Daily quota limits per teacher (Free Tier Safe Plan)
  static const int kDailyExamLimit = 10;
  static const int kDailyChatLimit = 100;

  /// Task costs in credits
  static const Map<EdSentreTask, int> taskCosts = {
    EdSentreTask.teacherChatAssistant: 2,
    EdSentreTask.teacherGenerateExam: 15,
    EdSentreTask.teacherGenerateDeepExam: 25,
    EdSentreTask.teacherGenerateAssignment: 10,
    EdSentreTask.teacherGradeEssay: 5,
    EdSentreTask.teacherAnalyzeClassPerformance: 10,
    EdSentreTask.teacherExtractConceptsFromBook: 5,
    EdSentreTask.autoNameConversation: 0, // Free — lightweight task
  };

  static int getCost(EdSentreTask task) => taskCosts[task] ?? 2;

  static String resolveModelForTask(EdSentreTask task) {
    switch (task) {
      // Qwen-Max — complex generation & analysis
      case EdSentreTask.teacherGenerateExam:
      case EdSentreTask.teacherGenerateDeepExam:
      case EdSentreTask.teacherGradeEssay:
      case EdSentreTask.teacherAnalyzeClassPerformance:
        return modelMax;

      // Qwen-Plus — balanced tasks
      case EdSentreTask.teacherGenerateAssignment:
      case EdSentreTask.teacherExtractConceptsFromBook:
      case EdSentreTask.teacherChatAssistant:
        return modelSmart;

      // Qwen-Turbo — fast & cheap
      case EdSentreTask.autoNameConversation:
        return modelFast;
    }
  }
}
