import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;

// Removed AppColors import
import '../../../../shared/widgets/premium_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../provider/teacher_provider.dart';

class TeacherGroupsScreen extends StatefulWidget {
  const TeacherGroupsScreen({super.key});

  @override
  State<TeacherGroupsScreen> createState() => _TeacherGroupsScreenState();
}

class _TeacherGroupsScreenState extends State<TeacherGroupsScreen> {
  bool _isMonitorWindowActive(GroupModel group) {
    if (group.schedules.isEmpty) return false;

    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final todayName = dayNames[now.weekday - 1];

    int parseTimeToMinutes(String time) {
      if (time.isEmpty) return -1;
      final trimmed = time.trim();
      final parts = trimmed.split(' ');
      final hhmm = parts.first;
      final ampm = parts.length > 1 ? parts[1].toLowerCase() : null;
      final hhmmParts = hhmm.split(':');
      if (hhmmParts.length < 2) return -1;
      final hour = int.tryParse(hhmmParts[0]);
      final minute = int.tryParse(hhmmParts[1]);
      if (hour == null || minute == null) return -1;

      var h = hour;
      if (ampm == 'pm' && h < 12) h += 12;
      if (ampm == 'am' && h == 12) h = 0;
      return (h * 60) + minute;
    }

    final schedule = group.schedules.firstWhere(
      (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
      orElse: () => const ScheduleItem(
        id: '',
        courseName: '',
        groupName: '',
        teacherName: '',
        dayOfWeek: '',
        startTime: '',
        endTime: '',
        centerId: '',
      ),
    );

    if (schedule.startTime.isEmpty) return false;

    final startMinutes = parseTimeToMinutes(schedule.startTime);
    if (startMinutes < 0) return false;
    final endMinutes = schedule.endTime.isNotEmpty
        ? parseTimeToMinutes(schedule.endTime)
        : startMinutes + 60;

    final currentMinutes = (now.hour * 60) + now.minute;
    return currentMinutes >= (startMinutes - 30) &&
        currentMinutes <= (endMinutes + 30);
  }

  void _showMonitorWindowHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'المراقبة متاحة قبل الحصة بـ 30 دقيقة وحتى بعدها بـ 30 دقيقة فقط',
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final groups = provider.groups;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'المجموعات الذكية',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20.sp,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildSmartSummaryCard(provider),
              SizedBox(height: 20.h),
              if (groups.isEmpty)
                _buildEmptyState()
              else
                ...groups.asMap().entries.map(
                  (e) => _buildSmartGroupCard(e.value, provider, e.key),
                ),
              SizedBox(height: 80.h), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: EmptyState(
        icon: Icons.groups_rounded,
        title: 'لا توجد مجموعات',
        subtitle: 'سيظهر هنا تحليل ذكي لمجموعاتك فور إضافتها.',
      ),
    );
  }

  Widget _buildSmartSummaryCard(TeacherProvider provider) {
    final totalIncome = provider.totalProjectedIncome;
    final totalStudents = provider.groups.fold(
      0,
      (sum, g) => sum + g.currentStudents,
    );
    final totalGroups = provider.groups.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نظرة عامة (شهرية)',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                      fontSize: 14.sp,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    intl.NumberFormat.currency(
                      symbol: 'ج.م',
                      decimalDigits: 0,
                    ).format(totalIncome),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ).animate().scale(duration: 500.ms),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 30.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildSummaryStat(Icons.people_rounded, '$totalStudents طالب'),
              SizedBox(width: 16.w),
              _buildSummaryStat(Icons.class_rounded, '$totalGroups مجموعات'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSummaryStat(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onPrimaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartGroupCard(
    GroupModel group,
    TeacherProvider provider,
    int index,
  ) {
    final financials = provider.calculateGroupFinancials(group);
    final schedules = group.schedules;
    final canMonitor = _isMonitorWindowActive(group);

    return GestureDetector(
      onTap: () => context.push('/teacher/groups/${group.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Header Area
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    height: 48.w,
                    width: 48.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        group.groupName.isNotEmpty ? group.groupName[0] : 'G',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.groupName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          '${group.courseName ?? 'مادة'} • ${group.currentStudents} طالب',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12.sp,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(group),
                ],
              ),
            ),

            Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              height: 1,
            ),

            // 2. Schedule Section - "The Smart & Genius Part"
            if (schedules.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مواعيد الحصص',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: schedules.map((schedule) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 14.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '${schedule.dayOfWeek} ${schedule.startTime}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 12.sp,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'لم يتم تحديد مواعيد بعد',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),

            // 3. Financial Progress Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأداء المالي',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12.sp,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        intl.NumberFormat.currency(
                          symbol: 'ج.م',
                          decimalDigits: 0,
                        ).format(financials['teacher_share']),
                        style: TextStyle(
                          color: Colors
                              .greenAccent, // Kept for financial positive vibe
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.h),
                    child: LinearProgressIndicator(
                      value:
                          financials['teacher_share']! /
                          (financials['total_income'] == 0
                              ? 1
                              : financials['total_income']!),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.greenAccent,
                      ),
                      minHeight: 6.h,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'نسبتك من اجمالي الدخل (${intl.NumberFormat.currency(symbol: 'ج.م', decimalDigits: 0).format(financials['total_income'])})',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10.sp,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 4. Quick Actions
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: 'مراقبة',
                      icon: Icons.broadcast_on_personal_rounded,
                      onPressed: () {
                        if (canMonitor) {
                          context.push('/teacher/attendance/${group.id}');
                          return;
                        }
                        _showMonitorWindowHint();
                      },
                      height: 38.h,
                      fontSize: 13.sp,
                      hasGlow: canMonitor,
                      gradient: canMonitor
                          ? LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.1),
                                Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.1),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GradientButton(
                      text: 'مراسلة',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => context.push('/teacher/messages'),
                      height: 38.h,
                      fontSize: 13.sp,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.primary,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 + (index * 50))).fadeIn().slideX();
  }

  Widget _buildStatusBadge(GroupModel group) {
    bool isFull = group.currentStudents >= group.maxStudents;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isFull
            ? Theme.of(context).colorScheme.error.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isFull
              ? Theme.of(context).colorScheme.error.withOpacity(0.5)
              : Colors.green.withOpacity(0.5),
        ),
      ),
      child: Text(
        isFull ? 'مكتمل' : 'نشط',
        style: TextStyle(
          color: isFull ? Theme.of(context).colorScheme.error : Colors.green,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
