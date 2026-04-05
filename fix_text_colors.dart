import 'dart:io';

void main() {
  final files = [
    'lib/features/teacher/assignments/submissions_screen.dart',
    'lib/features/teacher/assignments/grading_review_screen.dart',
    'lib/features/teacher/assignments/exam_answer_review_screen.dart',
    'lib/features/teacher/assignments/create_assignment_screen.dart',
    'lib/features/teacher/assignments/teacher_assignments_screen.dart',
  ];

  for (final path in files) {
    try {
      final file = File(path);
      if (!file.existsSync()) continue;
      
      var content = file.readAsStringSync();
      
      content = content.replaceAll('AppColors.textDisplayHint', 'AppColors.textMuted');
      content = content.replaceAll('AppColors.textDisplaySecondary', 'AppColors.textMuted');

      file.writeAsStringSync(content);
      print('✅ Updated \$path');
    } catch (e) {
      print('❌ Failed \$path: \$e');
    }
  }
}
