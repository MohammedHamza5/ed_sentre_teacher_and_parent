/// Log Viewer Screen - شاشة عرض السجلات
/// للمطورين لعرض كل ما يحدث في التطبيق
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/app_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  LogLevel? _filterLevel;
  String? _filterTag;
  String _searchQuery = '';
  bool _autoScroll = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = AppLogger.instance.getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 سجل التطبيق'),
        actions: [
          // تصفية حسب المستوى
          PopupMenuButton<LogLevel?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (level) {
              setState(() => _filterLevel = level);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('الكل')),
              ...LogLevel.values.map((level) {
                return PopupMenuItem(
                  value: level,
                  child: Row(
                    children: [
                      Text(level.emoji),
                      const SizedBox(width: 8),
                      Text(level.label),
                    ],
                  ),
                );
              }),
            ],
          ),

          // مشاركة السجل
          IconButton(icon: const Icon(Icons.share), onPressed: _shareLogs),

          // مسح السجلات
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'إجمالي: ${stats['total_logs']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...(stats['by_level'] as Map).entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ],
            ),
          ),

          // بحث
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث في السجلات...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // قائمة السجلات
          Expanded(
            child: StreamBuilder<LogEntry>(
              stream: AppLogger.instance.logStream,
              builder: (context, snapshot) {
                // تحديث القائمة
                final logs = _filterLogs(AppLogger.instance.logs);

                if (logs.isEmpty) {
                  return const Center(child: Text('لا توجد سجلات'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[logs.length - 1 - index];
                    return _buildLogItem(log);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // زر التبديل التلقائي
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          setState(() => _autoScroll = !_autoScroll);
        },
        child: Icon(_autoScroll ? Icons.pause : Icons.play_arrow),
      ),
    );
  }

  /// تصفية السجلات
  List<LogEntry> _filterLogs(List<LogEntry> logs) {
    return logs.where((log) {
      if (_filterLevel != null && log.level != _filterLevel) return false;
      if (_filterTag != null && log.tag != _filterTag) return false;
      if (_searchQuery.isNotEmpty &&
          !log.message.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  /// بناء عنصر السجل
  Widget _buildLogItem(LogEntry log) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Text(log.level.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          log.message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            if (log.tag != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(log.tag!, style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _formatTime(log.timestamp),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // البيانات
                if (log.data != null) ...[
                  Text(
                    '📊 البيانات:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.data.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // الخطأ
                if (log.error != null) ...[
                  Text(
                    '⚠️ الخطأ:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.error.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Stack Trace
                if (log.stackTrace != null) ...[
                  Text(
                    '📍 Stack Trace:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.stackTrace.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // نسخ
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copyLog(log),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('نسخ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق الوقت
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }

  /// نسخ السجل
  void _copyLog(LogEntry log) {
    Clipboard.setData(ClipboardData(text: log.toFileString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }

  /// مشاركة السجلات
  void _shareLogs() async {
    final logs = AppLogger.instance.exportLogsAsText();
    await Share.share(logs, subject: 'سجلات التطبيق');
  }

  /// مسح السجلات
  void _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح السجلات'),
        content: const Text('هل تريد مسح كل السجلات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      AppLogger.instance.clearLogs();
      setState(() {});
    }
  }
}
