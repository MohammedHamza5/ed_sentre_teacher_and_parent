import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

/// 🟢 Subject Detail & Chapters Management Screen - Glassmorphism Update
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
  late Color _themeColor;

  @override
  void initState() {
    super.initState();
    _subject = widget.subjectData;
    _themeColor = _parseColor(_subject?['color']);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return Theme.of(context).colorScheme.primary;
    try {
      String hexStr = colorStr;
      if (hexStr.startsWith('#')) hexStr = "FF${hexStr.substring(1)}";
      return Color(int.parse(hexStr, radix: 16));
    } catch (_) {
      return Theme.of(context).colorScheme.primary;
    }
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
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
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
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
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
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  void _showAddChapterSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                            color: _themeColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            color: _themeColor,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'إضافة وحدة جديدة',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    GeniusTextField(
                      controller: titleCtrl,
                      label: 'عنوان الوحدة',
                      prefixIcon: Icons.title_rounded,
                    ),
                    SizedBox(height: 16.h),
                    GeniusTextField(
                      controller: descCtrl,
                      label: 'الوصف (اختياري)',
                      prefixIcon: Icons.description_rounded,
                    ),
                    SizedBox(height: 32.h),
                    GeniusButton(
                      label: 'إضافة الوحدة',
                      onPressed: () {
                        if (titleCtrl.text.isNotEmpty) {
                          Navigator.pop(context);
                          _addChapter(titleCtrl.text, descCtrl.text);
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
      },
    );
  }

  void _showAddLessonSheet(String chapterId, int lessonCount) {
    final titleCtrl = TextEditingController();
    final objCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '45');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                            color: _themeColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: _themeColor,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'إضافة درس جديد',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    GeniusTextField(
                      controller: titleCtrl,
                      label: 'عنوان الدرس',
                      prefixIcon: Icons.title_rounded,
                    ),
                    SizedBox(height: 16.h),
                    GeniusTextField(
                      controller: objCtrl,
                      label: 'الأهداف (اختياري)',
                      prefixIcon: Icons.flag_rounded,
                    ),
                    SizedBox(height: 16.h),
                    GeniusTextField(
                      controller: durationCtrl,
                      label: 'المدة (دقائق)',
                      prefixIcon: Icons.timer_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 32.h),
                    GeniusButton(
                      label: 'إضافة الدرس',
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
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
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
          _subject?['name'] ?? 'تفاصيل المادة',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDisplay),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChapterSheet,
        backgroundColor: _themeColor,
        elevation: 8,
        label: Text(
          'وحدة جديدة',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        icon: Icon(Icons.add_rounded, color: Colors.white),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
      body: _isLoading
          ? __buildLoadingState()
          : _chapters.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              backgroundColor: _themeColor,
              color: Theme.of(context).colorScheme.surface,
              child: StaggeredListAnimator(
                isList: true,
                delayBase: 100.ms,
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                children: _chapters
                    .asMap()
                    .entries
                    .map((entry) => _buildChapterCard(entry.key, entry.value))
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
          3,
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
        icon: Icons.topic_rounded,
        title: 'لا يوجد أبواب/وحدات بعد',
        subtitle: 'قم بإضافة الوحدة الأولى لهذه المادة للبدء برفع الدروس',
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildChapterCard(int chapterIndex, Map<String, dynamic> chapter) {
    final lessons = List<Map<String, dynamic>>.from(chapter['lessons'] ?? []);
    lessons.sort(
      (a, b) =>
          (a['order_num'] as int? ?? 0).compareTo(b['order_num'] as int? ?? 0),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: GlassCard(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            key: PageStorageKey('chapter_${chapter['id']}'),
            tilePadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            collapsedIconColor: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
            iconColor: _themeColor,
            leading: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: _themeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: _themeColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${chapterIndex + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _themeColor,
                  fontSize: 18.sp,
                ),
              ),
            ),
            title: Text(
              chapter['title'] ?? 'بدون عنوان',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              '${lessons.length} ${lessons.length == 1 ? 'درس' : 'دروس'}',
              style: TextStyle(
                color: _themeColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  children: [
                    ...lessons.asMap().entries.map((lessonEntry) {
                      final lesson = lessonEntry.value;
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 4.h,
                        ),
                        leading: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: _themeColor,
                            size: 20.sp,
                          ),
                        ),
                        title: Text(
                          lesson['title'] ?? 'درس',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: lesson['duration_mins'] != null
                            ? Text(
                                '${lesson['duration_mins']} دقيقة',
                                style: TextStyle(
                                  color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                                  fontSize: 12.sp,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                            size: 22.sp,
                          ),
                          onPressed: () {
                            // delete logic here
                          },
                        ),
                      );
                    }),
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 28.w,
                        vertical: 8.h,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: _themeColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_rounded, color: _themeColor),
                      ),
                      title: Text(
                        'إضافة درس جديد',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      onTap: () =>
                          _showAddLessonSheet(chapter['id'], lessons.length),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
