import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final dartFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart'));

  int totalFixed = 0;

  for (final file in dartFiles) {
    var content = await file.readAsString();
    final original = content;

    content = _fixGeniusTextFieldParams(content);
    content = _fixGeniusButtonParams(content);
    content = _fixGlassCardImport(content);

    // GlassCard backgroundColor: -> color:
    content = content.replaceAll('backgroundColor:', 'color:');

    // Fix heroGlow type: Color -> List<BoxShadow>
    if (file.path.contains('genius_button.dart')) {
      content = content.replaceAll(
        'boxShadow: _isHovered ? AppColors.heroGlow : null,',
        'boxShadow: _isHovered ? [const BoxShadow(color: AppColors.heroGlow, blurRadius: 20, spreadRadius: 2)] : null,',
      );
    }

    if (content != original) {
      await file.writeAsString(content);
      totalFixed++;
      print('Fixed: ${file.path.split(Platform.pathSeparator).last}');
    }
  }

  print('');
  print('Fixed $totalFixed files');
}

String _fixGeniusTextFieldParams(String content) {
  final buffer = StringBuffer();
  int i = 0;
  while (i < content.length) {
    final geniusStart = content.indexOf('GeniusTextField(', i);
    if (geniusStart == -1) {
      buffer.write(content.substring(i));
      break;
    }
    buffer.write(content.substring(i, geniusStart));
    final blockEnd = _findMatchingParen(content, geniusStart + 'GeniusTextField'.length);
    if (blockEnd == -1) {
      buffer.write(content.substring(geniusStart));
      break;
    }
    var block = content.substring(geniusStart, blockEnd + 1);
    block = _fixTextFieldBlock(block);
    buffer.write(block);
    i = blockEnd + 1;
  }
  return buffer.toString();
}

String _fixTextFieldBlock(String block) {
  block = block.replaceAll(RegExp(r'\bhintText:\s*'), 'hint: ');
  block = block.replaceAll(RegExp(r',?\s*fillColor:\s*[^,\n)]+'), '');
  block = block.replaceAll(RegExp(r',?\s*hasBorder:\s*(true|false)'), '');
  return block;
}

String _fixGeniusButtonParams(String content) {
  final buffer = StringBuffer();
  int i = 0;
  while (i < content.length) {
    final btnStart = content.indexOf('GeniusButton(', i);
    if (btnStart == -1) {
      buffer.write(content.substring(i));
      break;
    }
    buffer.write(content.substring(i, btnStart));
    final blockEnd = _findMatchingParen(content, btnStart + 'GeniusButton'.length);
    if (blockEnd == -1) {
      buffer.write(content.substring(btnStart));
      break;
    }
    var block = content.substring(btnStart, blockEnd + 1);
    block = _fixButtonBlock(block);
    buffer.write(block);
    i = blockEnd + 1;
  }
  return buffer.toString();
}

String _fixButtonBlock(String block) {
  // Replace bare `text:` named param with `label:`
  block = block.replaceAll(RegExp(r'\btext:\s*'), 'label: ');
  block = block.replaceAll('isProviderLoading:', 'isLoading:');
  block = block.replaceAll(RegExp(r',?\s*isGlass:\s*true'), ', variant: GeniusButtonVariant.glass');
  block = block.replaceAll(RegExp(r',?\s*isGlass:\s*false'), '');
  block = block.replaceAll(RegExp(r',?\s*isDisabled:\s*(true|false|\w+)'), '');
  return block;
}

String _fixGlassCardImport(String content) {
  if (content.contains('premium_widgets.dart') && content.contains('glass_card.dart')) {
    // hide GlassCard from premium_widgets to resolve ambiguity
    content = content.replaceAllMapped(
      RegExp("import '([^']*premium_widgets\\.dart)';"),
      (m) => "import '${m[1]}' hide GlassCard;",
    );
  }
  return content;
}

int _findMatchingParen(String content, int openParenIndex) {
  int depth = 0;
  for (int i = openParenIndex; i < content.length; i++) {
    if (content[i] == '(') {
      depth++;
    } else if (content[i] == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}
