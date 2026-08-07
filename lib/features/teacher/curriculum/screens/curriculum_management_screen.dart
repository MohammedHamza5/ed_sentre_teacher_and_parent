import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/genius_button.dart';
import '../../../../core/widgets/genius/genius_text_field.dart';
import '../../../../core/widgets/genius/staggered_list_animator.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../../shared/widgets/premium_widgets.dart' show EmptyState;

/// 🟢 Curriculum Management Screen - Radical Glassmorphism Overhaul
class CurriculumManagementScreen extends StatefulWidget {
  const CurriculumManagementScreen({super.key});

  @override
  State<CurriculumManagementScreen> createState() =>
      _CurriculumManagementScreenState();
}

class _CurriculumManagementScreenState
    extends State<CurriculumManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];
  // Tracks official books found for the subject name typed in the add-sheet
  List<Map<String, dynamic>> _officialBooksForNewSubject = [];
  bool _isImporting = false;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المنهج: $e')));
      }
    }
  }

  /// Checks the official curriculum_books table for books matching [name].
  Future<void> _checkOfficialBooksForSubject(String name, StateSetter setSheetState) async {
    if (name.trim().isEmpty) {
      setSheetState(() => _officialBooksForNewSubject = []);
      return;
    }
    final repo = context.read<SupabaseRepository>();
    final books = await repo.getAvailableBooksForSubject(name.trim());
    setSheetState(() => _officialBooksForNewSubject = books);
  }

  /// Imports an official curriculum book into this center's subjects/chapters/lessons.
  Future<void> _importOfficialCurriculum({
    required Map<String, dynamic> book,
    required String centerId,
    required String icon,
    required String color,
    required StateSetter setSheetState,
  }) async {
    setSheetState(() => _isImporting = true);
    try {
      final repo = context.read<SupabaseRepository>();
      final subjectId = await repo.importCurriculumToCenter(
        centerId: centerId,
        subjectName: book['subject_name'] as String? ?? '',
        gradeLevel: book['grade_level'] as String? ?? '1',
        semester: book['semester'] as int? ?? 1,
        icon: icon,
        color: color,
      );
      if (!mounted) return;
      if (subjectId != null) {
        Navigator.pop(context);
        _loadSubjects();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ تم استيراد المنهج الرسمي بنجاح!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على منهج رسمي لهذه المادة والمرحلة')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاستيراد: $e')));
    } finally {
      if (mounted) setSheetState(() => _isImporting = false);
    }
  }

  void _showAddSubjectSheet() {
    final nameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: '1');
    final semCtrl = TextEditingController(text: '1');
    final colorCtrl = TextEditingController(text: '#10B981'); // Emerald
    final iconCtrl = TextEditingController(text: '📚');
    
    // Reset state before showing sheet
    _officialBooksForNewSubject = [];
    _isImporting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Add listener here to avoid multiple listeners
            // In a real app, use a proper debounce package or Timer.
            // For simplicity here, we'll just check on change with a small delay or directly.
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                      border: Border(
                        top: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
                      ),
                    ),
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'إضافة مادة جديدة',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        GeniusTextField(
                          controller: nameCtrl,
                          label: 'اسم المادة (مثال: رياضيات)',
                          prefixIcon: Icons.edit_rounded,
                          onChanged: (val) {
                            // Simple debounce-like behavior could be added here
                            _checkOfficialBooksForSubject(val, setSheetState);
                          },
                        ),
                        SizedBox(height: 16.h),
                        
                        // 🤖 AI OFFICIAL CURRICULUM BANNER
                        if (_officialBooksForNewSubject.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        'تم العثور على مناهج رسمية لهذه المادة!',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                ..._officialBooksForNewSubject.map((book) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: ElevatedButton.icon(
                                      onPressed: _isImporting ? null : () {
                                        final centerId = context.read<CenterProvider>().currentCenterId;
                                        if (centerId != null) {
                                          _importOfficialCurriculum(
                                            book: book,
                                            centerId: centerId,
                                            icon: iconCtrl.text,
                                            color: colorCtrl.text,
                                            setSheetState: setSheetState,
                                          );
                                        }
                                      },
                                      icon: _isImporting 
                                          ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.download_rounded),
                                      label: Text('استيراد: ${book['book_title']} (${book['grade_label']})'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: Size(double.infinity, 45.h),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Center(
                            child: Text(
                              'أو إكمال الإضافة يدوياً:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: GeniusTextField(
                                controller: gradeCtrl,
                                label: 'الصف (1-12)',
                                prefixIcon: Icons.school_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: GeniusTextField(
                                controller: semCtrl,
                                label: 'الفصل (1-2)',
                                prefixIcon: Icons.auto_awesome_motion_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: GeniusTextField(
                                controller: iconCtrl,
                                label: 'أيقونة (Emoji)',
                                prefixIcon: Icons.emoji_emotions_rounded,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: GeniusTextField(
                                controller: colorCtrl,
                                label: 'لون البطاقة (HEX)',
                                prefixIcon: Icons.color_lens_rounded,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        GeniusButton(
                          label: 'إضافة المادة (يدوياً)',
                          onPressed: () async {
                            final centerId = context
                                .read<CenterProvider>()
                                .currentCenterId;
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
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'المناهج التعليمية',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 8,
        label: Text(
          'مادة جديدة',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        icon: Icon(Icons.add_rounded, color: Theme.of(context).scaffoldBackgroundColor),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
      body: _isLoading
          ? __buildLoadingState()
          : _subjects.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadSubjects,
              backgroundColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(context).colorScheme.surface,
              child: StaggeredListAnimator(
                isList: true,
                delayBase: 100.ms,
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                children: _subjects
                    .map((subject) => _buildSubjectCard(subject))
                    .toList(),
              ),
            ),
    );
  }

  Widget __buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: const ShimmerListItem(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: EmptyState(
        icon: Icons.menu_book_rounded,
        title: 'لا يوجد مواد بعد',
        subtitle:
            'قم بإضافة المناهج الدراسية لطلابك لتبدأ في رفع المحتوى والملزمات',
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    Color cardAccent = Theme.of(context).colorScheme.primary;
    try {
      String hexString = subject['color'] ?? '#10B981';
      if (hexString.startsWith('#')) hexString = "FF${hexString.substring(1)}";
      cardAccent = Color(int.parse(hexString, radix: 16));
    } catch (_) {}

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: GlassCard(
        onTap: () =>
            context.go('/teacher/curriculum/${subject['id']}', extra: subject),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: cardAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: cardAccent.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                subject['icon'] ?? '📚',
                style: TextStyle(fontSize: 28.sp),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['name'] ?? 'بدون اسم',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      _buildChip(
                        'الصف ${subject['grade_level'] ?? '-'}',
                        Icons.school_rounded,
                        cardAccent,
                      ),
                      SizedBox(width: 8.w),
                      _buildChip(
                        'الترم ${subject['semester'] ?? '-'}',
                        Icons.auto_awesome_motion_rounded,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
