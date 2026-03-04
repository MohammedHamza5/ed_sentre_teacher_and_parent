import '../../../shared/widgets/app_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// Removed AppColors import
import '../../../core/providers/center_provider.dart';
import '../provider/teacher_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../shared/widgets/premium_plus_widgets.dart';

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
    _loadData();
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

      if (centerId == null) {
        throw Exception('لم يتم تحديد السنتر');
      }

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
    } catch (e, stack) {
      debugPrint('📊 [ReportsScreen] ERROR: $e\n$stack');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 160.h,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                ),
                onPressed: () => context.go('/teacher'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(
                          Icons.analytics_outlined,
                          size: 160.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.06),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(
                                      Icons.analytics_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      size: 22.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'لوحة المؤشرات',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'تحليل شامل للأداء والحضور',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: _loadData,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: DrawerMenuButton(isTeacher: true),
                ),
              ],
            ),
          ];
        },
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.sp,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    GradientButton(
                      text: 'إعادة المحاولة',
                      icon: Icons.refresh,
                      onPressed: _loadData,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 100.h),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      _buildOverviewCards(),
                      SizedBox(height: 24.h),
                      _buildSectionTitle('اتجاهات الحضور (آخر 30 يوم)'),
                      SizedBox(height: 8.h),
                      _buildAttendanceChart(),
                      SizedBox(height: 24.h),
                      _buildSectionTitle('نشاط الواجبات'),
                      SizedBox(height: 8.h),
                      _buildAssignmentsChart(),
                      SizedBox(height: 24.h),
                      _buildSectionTitle('أفضل الطلاب أداءً'),
                      SizedBox(height: 8.h),
                      _buildTopStudents(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final teacherProvider = context.watch<TeacherProvider>();

    final totalStudents = teacherProvider.statsTotalStudents > 0
        ? teacherProvider.statsTotalStudents
        : getMapValue(_overviewStats, 'total_students');

    final attendanceRate = teacherProvider.statsAttendanceRate > 0
        ? teacherProvider.statsAttendanceRate
        : getMapValue(_overviewStats, 'attendance_rate');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: PremiumStatCard(
              title: 'الطلاب',
              value: '$totalStudents',
              icon: Icons.people,
              animationDelay: 0,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: PremiumStatCard(
              title: 'نسبة الحضور',
              value: '$attendanceRate%',
              icon: Icons.check_circle,
              animationDelay: 100,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: PremiumStatCard(
              title: 'الواجبات',
              value: '${getMapValue(_overviewStats, 'total_assignments')}',
              icon: Icons.assignment,
              animationDelay: 200,
            ),
          ),
        ],
      ),
    );
  }

  dynamic getMapValue(Map<String, dynamic> map, String key) {
    return map[key] ?? 0;
  }

  Widget _buildAttendanceChart() {
    if (_attendanceTrends.isEmpty) {
      return _buildNoDataCard('لا توجد بيانات كافية');
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < _attendanceTrends.length; i++) {
      final dayStats = _attendanceTrends[i];
      final present = dayStats['present'] as int? ?? 0;
      final total = dayStats['total'] as int? ?? 1;
      final rate = total > 0 ? (present / total) * 100 : 0.0;
      spots.add(FlSpot(i.toDouble(), rate));
    }

    return Container(
      height: 200.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: GlassMorphismCard(
        padding: EdgeInsets.all(16.w),
        hasNeonBorder: true,
        neonColor: Theme.of(context).colorScheme.primary,
        animationDelay: 300,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 30,
                  showTitles: true,
                  interval: 25,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.primary.withOpacity(0.0),
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
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildAssignmentsChart() {
    if (_assignmentTrends.isEmpty) {
      return _buildNoDataCard('لا توجد بيانات كافية');
    }

    return Container(
      height: 200.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: GlassMorphismCard(
        padding: EdgeInsets.all(16.w),
        hasNeonBorder: true,
        neonColor: Theme.of(context).colorScheme.secondary,
        animationDelay: 400,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontFamily: 'Cairo',
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
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
                    color: Theme.of(context).colorScheme.secondary,
                    width: 14,
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

  Widget _buildNoDataCard(String text) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: GlassMorphismCard(
        padding: EdgeInsets.symmetric(vertical: 30.h),
        backgroundColor:
            Theme.of(context).cardTheme.color?.withOpacity(0.3) ??
            Theme.of(context).colorScheme.surface.withOpacity(0.3),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 32.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              SizedBox(height: 8.h),
              Text(
                text,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStudents() {
    final topStudents = _studentsPerformance.take(5).toList();
    if (topStudents.isEmpty) {
      return _buildNoDataCard('لا توجد بيانات أداء');
    }

    return Column(
      children: topStudents.asMap().entries.map((entry) {
        final index = entry.key;
        final student = entry.value;
        final rankColors = [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFC0C0C0), // Silver
          const Color(0xFFCD7F32), // Bronze
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.primaryContainer,
        ];

        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: GlassMorphismCard(
            padding: EdgeInsets.all(14.w),
            backgroundColor:
                Theme.of(context).cardTheme.color?.withOpacity(0.3) ??
                Theme.of(context).colorScheme.surface.withOpacity(0.3),
            animationDelay: 80 * index,
            child: Row(
              children: [
                // Rank
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: rankColors[index].withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rankColors[index].withOpacity(0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: rankColors[index],
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'حضور: ${student['attendance']}% | واجبات: ${student['assignments']}%',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                // Overall badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${student['overall']}%',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      fontFamily: 'Cairo',
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
