import 'dart:io';

void main() async {
  final file = File('lib/features/teacher/assignments/teacher_assignments_screen.dart');
  var content = await file.readAsString();

  content = content.replaceAll('GlassMorphismCard(', 'GlassCard(');
  content = content.replaceAll(RegExp(r'animationDelay:\s*\d+\s*\*\s*index,'), '');
  content = content.replaceAll('GradientButton(', 'GeniusButton(');

  content = content.replaceAll(RegExp(r'Theme\.of\(context\)\.cardTheme\.color \?\?[\s\n]*Theme\.of\(context\)\.colorScheme\.surface'), 'AppColors.darkSurface');
  content = content.replaceAll(RegExp(r'Theme\.of\(context\)\.colorScheme\.surface'), 'AppColors.darkSurface');
  content = content.replaceAllMapped(RegExp(r'Theme\.of\(context\)\.colorScheme\.onSurface\.withOpacity\((.*?)\)'), (match) => 'AppColors.textDisplay.withValues(alpha: ${match[1]})');
  content = content.replaceAll('Theme.of(context).colorScheme.onSurface', 'AppColors.textDisplay');
  content = content.replaceAllMapped(RegExp(r'Theme\.of\(context\)\.colorScheme\.outline\.withOpacity\((.*?)\)'), (match) => 'AppColors.glassBorderHighlight');
  content = content.replaceAllMapped(RegExp(r'Theme\.of\(context\)\.colorScheme\.primary\.withValues\(alpha: (.*?)\)'), (match) => 'AppColors.accentVivid.withValues(alpha: ${match[1]})');
  content = content.replaceAllMapped(RegExp(r'Theme\.of\(context\)\.colorScheme\.primary\.withOpacity\((.*?)\)'), (match) => 'AppColors.accentVivid.withValues(alpha: ${match[1]})');
  content = content.replaceAll('Theme.of(context).colorScheme.primary', 'AppColors.accentVivid');
  content = content.replaceAll('Theme.of(context).colorScheme.secondary', 'AppColors.accentVivid');
  content = content.replaceAllMapped(RegExp(r'Theme\.of\(context\)\.colorScheme\.error\.withOpacity\((.*?)\)'), (match) => 'AppColors.errorRed.withValues(alpha: ${match[1]})');
  content = content.replaceAll('Theme.of(context).colorScheme.error', 'AppColors.errorRed');

  content = content.replaceAllMapped(RegExp(r'\.withOpacity\((.*?)\)'), (match) => '.withValues(alpha: ${match[1]})');

  content = content.replaceAll('TextField(', 'GeniusTextField(');

  await file.writeAsString(content);
}
