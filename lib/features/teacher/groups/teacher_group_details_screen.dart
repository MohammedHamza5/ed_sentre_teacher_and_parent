import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/app_colors.dart';
import '../provider/teacher_provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../attendance/teacher_attendance_history_screen.dart';
import '../../../shared/data/supabase_repository.dart';

/// 🎨 Teacher Group Details Screen
/// Displays full details for a specific group: Info, Students, Schedule
class TeacherGroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const TeacherGroupDetailsScreen({super.key, required this.groupId});

  @override
  State<TeacherGroupDetailsScreen> createState() =>
      _TeacherGroupDetailsScreenState();
}

class _TeacherGroupDetailsScreenState extends State<TeacherGroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  GroupModel? _group;
  List<Map<String, dynamic>> _students = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    final teacherProvider = context.read<TeacherProvider>();
    final repo = context.read<SupabaseRepository>();

    // 1. Find group in provider
    try {
      final group = teacherProvider.groups.firstWhere(
        (g) => g.id == widget.groupId,
      );
      _group = group;

      final studentsResponse = await repo.getGroupStudents(widget.groupId);
      _students = studentsResponse.map((e) {
        final student = e['students'] as Map<String, dynamic>;
        return {
          'student_name': student['full_name'],
          'student_phone': student['phone'],
          'student_avatar': student['avatar_url'],
          'student_id': student['id'],
          'enrollment_id': e['id'],
        };
      }).toList();

      if (_students.isEmpty) {
        _students = teacherProvider.getStudentsForGroup(widget.groupId);
      }
    } catch (e) {
      debugPrint('Error loading group details: $e');
      _error = e.toString();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final canMonitorNow = _isClassActive();
    final tabBarHeight = kTextTabBarHeight + 12.h;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _group == null
          ? _buildErrorState()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 260.h,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.darkBackground,
                    title: innerBoxIsScrolled
                        ? Text(
                            _group!.groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          )
                        : null,
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => context.pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildHeader(tabBarHeight),
                    ),
                    actions: [
                      IconButton(
                        onPressed: _group?.groupCode == null
                            ? null
                            : () async {
                                final code = _group!.groupCode!;
                                await Clipboard.setData(
                                  ClipboardData(text: code),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم نسخ كود المجموعة: $code'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.copy_all_rounded),
                        tooltip: 'نسخ كود المجموعة',
                      ),
                      IconButton(
                        onPressed: () {
                          if (canMonitorNow) {
                            context.push(
                              '/teacher/attendance/${widget.groupId}',
                            );
                            return;
                          }
                          _showMonitorWindowHint();
                        },
                        icon: const Icon(Icons.fact_check_rounded),
                        tooltip: 'مراقبة الحضور',
                      ),
                      SizedBox(width: 4.w),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorWeight: 3,
                      dividerColor: Colors.white12,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.people_alt_rounded),
                          text: 'الطلاب',
                        ),
                        Tab(
                          icon: Icon(Icons.schedule_rounded),
                          text: 'المواعيد',
                        ),
                        Tab(
                          icon: Icon(Icons.fact_check_rounded),
                          text: 'الحضور',
                        ),
                        Tab(
                          icon: Icon(Icons.info_outline_rounded),
                          text: 'معلومات',
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentsTab(),
                  _buildScheduleTab(),
                  _buildAttendanceTab(),
                  _buildInfoTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(double tabBarHeight) {
    final group = _group!;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 220.w,
              height: 220.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                16.w,
                16.h,
                16.w,
                72.h + tabBarHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.center,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        _buildHeaderChip(
                          icon: Icons.people_alt_rounded,
                          label: '${group.currentStudents} طالب',
                        ),
                        _buildHeaderChip(
                          icon: Icons.attach_money_rounded,
                          label: '${group.monthlyFee ?? 0} ج.م',
                        ),
                        if (group.groupCode != null &&
                            group.groupCode!.isNotEmpty)
                          _buildHeaderChip(
                            icon: Icons.qr_code_rounded,
                            label: group.groupCode!,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      group.courseName ?? 'مادة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            bottom: tabBarHeight + 8.h,
            start: 16.w,
            end: 16.w,
            child: PremiumCard(
              hasBorder: false,
              backgroundColor: Colors.black.withValues(alpha: 0.18),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _buildScheduleSummary(group),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.amber),
          SizedBox(height: 16.h),
          Text(
            'لم يتم العثور على المجموعة',
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
          if (_error != null) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12.sp),
              ),
            ),
          ],
          TextButton(onPressed: () => context.pop(), child: const Text('عودة')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentsTab() {
    if (_students.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'لا يوجد طلاب',
        subtitle: 'لم ينضم أي طالب لهذه المجموعة بعد',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final name = student['student_name'] as String? ?? 'طالب';
        final phone = student['student_phone'] as String? ?? '';
        final avatar = student['student_avatar'] as String?;
        final code = student['student_code'] as String?;
        return PremiumCard(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Text(
                          name.isNotEmpty ? name[0] : 'ط',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      phone.isNotEmpty ? phone : '—',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (code != null && code.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'كود: $code',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'نشط',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX();
      },
    );
  }

  Widget _buildScheduleTab() {
    if (_group!.schedules.isEmpty) {
      if (_group!.dayOfWeek != null) {
        // Legacy fallback
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: PremiumCard(
            hasGlow: true,
            glowColor: AppColors.primary,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(Icons.schedule_rounded, color: AppColors.primary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'الموعد: ${_getFieldDayName(_group!.dayOfWeek)} • ${_group!.startTime}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return EmptyState(
        icon: Icons.calendar_today,
        title: 'لا توجد مواعيد',
        subtitle: 'لم يتم تحديد مواعيد لهذه المجموعة',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _group!.schedules.length,
      itemBuilder: (context, index) {
        final schedule = _group!.schedules[index];
        return PremiumCard(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateDay(schedule.dayOfWeek),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${schedule.startTime} - ${schedule.endTime}',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.darkInput,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(
                  schedule.roomName?.isNotEmpty == true
                      ? schedule.roomName!
                      : '—',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    final group = _group!;
    final items = [
      ('اسم المجموعة', group.groupName, Icons.label_rounded),
      ('المادة', group.courseName ?? '-', Icons.book_rounded),
      ('المرحلة', group.gradeLevel ?? '-', Icons.school_rounded),
      ('الكود', group.groupCode ?? '-', Icons.qr_code_rounded),
      (
        'السعر الشهري',
        '${group.monthlyFee ?? 0} ج.م',
        Icons.attach_money_rounded,
      ),
      (
        'عدد الطلاب',
        '${group.currentStudents} / ${group.maxStudents}',
        Icons.people_alt_rounded,
      ),
    ];

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        PremiumCard(
          hasGlow: true,
          glowColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملخص سريع',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: items.map((e) {
                  return _buildInfoPill(label: e.$1, value: e.$2, icon: e.$3);
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    final isLiveActive = _isClassActive();
    final repo = context.read<SupabaseRepository>();

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: repo.getGroupAttendanceForToday(widget.groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return PremiumCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'تحميل ملخص حضور اليوم...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data ?? [];
            final present = data
                .where((s) => s['attendance_status'] == 'present')
                .length;
            final late = data
                .where((s) => s['attendance_status'] == 'late')
                .length;
            final absent = data
                .where((s) => s['attendance_status'] == 'absent')
                .length;
            final pending = data
                .where(
                  (s) =>
                      s['attendance_status'] == 'pending' ||
                      s['attendance_status'] == null,
                )
                .length;

            return PremiumCard(
              hasGlow: true,
              glowColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'حضور اليوم',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          label: 'حضور',
                          value: present,
                          color: AppColors.success,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'تأخير',
                          value: late,
                          color: AppColors.warning,
                          icon: Icons.access_time_rounded,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'غياب',
                          value: absent,
                          color: AppColors.error,
                          icon: Icons.cancel_rounded,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'لم يُسجل',
                          value: pending,
                          color: Colors.white54,
                          icon: Icons.help_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
          },
        ),
        SizedBox(height: 14.h),
        PremiumCard(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Icon(
                Icons.broadcast_on_personal_rounded,
                size: 48.sp,
                color: isLiveActive ? AppColors.error : Colors.grey,
              ),
              SizedBox(height: 16.h),
              Text(
                'مراقبة الحضور (مباشر)',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                isLiveActive
                    ? 'الحصة جارية الآن. يمكنك بدء مراقبة الحضور.'
                    : 'لا توجد حصة جارية حالياً (يفتح قبل الموعد بـ 30 دقيقة).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: () {
                    if (isLiveActive) {
                      context.push('/teacher/attendance/${widget.groupId}');
                      return;
                    }
                    _showMonitorWindowHint();
                  },
                  gradient: LinearGradient(
                    colors: isLiveActive
                        ? [
                            AppColors.error,
                            AppColors.error.withValues(alpha: 0.8),
                          ]
                        : [Colors.white10, Colors.white10],
                  ),
                  text: 'بدء المراقبة',
                  icon: Icons.play_circle_fill_rounded,
                  hasGlow: isLiveActive,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(),
        SizedBox(height: 20.h),
        PremiumCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    TeacherAttendanceHistoryScreen(groupId: widget.groupId),
              ),
            );
          },
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history, color: AppColors.primary),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل الحضور',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'مراجعة الحضور للأيام السابقة',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            ],
          ),
        ).animate(delay: 100.ms).fadeIn().slideY(),
      ],
    );
  }

  bool _isClassActive() {
    if (_group == null || _group!.schedules.isEmpty) return false;

    final now = DateTime.now();
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

    // Check if any schedule specifically for TODAY matches time window
    return _group!.schedules.any((s) {
      if (s.dayOfWeek.toLowerCase() != todayName.toLowerCase()) return false;

      final startMinutes = parseTimeToMinutes(s.startTime);
      if (startMinutes < 0) return false;
      final endMinutes = s.endTime.isNotEmpty
          ? parseTimeToMinutes(s.endTime)
          : startMinutes + 60;

      // Active window: Start - 30m to End + 30m
      return currentTimeMinutes >= (startMinutes - 30) &&
          currentTimeMinutes <= (endMinutes + 30);
    });
  }

  Widget _buildInfoPill({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.darkInput,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.primaryLight),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMonitorWindowHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'المراقبة متاحة قبل الحصة بـ 30 دقيقة وحتى بعدها بـ 30 دقيقة فقط',
        ),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 6.h),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _translateDay(String dayEnglish) {
    const days = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };
    return days[dayEnglish.toLowerCase()] ?? dayEnglish;
  }

  String _getFieldDayName(int? dayIndex) {
    if (dayIndex == null) return '-';
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];
    if (dayIndex < 0 || dayIndex > 6) return '-';
    return days[dayIndex];
  }

  String _buildScheduleSummary(GroupModel group) {
    if (group.schedules.isEmpty) {
      if (group.dayOfWeek != null && (group.startTime?.isNotEmpty == true)) {
        return '${_getFieldDayName(group.dayOfWeek)} • ${group.startTime}';
      }
      return 'لا توجد مواعيد';
    }

    final first = group.schedules.first;
    final day = _translateDay(first.dayOfWeek);
    final time = first.startTime;
    return '$day • $time';
  }
}
