import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/group_model.dart';
import '../../../../shared/widgets/premium_widgets.dart' show EmptyState;
import '../../provider/teacher_provider.dart';

import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';

/// 🟢 Teacher Attendance Monitor Screen - Glassmorphism 2.0 Overhaul
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadStudents(String groupId) async {
    setState(() => _isLoading = true);

    final teacherProvider = context.read<TeacherProvider>();
    final repo = context.read<SupabaseRepository>();
    List<Map<String, dynamic>> students = [];

    try {
      students = await repo.getGroupAttendanceForToday(groupId);
    } catch (e) {
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
    final teacherProvider = context.read<TeacherProvider>();

    try {
      final teacherId = auth.teacherProfile?.id;
      final centerId = center.currentCenterId;

      if (teacherId != null && centerId != null) {
        _myGroups = List<GroupModel>.from(teacherProvider.groups);

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

    int parseTime(String time) {
      if (time.isEmpty) return 0;
      try {
        final parts = time.trim().split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } catch (_) {
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

    final todayGroups = _myGroups.where((g) {
      return g.schedules.any(
        (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
      );
    }).toList();

    if (todayGroups.isEmpty) return _myGroups.first;

    GroupModel? currentClass;
    GroupModel? nextClass;
    int minDiffToNext = 999999;

    for (var group in todayGroups) {
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
          : startMinutes + 60;

      if (currentTimeMinutes >= startMinutes &&
          currentTimeMinutes <= endMinutes) {
        currentClass = group;
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher/scan'),
        icon: Icon(Icons.qr_code_scanner_rounded, size: 22.sp),
        label: Text('مسح الكروت (QR)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        title: Text(
          'متابعة الحضور',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('جاري التحديث...')));
              _refreshAttendance();
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 26.sp,
            ),
            tooltip: 'تحديث',
          ),
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            if (_myGroups.isEmpty && !_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildNoGroupsState(),
              )
            else ...[
              if (_myGroups.isNotEmpty)
                SliverToBoxAdapter(child: _buildGroupSelector()),
              if (_myGroups.isNotEmpty)
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              if (_myGroups.isNotEmpty)
                SliverToBoxAdapter(child: _buildStatsSummary()),
              if (_myGroups.isNotEmpty)
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildInlineLoader())
              else if (_students.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildNoStudentsState(),
                )
              else
                _buildStudentsList(),
            ],
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GlassCard(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.class_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'المجموعة الحالية',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGroupId,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  style: Theme.of(context).textTheme.titleMedium,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  items: _myGroups.map((group) {
                    return DropdownMenuItem<String>(
                      value: group.id,
                      child: Text(
                        '${group.groupName} - ${_getDayName(group.dayOfWeek)} ${group.startTime ?? ''}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
              SizedBox(height: 16.h),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.access_time_rounded,
                    '${_selectedGroup!.startTime ?? ''} - ${_selectedGroup!.endTime ?? ''}',
                  ),
                  SizedBox(width: 12.w),
                  _buildInfoChip(
                    Icons.groups_rounded,
                    '${_students.length} طالب',
                  ),
                ],
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16.sp),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'حاضر',
              _presentCount,
              Colors.green,
              Icons.check_circle_rounded,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              'غائب',
              _absentCount,
              Theme.of(context).colorScheme.error,
              Icons.cancel_rounded,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              'لم يُسجل',
              _pendingCount,
              AppColors.warningAmber,
              Icons.help_outline_rounded,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return GlassCard(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
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
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
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

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildStudentTile(sortedStudents[index], index),
          childCount: sortedStudents.length,
        ),
      ),
    );
  }

  Widget _buildInlineLoader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: const TableListShimmer(itemCount: 6),
    );
  }

  Widget _buildNoGroupsState() {
    return Center(
      child: EmptyState(
        icon: Icons.class_outlined,
        title: 'لا توجد مجموعات',
        subtitle: 'لم يتم تعيين مجموعات لك حتى الآن لإدارة الحضور',
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: EmptyState(
        icon: Icons.people_outline,
        title: 'لا يوجد طلاب',
        subtitle: 'سيظهر الطلاب المسجلون هنا لمتابعة حضورهم',
      ).animate().fadeIn().scale(),
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
        statusColor = AppColors.statusSuccess;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'حاضر';
        break;
      case 'late':
        statusColor = AppColors.warningAmber;
        statusIcon = Icons.access_time_filled_rounded;
        statusText = 'متأخر';
        break;
      case 'absent':
        statusColor = context.themeError;
        statusIcon = Icons.cancel_rounded;
        statusText = 'غائب';
        break;
      default:
        statusColor = context.themeTextSecondary;
        statusIcon = Icons.help_outline_rounded;
        statusText = 'لم يُسجل';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Semantics(
        label: '$name، الحالة: $statusText',
        container: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56), // Touch target >= 48dp
          decoration: BoxDecoration(
            color: context.themeCard,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.6),
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
                  radius: 24.r,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(
                          avatarUrl,
                          maxHeight: 150,
                          maxWidth: 150,
                        )
                      : null,
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person,
                          color: statusColor,
                          size: 24.sp,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                    if (checkInTime != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13.sp,
                            color: context.themeTextSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'تسجيل: $checkInTime',
                            style: TextStyle(
                              color: context.themeTextSecondary,
                              fontSize: 11.5.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 36, minWidth: 72),
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.08, end: 0),
      ),
    );
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

