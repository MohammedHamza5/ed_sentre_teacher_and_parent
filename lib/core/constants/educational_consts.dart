class EducationalStages {
  // Preparatory Stage
  static const String prepFirst = 'الصف الأول الإعدادي';
  static const String prepSecond = 'الصف الثاني الإعدادي';
  static const String prepThird = 'الصف الثالث الإعدادي';

  // Secondary Stage
  static const String secFirst = 'الصف الأول الثانوي';
  static const String secSecond = 'الصف الثاني الثانوي';
  static const String secThird = 'الصف الثالث الثانوي';

  // All valid grades to be shown in dropdowns
  static const List<String> allGrades = [
    prepFirst,
    prepSecond,
    prepThird,
    secFirst,
    secSecond,
    secThird,
  ];

  // Helper lists if needed
  static const List<String> prepGrades = [prepFirst, prepSecond, prepThird];

  static const List<String> secGrades = [secFirst, secSecond, secThird];

  /// Helper method to convert full grade names to short codes (e.g., for Group generation)
  static String getShortName(String grade) {
    switch (grade) {
      case prepFirst:
        return '1إ';
      case prepSecond:
        return '2إ';
      case prepThird:
        return '3إ';
      case secFirst:
        return '1ث';
      case secSecond:
        return '2ث';
      case secThird:
        return '3ث';
      default:
        return grade; // Fallback to original if not found
    }
  }
}
