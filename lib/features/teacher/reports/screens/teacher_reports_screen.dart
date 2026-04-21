import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/providers/center_provider.dart';
import '../../provider/teacher_provider.dart';
import '../../../../shared/data/supabase_repository.dart';

import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/staggered_list_animator.dart';
import '../../../../shared/widgets/premium_widgets.dart' hide GlassCard;

/// 🟢 Teacher Reports & Analytics Screen - Glassmorphism 2.0 Overhaul
class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _overviewStats = {};
  List<Map<String, dynamic>> _attendanceTrends = [];
  List<Map<String, dynamic>> _assignmentTrends = [];
  List<Map<String, dynamic>> _studentsPerformance = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<SupabaseRepository>();
      final centerProvider = context.read<CenterProvider>();
      final teacherProvider = context.read<TeacherProvider>();
      final centerId = centerProvider.currentCenterId;

      var teacherId = teacherProvider.teacherId;
      if (teacherId == null && teacherProvider.teacherProfile == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        teacherId = teacherProvider.teacherId;
      }

      if (centerId == null) throw Exception('لم يتم تحديد السنتر');

      final stats = await repository.getTeacherOverviewStats(
        centerId,
        teacherId: teacherId,
      );
      final attendance = await repository.getTeacherAttendanceTrends(
        centerId,
        teacherId: teacherId,
      );
      final assignments = await repository.getTeacherAssignmentTrends(
        centerId,
        teacherId: teacherId,
      );
      final performance = await repository.getStudentsPerformance(
        centerId: centerId,
        teacherId: teacherId,
      );

      if (mounted) {
        setState(() {
          _overviewStats = stats;
          _attendanceTrends = attendance;
          _assignmentTrends = assignments;
          _studentsPerformance = performance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'لوحة المؤشرات',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        backgroundColor: AppColors.forestDeep.withValues(alpha: 0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDisplay),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.accentVivid),
            onPressed: _loadData,
          ),
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? _buildLoader()
            : _error != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadData,
                backgroundColor: AppColors.accentVivid,
                color: AppColors.forestPrimary,
                child: StaggeredListAnimator(
                  isList: true,
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
                  children: [
                    _buildOverviewCards(),
                    SizedBox(height: 32.h),
                    _buildSectionTitle('اتجاهات الحضور (آخر 30 يوم)'),
                    SizedBox(height: 16.h),
                    _buildAttendanceChart(),
                    SizedBox(height: 32.h),
                    _buildSectionTitle('نشاط الواجبات'),
                    SizedBox(height: 16.h),
                    _buildAssignmentsChart(),
                    SizedBox(height: 32.h),
                    _buildSectionTitle('أفضل الطلاب أداءً'),
                    SizedBox(height: 16.h),
                    _buildTopStudents(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: ShimmerLoading(height: 120.h)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerLoading(height: 120.h)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerLoading(height: 120.h)),
            ],
          ),
          SizedBox(height: 32.h),
          ShimmerLoading(height: 200.h),
          SizedBox(height: 32.h),
          ShimmerLoading(height: 200.h),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64.sp,
            color: AppColors.errorRed,
          ),
          SizedBox(height: 16.h),
          Text(
            _error ?? 'حدث خطأ غير معروف',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.forestDeep,
            ),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(
                color: AppColors.forestDeep,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentVivid,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: AppColors.accentVivid,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildOverviewCards() {
    final teacherProvider = context.watch<TeacherProvider>();

    final totalStudents = teacherProvider.statsTotalStudents > 0
        ? teacherProvider.statsTotalStudents
        : (_overviewStats['total_students'] ?? 0);
    final attendanceRate = teacherProvider.statsAttendanceRate > 0
        ? teacherProvider.statsAttendanceRate
        : (_overviewStats['attendance_rate'] ?? 0);
    final totalAssignments = _overviewStats['total_assignments'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'الطلاب',
            '$totalStudents',
            Icons.people_rounded,
            AppColors.infoPurple,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'الحضور',
            '$attendanceRate%',
            Icons.check_circle_rounded,
            AppColors.emeraldGreen,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'الواجبات',
            '$totalAssignments',
            Icons.assignment_rounded,
            AppColors.accentVivid,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      color: AppColors.forestPrimary.withValues(alpha: 0.4),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    if (_attendanceTrends.isEmpty) return _buildNoDataCard();

    List<FlSpot> spots = [];
    for (int i = 0; i < _attendanceTrends.length; i++) {
      final dayStats = _attendanceTrends[i];
      final present = dayStats['present'] as int? ?? 0;
      final total = dayStats['total'] as int? ?? 1;
      spots.add(
        FlSpot(i.toDouble(), total > 0 ? (present / total) * 100 : 0.0),
      );
    }

    return SizedBox(
      height: 220.h,
      child: GlassCard(
        color: AppColors.forestPrimary.withValues(alpha: 0.4),
        padding: EdgeInsets.all(16.w),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: AppColors.glassBorderHighlight, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 36,
                  showTitles: true,
                  interval: 25,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.emeraldGreen,
                barWidth: 4,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emeraldGreen.withValues(alpha: 0.3),
                      AppColors.emeraldGreen.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            minY: 0,
            maxY: 100,
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsChart() {
    if (_assignmentTrends.isEmpty) return _buildNoDataCard();

    return SizedBox(
      height: 220.h,
      child: GlassCard(
        color: AppColors.forestPrimary.withValues(alpha: 0.4),
        padding: EdgeInsets.all(16.w),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: AppColors.glassBorderHighlight, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 24,
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _assignmentTrends.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (e.value['count'] as int).toDouble(),
                    gradient: LinearGradient(
                      colors: [AppColors.accentVivid, AppColors.infoPurple],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return GlassCard(
      color: AppColors.darkSurface.withValues(alpha: 0.4),
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48.sp,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              'لا توجد بيانات كافية',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStudents() {
    final topStudents = _studentsPerformance.take(5).toList();
    if (topStudents.isEmpty) return _buildNoDataCard();

    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
      AppColors.infoPurple,
      AppColors.infoPurple,
    ];

    return Column(
      children: topStudents.asMap().entries.map((entry) {
        final index = entry.key;
        final student = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GlassCard(
            color: AppColors.forestPrimary.withValues(alpha: 0.4),
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: rankColors[index].withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rankColors[index].withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: rankColors[index],
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'حضور: ${student['attendance']}% • واجبات: ${student['assignments']}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${student['overall']}%',
                    style: TextStyle(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
