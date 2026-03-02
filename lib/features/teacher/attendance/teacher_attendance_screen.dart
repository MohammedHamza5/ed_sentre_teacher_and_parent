import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_colors.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/group_model.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../provider/teacher_provider.dart';

/// Teacher Attendance Monitor Screen - Premium Dark Mode
class TeacherAttendanceScreen extends StatefulWidget {
  final String? groupId;

  const TeacherAttendanceScreen({super.key, this.groupId});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  bool _isLoading = true;
  String? _selectedGroupId;
  List<GroupModel> _myGroups = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
    _loadInitialData();
  }

  Future<void> _loadStudents(String groupId) async {
    debugPrint('👥 [Attendance] _loadStudents: START for Group ID: $groupId');
    setState(() => _isLoading = true);

    final teacherProvider = context.read<TeacherProvider>();
    final repo = context.read<SupabaseRepository>();
    List<Map<String, dynamic>> students = [];

    try {
      students = await repo.getGroupAttendanceForToday(groupId);
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
      students = teacherProvider.getStudentsForGroup(groupId).map((s) {
        return {
          'id': s['student_id'],
          'student_id': s['student_id'],
          'name': s['student_name'],
          'code': s['student_code'],
          'avatar_url': s['student_avatar'],
          'attendance_status': s['attendance_status'] ?? 'pending',
          'check_in_time': s['check_in_time'],
        };
      }).toList();
    }

    if (students.isEmpty) {
      debugPrint(
        '⚠️ [Attendance] Students list empty. Forcing refresh from API...',
      );
      await teacherProvider.refreshData();
      final refreshedStudents = teacherProvider
          .getStudentsForGroup(groupId)
          .map((s) {
            return {
              'id': s['student_id'],
              'student_id': s['student_id'],
              'name': s['student_name'],
              'code': s['student_code'],
              'avatar_url': s['student_avatar'],
              'attendance_status': s['attendance_status'] ?? 'pending',
              'check_in_time': s['check_in_time'],
            };
          })
          .toList();
      debugPrint(
        '👥 [Attendance] After refresh: ${refreshedStudents.length} students',
      );

      setState(() {
        _students = refreshedStudents;
        _isLoading = false;
      });
    } else {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final center = context.read<CenterProvider>();
    final repo = context.read<SupabaseRepository>();

    try {
      final teacherId = auth.teacherProfile?.id;
      final centerId = center.currentCenterId;

      if (teacherId != null && centerId != null) {
        _myGroups = await repo.getTeacherGroups(teacherId, centerId);

        if (_myGroups.isNotEmpty) {
          if (_selectedGroupId == null ||
              !_myGroups.any((g) => g.id == _selectedGroupId)) {
            _selectedGroupId = _findNearestGroup()?.id ?? _myGroups.first.id;
          }
          await _refreshAttendance();
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance init: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  GroupModel? _findNearestGroup() {
    if (_myGroups.isEmpty) return null;
    final now = DateTime.now();

    // Helper to parse time string "HH:MM"
    int parseTime(String time) {
      if (time.isEmpty) return 0;
      try {
        final parts = time.trim().split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } catch (e) {
        return 0;
      }
    }

    final currentTimeMinutes = now.hour * 60 + now.minute;
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

    debugPrint('🕒 [Attendance] _findNearestGroup: START');
    debugPrint('🕒 [Attendance] Current Time: $now ($todayName)');

    // Filter groups that have a schedule TODAY
    final todayGroups = _myGroups.where((g) {
      final hasSchedule = g.schedules.any(
        (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
      );
      if (hasSchedule) debugPrint('   - Candidate Group: ${g.groupName}');
      return hasSchedule;
    }).toList();

    debugPrint(
      '🕒 [Attendance] Today\'s Groups with Schedules: ${todayGroups.length}',
    );

    if (todayGroups.isEmpty) {
      debugPrint(
        '⚠️ [Attendance] No groups scheduled for today. Defaulting to first group.',
      );
      return _myGroups.first;
    }

    GroupModel? currentClass;
    GroupModel? nextClass;
    int minDiffToNext = 999999;

    for (var group in todayGroups) {
      // Find the specific schedule for today
      final schedule = group.schedules.firstWhere(
        (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
        orElse: () => ScheduleItem(
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

      if (schedule.startTime.isEmpty) continue;

      final startMinutes = parseTime(schedule.startTime);
      final endMinutes = schedule.endTime.isNotEmpty
          ? parseTime(schedule.endTime)
          : startMinutes + 60; // Default 60 mins

      debugPrint(
        '   👉 Checking ${group.groupName}: ${schedule.startTime} - ${schedule.endTime}',
      );

      if (currentTimeMinutes >= startMinutes &&
          currentTimeMinutes <= endMinutes) {
        currentClass = group;
        debugPrint('   ✅ MATCHED CURRENT CLASS: ${group.groupName}');
        break;
      }

      final diffToStart = startMinutes - currentTimeMinutes;
      if (diffToStart > 0 && diffToStart < minDiffToNext) {
        minDiffToNext = diffToStart;
        nextClass = group;
      }
    }

    return currentClass ?? nextClass ?? todayGroups.first;
  }

  Future<void> _refreshAttendance() async {
    if (_selectedGroupId == null) return;
    try {
      await _loadStudents(_selectedGroupId!);
    } catch (e) {
      debugPrint('Error refreshing attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحديث: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  int get _presentCount => _students
      .where(
        (s) =>
            s['attendance_status'] == 'present' ||
            s['attendance_status'] == 'late',
      )
      .length;
  int get _absentCount =>
      _students.where((s) => s['attendance_status'] == 'absent').length;
  int get _pendingCount => _students
      .where(
        (s) =>
            s['attendance_status'] == 'pending' ||
            s['attendance_status'] == null,
      )
      .length;

  GroupModel? get _selectedGroup => _myGroups.firstWhere(
    (g) => g.id == _selectedGroupId,
    orElse: () => _myGroups.first,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_myGroups.isEmpty) ...[
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            _isLoading
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildInlineLoader(),
                  )
                : SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildNoGroupsState(),
                  ),
          ] else ...[
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            SliverToBoxAdapter(child: _buildGroupSelector()),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            SliverToBoxAdapter(child: _buildStatsSummary()),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            if (_isLoading)
              SliverToBoxAdapter(child: _buildInlineLoader())
            else if (_students.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildNoStudentsState(),
              )
            else ...[
              _buildStudentsList(),
              SliverToBoxAdapter(child: SizedBox(height: 80.h)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkSurface,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 20.w, bottom: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.fact_check_outlined,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'متابعة الحضور',
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
                        'مراقبة حضور وغياب الطلاب',
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
          onPressed: _refreshAttendance,
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'تحديث',
        ),
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: DrawerMenuButton(isTeacher: true),
        ),
      ],
    );
  }

  Widget _buildGroupSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: PremiumCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.class_, color: AppColors.primaryLight, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'الحصة الحالية',
                  style: TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.darkInput,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGroupId,
                  isExpanded: true,
                  dropdownColor: AppColors.darkElevated,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryLight,
                  ),
                  items: _myGroups.map((group) {
                    return DropdownMenuItem<String>(
                      value: group.id,
                      child: Builder(
                        builder: (context) {
                          final todayDate = DateTime.now();
                          final dayNames = [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ];
                          final todayName = dayNames[todayDate.weekday - 1];
                          var timeDisplay = group.startTime ?? '';

                          try {
                            final schedule = group.schedules.firstWhere(
                              (s) =>
                                  s.dayOfWeek.toLowerCase() ==
                                  todayName.toLowerCase(),
                            );
                            if (schedule.startTime.isNotEmpty) {
                              timeDisplay = schedule.startTime;
                            }
                          } catch (_) {}

                          return Text(
                            '${group.groupName} - ${_getDayName(group.dayOfWeek)} $timeDisplay',
                            style: TextStyle(color: AppColors.textOnDark),
                          );
                        },
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGroupId = value;
                        _students = [];
                      });
                      _loadStudents(value);
                    }
                  },
                ),
              ),
            ),
            if (_selectedGroup != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.access_time,
                    '${_selectedGroup!.startTime ?? ''} - ${_selectedGroup!.endTime ?? ''}',
                  ),
                  SizedBox(width: 12.w),
                  _buildInfoChip(Icons.people, '${_students.length} طالب'),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 14.sp),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(color: AppColors.textOnDark, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'حضور',
              _presentCount,
              AppColors.success,
              Icons.check_circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildStatCard(
              'غياب',
              _absentCount,
              AppColors.error,
              Icons.cancel,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildStatCard(
              'لم يُسجل',
              _pendingCount,
              AppColors.warning,
              Icons.help_outline,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return PremiumCard(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    final sortedStudents = List<Map<String, dynamic>>.from(_students)
      ..sort((a, b) {
        const order = {'present': 0, 'late': 1, 'pending': 2, 'absent': 3};
        final aStatus = a['attendance_status'] as String? ?? 'pending';
        final bStatus = b['attendance_status'] as String? ?? 'pending';
        return (order[aStatus] ?? 2).compareTo(order[bStatus] ?? 2);
      });

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _buildStudentTile(sortedStudents[index], index),
        );
      }, childCount: sortedStudents.length),
    );
  }

  Widget _buildInlineLoader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: PremiumCard(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'جاري التحميل...',
              style: TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student, int index) {
    final name = student['name'] as String? ?? 'طالب';
    final status = student['attendance_status'] as String? ?? 'pending';
    final checkInTime = student['check_in_time'] as String?;
    final avatarUrl = student['avatar_url'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'present':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'حاضر';
        break;
      case 'late':
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time;
        statusText = 'متأخر';
        break;
      case 'absent':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'غائب';
        break;
      default:
        statusColor = AppColors.textOnDarkHint;
        statusIcon = Icons.help_outline;
        statusText = 'لم يُسجل';
    }

    return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: PremiumCard(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, color: statusColor, size: 22.sp)
                        : null,
                  ),
                ),
                SizedBox(width: 12.w),

                // Name & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      if (checkInTime != null)
                        Text(
                          'وقت الحضور: $checkInTime',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textOnDarkSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildNoGroupsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Icon(
              Icons.class_outlined,
              size: 56.sp,
              color: AppColors.textOnDarkHint,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد مجموعات',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textOnDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لم يتم تعيين مجموعات لك بعد',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Icon(
              Icons.people_outline,
              size: 56.sp,
              color: AppColors.textOnDarkHint,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا يوجد طلاب في هذه المجموعة',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'سيظهر الطلاب المسجلون هنا',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  String _getDayName(int? dayIndex) {
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];
    if (dayIndex == null || dayIndex < 0 || dayIndex > 6) return '';
    return days[dayIndex];
  }
}
