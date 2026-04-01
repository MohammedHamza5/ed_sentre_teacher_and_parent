import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/center_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/widgets/premium_widgets.dart';

class SubjectDetailManagementScreen extends StatefulWidget {
  final String subjectId;
  final Map<String, dynamic>? subjectData;

  const SubjectDetailManagementScreen({
    super.key,
    required this.subjectId,
    this.subjectData,
  });

  @override
  State<SubjectDetailManagementScreen> createState() =>
      _SubjectDetailManagementScreenState();
}

class _SubjectDetailManagementScreenState
    extends State<SubjectDetailManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chapters = [];
  Map<String, dynamic>? _subject;

  @override
  void initState() {
    super.initState();
    _subject = widget.subjectData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final repo = context.read<SupabaseRepository>();
      final chapters = await repo.getChaptersWithLessons(widget.subjectId);
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _addChapter(String title, String desc) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<SupabaseRepository>();
      await repo.addChapter(
        subjectId: widget.subjectId,
        title: title,
        description: desc.isEmpty ? null : desc,
        orderNum: _chapters.length,
      );
      await _loadData();
    } catch (e) {
      if (context.mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _addLesson(
    String chapterId,
    String title,
    String obj,
    int mins,
    int order,
  ) async {
    final centerId = context.read<CenterProvider>().currentCenterId;
    if (centerId == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = context.read<SupabaseRepository>();
      await repo.addLesson(
        centerId: centerId,
        subjectId: widget.subjectId,
        chapterId: chapterId,
        title: title,
        objectives: obj.isEmpty ? null : obj,
        durationMins: mins,
        orderNum: order,
      );
      await _loadData();
    } catch (e) {
      if (context.mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  void _showAddChapterDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة باب / وحدة', style: TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                _addChapter(titleCtrl.text, descCtrl.text);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(String chapterId, int lessonCount) {
    final titleCtrl = TextEditingController();
    final objCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '45');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة درس جديد', style: TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            TextField(
              controller: objCtrl,
              decoration: const InputDecoration(labelText: 'الأهداف (اختياري)'),
            ),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المدة (دقائق)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                _addLesson(
                  chapterId,
                  titleCtrl.text,
                  objCtrl.text,
                  int.tryParse(durationCtrl.text) ?? 45,
                  lessonCount + 1,
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _subject?['name'] ?? 'تفاصيل المادة',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChapterDialog,
        child: const Icon(Icons.add_box_rounded),
        tooltip: 'إضافة وحدة/باب',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chapters.isEmpty
              ? EmptyState(
                  icon: Icons.topic_rounded,
                  title: 'لا يوجد أبواب بعد',
                  subtitle: 'قم بإضافة الوحدة الأولى لهذه المادة',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _chapters.length,
                  itemBuilder: (context, chapterIndex) {
                    final chapter = _chapters[chapterIndex];
                    final lessons = List<Map<String, dynamic>>.from(
                      chapter['lessons'] ?? [],
                    );
                    lessons.sort((a, b) =>
                        (a['order_num'] as int? ?? 0)
                            .compareTo(b['order_num'] as int? ?? 0));

                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          child: Text('${chapterIndex + 1}'),
                        ),
                        title: Text(
                          chapter['title'],
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        subtitle: Text(
                          '${lessons.length} درس',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        children: [
                          ...lessons.map((lesson) {
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 32.w,
                                vertical: 4.h,
                              ),
                              leading: const Icon(Icons.play_circle_outline),
                              title: Text(
                                lesson['title'],
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              subtitle: lesson['duration_mins'] != null
                                  ? Text('${lesson['duration_mins']} دقيقة')
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red.shade300,
                                onPressed: () {
                                  // delete logic goes here
                                },
                              ),
                            );
                          }),
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 32.w),
                            leading: const Icon(Icons.add, color: Colors.green),
                            title: const Text(
                              'إضافة درس جديد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.green,
                              ),
                            ),
                            onTap: () => _showAddLessonDialog(
                              chapter['id'],
                              lessons.length,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
