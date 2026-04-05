import 'dart:io';

void main() async {
  final dir = Directory('lib');
  int replacedCount = 0;
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      if (content.contains('withOpacity(')) {
        final newContent = content.replaceAllMapped(
          RegExp(r'\.withOpacity\((.*?)\)'), 
          (match) => '.withValues(alpha: ${match.group(1)})'
        );
        if (newContent != content) {
          await entity.writeAsString(newContent);
          replacedCount++;
          print('Updated ${entity.path}');
        }
      }
    }
  }
  print('Replaced in $replacedCount files.');
}
