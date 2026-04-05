import 'dart:io';

void main() {
  final file = File('lib/features/teacher/assignments/create_assignment_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    '(Theme.of(context).cardTheme.color ??\n            Theme.of(context).colorScheme.surface)',
    'AppColors.darkSurface',
  );
  content = content.replaceAll(
    '(Theme.of(context).cardTheme.color ??\n                  Theme.of(context).colorScheme.surface)',
    'AppColors.darkSurface',
  );
  content = content.replaceAll(
    'Theme.of(context).colorScheme.onSurface',
    'AppColors.textDisplay',
  );
  content = content.replaceAll(
    'Theme.of(context).colorScheme.outline',
    'AppColors.glassBorderHighlight',
  );
  content = content.replaceAll(
    'Theme.of(context).colorScheme.error',
    'AppColors.errorRed',
  );
  content = content.replaceAll(
    'Theme.of(context).scaffoldBackgroundColor',
    'AppColors.forestDeep',
  );
  file.writeAsStringSync(content);
  print('✅ Replaced theme usages in create_assignment_screen.dart');
}
