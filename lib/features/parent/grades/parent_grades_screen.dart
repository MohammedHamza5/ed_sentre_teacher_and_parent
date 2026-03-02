import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../provider/parent_provider.dart';
import '../../../shared/models/models.dart';

class ParentGradesScreen extends StatefulWidget {
  const ParentGradesScreen({super.key});

  @override
  State<ParentGradesScreen> createState() => _ParentGradesScreenState();
}

class _ParentGradesScreenState extends State<ParentGradesScreen> {
  bool _isLoading = true;
  List<StudentGradeView> _grades = [];

  // Premium colors
  static const _gradientStart = Color(0xFFFF9500);
  static const _gradientEnd = Color(0xFFFFCC00);
  static const _excellentColor = Color(0xFF34C759);
  static const _goodColor = Color(0xFF007AFF);
  static const _averageColor = Color(0xFFFF9500);
  static const _poorColor = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final parentProvider = context.read<ParentProvider>();
    if (parentProvider.selectedChild != null &&
        parentProvider.selectedCenter != null) {
      final grades = await parentProvider.getChildGrades();
      if (mounted) {
        setState(() {
          _grades = grades;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 85) return _excellentColor;
    if (percentage >= 70) return _goodColor;
    if (percentage >= 50) return _averageColor;
    return _poorColor;
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = _grades.fold<double>(0, (sum, g) => sum + g.score);
    final totalMax = _grades.fold<double>(0, (sum, g) => sum + g.maxScore);
    final average = totalMax > 0 ? (totalScore / totalMax * 100) : 0.0;

    return Scaffold(
      body: _isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, _gradientEnd],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : CustomScrollView(
              slivers: [
                // Premium Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_gradientStart, _gradientEnd],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
                        child: Column(
                          children: [
                            // Title (centered, no back button)
                            Text(
                              'الدرجات والنتائج',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Average Display
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 48.sp,
                                  ),
                                  SizedBox(width: 20.w),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${average.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 42.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'المعدل العام',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().scale(delay: 200.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Grades List
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'جميع الدرجات',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),

                if (_grades.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.all(16.w),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'لا توجد درجات مسجلة لابنك',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildGradeCard(_grades[index], index),
                        childCount: _grades.length,
                      ),
                    ),
                  ),

                SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
              ],
            ),
    );
  }

  Widget _buildGradeCard(StudentGradeView grade, int index) {
    final score = grade.score;
    final maxScore = grade.maxScore;
    final percentage = grade.percentage;
    final color = _getGradeColor(percentage);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.courseName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      grade.examType,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${score.toStringAsFixed(0)} / ${maxScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Stack(
              children: [
                Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    height: 10.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                _getGradeLabel(percentage),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
  }

  String _getGradeLabel(double percentage) {
    if (percentage >= 90) return 'ممتاز';
    if (percentage >= 80) return 'جيد جداً';
    if (percentage >= 70) return 'جيد';
    if (percentage >= 60) return 'مقبول';
    return 'يحتاج تحسين';
  }
}
