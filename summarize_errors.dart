import 'dart:io';

void main() async {
  final file = File('last_errors.txt');
  if (!await file.exists()) return;

  final lines = await file.readAsLines();
  final counts = <String, int>{};
  
  for (final line in lines) {
    if (line.startsWith('  error - ')) {
      // e.g. "  error - path/to/file.dart:line:col - Message - error_code"
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final code = parts.last.trim();
        final msg = parts[parts.length - 2].trim();
        final key = '$code: $msg';
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (final entry in sorted.take(20)) {
    print('${entry.value.toString().padLeft(4)} | ${entry.key}');
  }
}
