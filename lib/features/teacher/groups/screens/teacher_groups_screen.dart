import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/genius_button.dart';
import '../../../../shared/models/models.dart';
import '../../provider/teacher_provider.dart';
import '../../../auth/provider/auth_provider.dart';

/// 🎨 Teacher Groups Screen - Forest Dark Edition
class TeacherGroupsScreen extends StatefulWidget {
  const TeacherGroupsScreen({super.key});

  @override
  State<TeacherGroupsScreen> createState() => _TeacherGroupsScreenState();
}

class _TeacherGroupsScreenState extends State<TeacherGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerLoad();
    });
  }

  void _triggerLoad() {
    final teacherProvider = context.read<TeacherProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (teacherProvider.groups.isEmpty) {
      if (teacherProvider.selectedCenter != null) {
        teacherProvider.refreshData(forceRefresh: true);
      } else {
        teacherProvider.loadTeacherData(userId);
      }
    }
  }

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
          style: TextStyle(fontWeight: FontWeight.bold),
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
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: provider.isLoading && groups.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => provider.refreshData(forceRefresh: true),
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    children: [
                      _buildSmartSummaryCard(provider),
                      SizedBox(height: 24.h),
                      if (groups.isEmpty)
                        _buildEmptyState(provider)
                      else
                        ...groups.asMap().entries.map(
                          (e) => _buildSmartGroupCard(e.value, provider, e.key),
                        ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(TeacherProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 48.h),
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 64.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          SizedBox(height: 24.h),
          Text(
            'لا توجد مجموعات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          SizedBox(height: 12.h),
          Text(
            'سيظهر هنا تحليل ذكي لمجموعاتك فور إضافتها.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          SizedBox(height: 20.h),
          OutlinedButton.icon(
            onPressed: () => provider.refreshData(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تحديث المجموعات'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSummaryCard(TeacherProvider provider) {
    final isIndependent = context.read<AuthProvider>().currentUser?.role == UserRole.centerAdmin;
    final totalProjected = provider.totalProjectedIncome(isIndependent: isIndependent);
    final totalActual = provider.totalActualIncome(isIndependent: isIndependent);
    
    final totalStudents = provider.groups.fold(
      0,
      (sum, g) => sum + (g.currentStudents > 0 ? g.currentStudents : provider.getStudentCountForGroup(g.id)),
    );
    final totalGroups = provider.groups.length;

    return GlassCard(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.all(24.w),
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
                    'نظرة عامة (المحصل / المتوقع)',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        intl.NumberFormat.currency(
                          symbol: '',
                          decimalDigits: 0,
                        ).format(totalActual),
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().scale(duration: 500.ms),
                      Text(
                        ' / ${intl.NumberFormat.currency(symbol: 'ج.م', decimalDigits: 0).format(totalProjected)}',
                        style: TextStyle(
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  Icons.people_rounded,
                  '$totalStudents طالب',
                  Colors.purple,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryStat(
                  Icons.class_rounded,
                  '$totalGroups مجموعات',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSummaryStat(IconData icon, String label, Color accentColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
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
    final isIndependent = context.read<AuthProvider>().currentUser?.role == UserRole.centerAdmin;
    final financials = provider.calculateGroupFinancials(group, isIndependent: isIndependent);
    final schedules = group.schedules;
    final canMonitor = _isMonitorWindowActive(group);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: GestureDetector(
        onTap: () => context.push('/teacher/groups/${group.id}'),
        child: GlassCard(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // 1. Header Area
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Container(
                      height: 52.w,
                      width: 52.w,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          group.groupName.isNotEmpty ? group.groupName[0] : 'م',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.groupName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${group.courseName ?? 'مادة'} • ${group.currentStudents > 0 ? group.currentStudents : provider.getStudentCountForGroup(group.id)} طالب',
                            style: TextStyle(
                              color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(group),
                  ],
                ),
              ),

              Divider(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300), height: 1),

              // 2. Schedule Section
              if (schedules.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'مواعيد الحصص',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
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
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.purple,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  '${schedule.dayOfWeek} ${schedule.startTime}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
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
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'لم يتم تحديد مواعيد بعد',
                        style: TextStyle(
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                          fontSize: 13.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Financial Progress Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الأداء المالي',
                          style: TextStyle(
                            color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${intl.NumberFormat.currency(symbol: '', decimalDigits: 0).format(financials['actual_teacher_share'])} / ${intl.NumberFormat.currency(symbol: 'ج.م', decimalDigits: 0).format(financials['teacher_share'])}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value:
                            financials['actual_teacher_share']! /
                            (financials['teacher_share'] == 0
                                ? 1
                                : financials['teacher_share']!),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                        minHeight: 6.h,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      isIndependent 
                          ? 'المُحصل فعلياً مقابل إجمالي الإيرادات المتوقعة (${intl.NumberFormat.currency(symbol: 'ج.م', decimalDigits: 0).format(financials['total_income'])})'
                          : 'نصيبك المُحصل فعلياً مقابل النصيب المتوقع من اجمالي الدخل (${intl.NumberFormat.currency(symbol: 'ج.م', decimalDigits: 0).format(financials['total_income'])})',
                      style: TextStyle(
                        color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // 4. Quick Actions
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: GeniusButton(
                        label: 'مراقبة',
                        onPressed: () {
                          if (canMonitor) {
                            context.push('/teacher/attendance/${group.id}');
                            return;
                          }
                          _showMonitorWindowHint();
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GeniusButton(
                        label: 'مراسلة',
                        onPressed: () => context.push('/teacher/messages'),
                        variant: GeniusButtonVariant.glass,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: 100 + (index * 50))).fadeIn().slideX(),
    );
  }

  Widget _buildStatusBadge(GroupModel group) {
    // 0 or negative maxStudents means unlimited capacity in the management system
    final bool isUnlimited = group.maxStudents <= 0;
    final bool isFull = !isUnlimited && group.currentStudents >= group.maxStudents;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isFull
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.15)
            : Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isFull
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.4)
              : Colors.green.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isFull ? 'مكتمل' : 'نشط',
        style: TextStyle(
          color: isFull ? Theme.of(context).colorScheme.error : Colors.green,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
