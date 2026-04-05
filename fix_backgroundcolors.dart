import 'dart:io';

/// Targeted revert: changes color: back to backgroundColor: in specific Flutter widget contexts.
/// Uses a simple approach: find `WidgetName(` blocks and within them, if color: appears
/// as a DIRECT parameter (not nested), rename it back.
void main() async {
  final dir = Directory('lib');
  final dartFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart'));

  int totalFixed = 0;
  int totalReplacements = 0;

  // Widgets that use backgroundColor: instead of color: as their main color param
  const bgColorWidgets = [
    'Scaffold(',
    'SliverAppBar(',
    'AppBar(',
    'LinearProgressIndicator(',
    'CircularProgressIndicator(',
    'RefreshIndicator(',
    'TabBar(',
    'BottomNavigationBar(',
    'NavigationBar(',
    'NavigationRail(',
    'DrawerThemeData(',
    'Drawer(',
    'SnackBarThemeData(',
    'SnackBar(',
    'AlertDialog(',
    'Dialog(',
    'Chip(',
    'FilterChip(',
    'ActionChip(',
    'ChoiceChip(',
    'InputDecoration(',
    'CheckboxListTile(',
    'SwitchListTile(',
    'RadioListTile(',
    'FloatingActionButton(',
    'PopupMenuButton(',
    'PopupMenuThemeData(',
    'TimePicker(',
    'DatePicker(',
    'ButtonStyle(',
    'ElevatedButton.styleFrom(',
    'TextButton.styleFrom(',
    'OutlinedButton.styleFrom(',
    'FilledButton.styleFrom(',
    'FilledButton(',
    'ElevatedButton(',
  ];

  for (final file in dartFiles) {
    var content = await file.readAsString();
    final original = content;
    int fileReplacements = 0;

    for (final widget in bgColorWidgets) {
      int i = 0;
      while (true) {
        final widgetIdx = content.indexOf(widget, i);
        if (widgetIdx == -1) break;

        // Find the ( position
        final parenStart = widgetIdx + widget.length - 1;
        final parenEnd = _findMatchingParen(content, parenStart);
        if (parenEnd == -1) {
          i = widgetIdx + 1;
          break;
        }

        // Extract the block
        final before = content.substring(0, widgetIdx);
        var block = content.substring(widgetIdx, parenEnd + 1);
        final after = content.substring(parenEnd + 1);

        // Find direct-level `color:` params (depth 1 = direct params of this widget)
        final fixed = _revertColorInBlock(block, widget.length);
        if (fixed != block) {
          fileReplacements++;
          content = before + fixed + after;
        }

        // Move past this widget block
        i = widgetIdx + fixed.length;
      }
    }

    if (content != original) {
      await file.writeAsString(content);
      totalFixed++;
      totalReplacements += fileReplacements;
      print(
        'Fixed $fileReplacements replacements in ${file.path.split(Platform.pathSeparator).last}',
      );
    }
  }

  print('');
  print('Total: $totalReplacements replacements across $totalFixed files');
}

/// Within a widget block, revert `color:` to `backgroundColor:` only at depth 1
/// (direct named parameters, not inside nested widgets).
String _revertColorInBlock(String block, int widgetNameLen) {
  // We parse character by character tracking paren/bracket depth
  final result = StringBuffer();
  int depth = 0;
  int i = 0;

  while (i < block.length) {
    final ch = block[i];

    if (ch == '(' || ch == '[' || ch == '{') {
      depth++;
      result.write(ch);
      i++;
      continue;
    }
    if (ch == ')' || ch == ']' || ch == '}') {
      depth--;
      result.write(ch);
      i++;
      continue;
    }

    // At depth 1 = direct params of the target widget
    if (depth == 1) {
      // Check for `color:` (with optional leading whitespace already in buffer)
      if (block.startsWith('color:', i)) {
        result.write('backgroundColor:');
        i += 'color:'.length;
        continue;
      }
    }

    result.write(ch);
    i++;
  }
  return result.toString();
}

int _findMatchingParen(String content, int openIdx) {
  int depth = 0;
  for (int i = openIdx; i < content.length; i++) {
    if (content[i] == '(' || content[i] == '[' || content[i] == '{') {
      depth++;
    } else if (content[i] == ')' || content[i] == ']' || content[i] == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}
