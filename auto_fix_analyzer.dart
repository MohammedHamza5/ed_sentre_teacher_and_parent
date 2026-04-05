import 'dart:io';

void main() async {
  final file = File('last_errors.txt');
  if (!await file.exists()) {
    print('No errors file found');
    return;
  }

  final lines = await file.readAsLines();

  // Group errors by file
  final fileErrors = <String, List<Map<String, dynamic>>>{};

  for (final line in lines) {
    if (line.startsWith('  error - ')) {
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final code = parts.last.trim();
        final msg = parts[parts.length - 2].trim();
        final pathRaw = parts[1].trim();

        // E.g. core\config\app_theme.dart:175:9
        final pathParts = pathRaw.split(':');
        if (pathParts.length >= 3) {
          final filePath = 'lib/${pathParts[0].replaceAll('\\', '/')}';
          final lineNum = int.tryParse(pathParts[1]) ?? 0;

          if (!fileErrors.containsKey(filePath)) {
            fileErrors[filePath] = [];
          }
          fileErrors[filePath]!.add({
            'line': lineNum,
            'code': code,
            'msg': msg,
          });
        }
      }
    }
  }

  int fixedCount = 0;

  for (final entry in fileErrors.entries) {
    final filePath = entry.key;
    final errors = entry.value;

    final targetFile = File(filePath);
    if (!await targetFile.exists()) continue;

    final fileLines = await targetFile.readAsLines();
    bool changed = false;

    // Process backwards to not mess up line numbers if we ever added/removed lines,
    // though here we just modify in-place
    errors.sort((a, b) => b['line'].compareTo(a['line']));

    for (final err in errors) {
      final lineIdx = err['line'] - 1;
      if (lineIdx < 0 || lineIdx >= fileLines.length) continue;

      String row = fileLines[lineIdx];

      if (err['code'] == 'undefined_named_parameter' &&
          row.contains('color:')) {
        // Safe to change color: back to backgroundColor: because compiler says color is wrong
        // Only do it if backgroundColor is not already there
        if (!row.contains('backgroundColor:')) {
          // Replace ONLY the literal 'color:' being used as parameter
          row = row.replaceFirst(RegExp(r'\bcolor:\s*'), 'backgroundColor: ');
        }
      } else if (err['code'] == 'duplicate_named_argument' &&
          row.contains('backgroundColor:')) {
        // It might be RefreshIndicator or CircularProgressIndicator.
        // Let's replace the first backgroundColor: with color: or valueColor:
        // For CircularProgressIndicator it usually had 'valueColor: AlwaysStoppedAnimation<Color>(color)'
        if (row.contains('value:')) {
          // likely circular progress
        } else {
          // generic duplicate. Let's just turn the first backgroundColor into color
          row = row.replaceFirst('backgroundColor:', 'color:');
        }
      }

      if (row != fileLines[lineIdx]) {
        fileLines[lineIdx] = row;
        changed = true;
        fixedCount++;
      }
    }

    if (changed) {
      await targetFile.writeAsString(fileLines.join('\n'));
      print('Fixed ${errors.length} issues in $filePath');
    }
  }

  print('Total fixed: $fixedCount. Try running dart analyze again.');
}
