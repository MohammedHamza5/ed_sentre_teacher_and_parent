import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/center_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/widgets/premium_widgets.dart';

class CurriculumManagementScreen extends StatefulWidget {
  const CurriculumManagementScreen({super.key});

  @override
  State<CurriculumManagementScreen> createState() => _CurriculumManagementScreenState();
}

class _CurriculumManagementScreenState extends State<CurriculumManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjects();
    });
  }

  Future<void> _loadSubjects() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final centerId = context.read<CenterProvider>().currentCenterId;
      if (centerId == null) {
        setState(() {
          _isLoading = false;
          _subjects = [];
        });
        return;
      }

      final repo = context.read<SupabaseRepository>();
      final subjects = await repo.getCurriculumSubjects(centerId);
      
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المنهج: $e')),
        );
      }
    }
  }

  void _showAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: '1');
    final semCtrl = TextEditingController(text: '1');
    final colorCtrl = TextEditingController(text: '#4F46E5');
    final iconCtrl = TextEditingController(text: '📚');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مادة جديدة', style: TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المادة (مثال: رياضيات)'),
              ),
              TextField(
                controller: gradeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الصف الدراسي (1-12)'),
              ),
              TextField(
                controller: semCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الفصل الدراسي (1 أو 2)'),
              ),
              TextField(
                controller: iconCtrl,
                decoration: const InputDecoration(labelText: 'أيقونة (Emoji)'),
              ),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'لون البطاقة (HEX)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final centerId = context.read<CenterProvider>().currentCenterId;
              if (centerId == null || nameCtrl.text.isEmpty) return;
              
              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                final repo = context.read<SupabaseRepository>();
                await repo.addSubject(
                  centerId: centerId,
                  name: nameCtrl.text,
                  gradeLevel: gradeCtrl.text,
                  semester: int.tryParse(semCtrl.text),
                  icon: iconCtrl.text,
                  color: colorCtrl.text,
                );
                _loadSubjects();
              } catch (e) {
                if (context.mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في الإضافة: $e')),
                  );
                }
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
          'إدارة المناهج',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'لا يوجد مواد بعد',
                  subtitle: 'قم بإضافة مادة جديدة للبدء في بناء المنهج',
                )
              : RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      // Parse hex color safely
                      Color cardColor = Theme.of(context).colorScheme.primary;
                      try {
                        String hexString = subject['color'] ?? '#4F46E5';
                        if (hexString.startsWith('#')) {
                          hexString = "FF${hexString.substring(1)}";
                        }
                        cardColor = Color(int.parse(hexString, radix: 16));
                      } catch (_) {}

                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () {
                            context.go(
                              '/teacher/curriculum/${subject['id']}',
                              extra: subject,
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Row(
                              children: [
                                Container(
                                  width: 50.w,
                                  height: 50.w,
                                  decoration: BoxDecoration(
                                    color: cardColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    subject['icon'] ?? '📚',
                                    style: TextStyle(fontSize: 24.sp),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject['name'] ?? 'بدون اسم',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'الصف: ${subject['grade_level'] ?? '-'} | الفصل: ${subject['semester'] ?? '-'}',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16.sp,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
