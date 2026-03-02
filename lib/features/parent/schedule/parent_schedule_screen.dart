import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../provider/parent_provider.dart';

class ParentScheduleScreen extends StatefulWidget {
  const ParentScheduleScreen({super.key});

  @override
  State<ParentScheduleScreen> createState() => _ParentScheduleScreenState();
}

class _ParentScheduleScreenState extends State<ParentScheduleScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedule = [];
  late TabController _tabController;

  // Premium colors
  static const _gradientStart = Color(0xFF007AFF);
  static const _gradientEnd = Color(0xFF5AC8FA);

  final List<String> _dayNames = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
  final List<Color> _dayColors = [
    const Color(0xFF6366F1),
    const Color(0xFFEC4899),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFF14B8A6),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _getTodayIndex(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  int _getTodayIndex() {
    final weekday = DateTime.now().weekday;
    // Convert to Saturday-based week (Saturday = 0)
    return (weekday + 1) % 7;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final parentProvider = context.read<ParentProvider>();
    if (parentProvider.selectedChild != null &&
        parentProvider.selectedCenter != null) {
      final schedule = await parentProvider.getChildSchedule();
      if (mounted) {
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : Column(
              children: [
                // Premium Header
                Container(
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
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                      child: Column(
                        children: [
                          // Title (centered, no back button)
                          Text(
                            'الجدول الدراسي',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Premium Day Selector Pills
                          SizedBox(
                            height: 50.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _dayNames.length,
                              separatorBuilder: (_, __) => SizedBox(width: 8.w),
                              itemBuilder: (context, index) {
                                final isSelected =
                                    _tabController.index == index;
                                final isToday = index == _getTodayIndex();
                                return GestureDetector(
                                  onTap: () {
                                    _tabController.animateTo(index);
                                    setState(() {});
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: isToday && !isSelected
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            )
                                          : null,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _dayNames[index],
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? _gradientStart
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Schedule Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(
                      7,
                      (dayIndex) => _buildDaySchedule(dayIndex),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDaySchedule(int dayIndex) {
    final daySchedule = _schedule.where((s) {
      final sDay = s['day_of_week'] as int?;
      return sDay == dayIndex;
    }).toList();

    if (daySchedule.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(24.w),
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _dayColors[dayIndex].withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available,
                  size: 48.sp,
                  color: _dayColors[dayIndex],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'لا توجد حصص لابنك في ${_dayNames[dayIndex]}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'يوم إجازة \u{1F389}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: daySchedule.length,
      itemBuilder: (context, index) {
        final item = daySchedule[index];
        return _buildScheduleCard(item, dayIndex, index);
      },
    );
  }

  Widget _buildScheduleCard(
    Map<String, dynamic> item,
    int dayIndex,
    int index,
  ) {
    final color = _dayColors[dayIndex];
    final startTime = item['start_time'] as String? ?? '00:00';
    final endTime = item['end_time'] as String? ?? '00:00';
    final courseName = item['course_name'] as String? ?? 'مادة';
    final groupName = item['group_name'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
      child: Row(
        children: [
          // Time Column
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
            ),
            child: Column(
              children: [
                Text(
                  startTime.substring(0, 5),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 6.h),
                  height: 20.h,
                  width: 2,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                Text(
                  endTime.substring(0, 5),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (groupName.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 14.sp,
                          color: const Color(0xFF6B7280),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          groupName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Arrow
          Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Icon(
              Icons.chevron_left,
              color: const Color(0xFFD1D5DB),
              size: 24.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
  }
}
