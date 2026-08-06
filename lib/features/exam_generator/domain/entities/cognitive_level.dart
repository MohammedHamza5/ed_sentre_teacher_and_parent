enum CognitiveLevel {
  remembering,
  understanding,
  applying,
  analyzing,
  evaluating,
  creating;

  static CognitiveLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'remembering':
        return CognitiveLevel.remembering;
      case 'understanding':
        return CognitiveLevel.understanding;
      case 'applying':
        return CognitiveLevel.applying;
      case 'analyzing':
        return CognitiveLevel.analyzing;
      case 'evaluating':
        return CognitiveLevel.evaluating;
      case 'creating':
        return CognitiveLevel.creating;
      default:
        return CognitiveLevel.understanding;
    }
  }

  String get arabicName {
    switch (this) {
      case CognitiveLevel.remembering:
        return 'التذكر';
      case CognitiveLevel.understanding:
        return 'الفهم';
      case CognitiveLevel.applying:
        return 'التطبيق';
      case CognitiveLevel.analyzing:
        return 'التحليل';
      case CognitiveLevel.evaluating:
        return 'التقييم';
      case CognitiveLevel.creating:
        return 'التركيب/الإبداع';
    }
  }
}
