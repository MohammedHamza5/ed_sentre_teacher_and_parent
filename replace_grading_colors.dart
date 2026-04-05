import 'dart:io';

void main() {
  final files = [
    'lib/features/teacher/assignments/submissions_screen.dart',
    'lib/features/teacher/assignments/grading_review_screen.dart',
    'lib/features/teacher/assignments/exam_answer_review_screen.dart',
  ];

  for (final path in files) {
    try {
      final file = File(path);
      if (!file.existsSync()) continue;
      
      var content = file.readAsStringSync();
      
      // Backgrounds
      content = content.replaceAll('AppColors.darkBackground', 'AppColors.forestDeep');
      content = content.replaceAll('AppColors.darkCard', 'AppColors.darkSurface');
      content = content.replaceAll('AppColors.darkInput', 'AppColors.darkSurface');
      
      // Borders
      content = content.replaceAll('AppColors.darkBorder', 'AppColors.glassBorderHighlight');
      
      // Text
      content = content.replaceAll('AppColors.textOnDark', 'AppColors.textDisplay');
      content = content.replaceAll('AppColors.textOnDarkSecondary', 'AppColors.textDisplay.withValues(alpha: 0.7)');
      content = content.replaceAll('AppColors.textOnDarkHint', 'AppColors.textDisplay.withValues(alpha: 0.5)');
      
      // Primary -> Accent
      content = content.replaceAll('AppColors.primary', 'AppColors.accentVivid');
      content = content.replaceAll('AppColors.success', 'AppColors.emeraldGreen');
      content = content.replaceAll('AppColors.warning', 'AppColors.warmAmber');
      content = content.replaceAll('AppColors.error', 'AppColors.errorRed');

      file.writeAsStringSync(content);
      print('✅ Updated \$path');
    } catch (e) {
      print('❌ Failed \$path: \$e');
    }
  }
}
