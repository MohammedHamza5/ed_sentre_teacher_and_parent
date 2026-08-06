import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../provider/parent_provider.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../../shared/widgets/premium_widgets.dart' show EmptyState;

class ParentCurriculumScreen extends StatefulWidget {
  const ParentCurriculumScreen({super.key});

  @override
  State<ParentCurriculumScreen> createState() => _ParentCurriculumScreenState();
}

class _ParentCurriculumScreenState extends State<ParentCurriculumScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _progressData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProgress());
  }

  Future<void> _loadProgress() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final parentProvider = context.read<ParentProvider>();
      final centerId = parentProvider.selectedCenterId;
      final studentId = parentProvider.selectedChildId;

      if (centerId == null || studentId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _progressData = [];
          });
        }
        return;
      }

      final repo = context.read<SupabaseRepository>();
      final progress = await repo.getLessonProgressForStudent(
        studentId: studentId,
        centerId: centerId,
      );

      if (mounted) {
        setState(() {
          _progressData = progress;
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

  Map<String, List<Map<String, dynamic>>> _groupProgressBySubject() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in _progressData) {
      final lesson = item['lessons'];
      if (lesson == null) continue;
      final subject = lesson['subjects'];
      if (subject == null) continue;

      final subjectName = subject['name'] as String? ?? 'مادة غير معروفة';
      if (!grouped.containsKey(subjectName)) {
        grouped[subjectName] = [];
      }
      grouped[subjectName]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final parentProvider = context.watch<ParentProvider>();
    final selectedChild = parentProvider.selectedChild;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'منهجي - ${selectedChild?.fullName?.split(' ').first ?? ''}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Padding(
              padding: EdgeInsets.all(20.w),
              child: const CardShimmerSkeleton(itemCount: 4),
            )
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: _progressData.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.auto_stories_rounded,
                        title: 'لا يوجد تقدم بعد',
                        subtitle: 'لم يكتمل أي درس من المنهج حتى الآن.',
                      ),
                    ).animate().fadeIn(duration: 400.ms)
                  : ListView(
                      padding: EdgeInsets.all(20.w),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: _buildSubjectCards(),
                    ),
            ),
    );
  }

  List<Widget> _buildSubjectCards() {
    final grouped = _groupProgressBySubject();
    int index = 0;
    
    return grouped.entries.map((entry) {
      final subjectName = entry.key;
      final lessons = entry.value;
      final delay = Duration(milliseconds: 100 * index++);

      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: GlassCard(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      subjectName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${lessons.length} دروس مكتملة',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              ...lessons.map((progressItem) {
                final lesson = progressItem['lessons'] ?? {};
                final completedAt = progressItem['completed_at'] != null 
                    ? DateTime.parse(progressItem['completed_at']).toLocal() 
                    : null;
                final dateStr = completedAt != null 
                    ? '${completedAt.day}/${completedAt.month}/${completedAt.year}' 
                    : '';

                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          lesson['title'] ?? 'درس',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11.sp,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ).animate(delay: delay).fadeIn().slideY(begin: 0.1, curve: Curves.easeOutQuad),
      );
    }).toList();
  }
}
