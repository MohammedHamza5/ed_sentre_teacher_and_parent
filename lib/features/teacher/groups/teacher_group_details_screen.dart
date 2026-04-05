import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/config/app_colors.dart';
import '../provider/teacher_provider.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/genius_button.dart';
import '../attendance/teacher_attendance_history_screen.dart';
import '../../../../shared/data/supabase_repository.dart';

/// 🎨 Teacher Group Details Screen - Forest Dark Edition
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
      backgroundColor: AppColors.forestDeep,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.accentVivid,
              ),
            )
          : _group == null
          ? _buildErrorState()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 260.h,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.forestPrimary,
                    title: innerBoxIsScrolled
                        ? Text(
                            _group!.groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          )
                        : null,
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textDisplay,
                      ),
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
                                    content: Text(
                                      'تم نسخ كود المجموعة: $code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.forestDeep,
                                      ),
                                    ),
                                    backgroundColor: AppColors.emeraldGreen,
                                  ),
                                );
                              },
                        icon: const Icon(
                          Icons.copy_all_rounded,
                          color: AppColors.textDisplay,
                        ),
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
                        icon: const Icon(
                          Icons.fact_check_rounded,
                          color: AppColors.textDisplay,
                        ),
                        tooltip: 'مراقبة الحضور',
                      ),
                      SizedBox(width: 4.w),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.accentVivid,
                      labelColor: AppColors.accentVivid,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
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
      decoration: BoxDecoration(
        color: AppColors.forestPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: Stack(
        children: [
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
                      spacing: 12.w,
                      runSpacing: 12.h,
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
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      group.courseName ?? 'مادة',
                      style: TextStyle(
                        color: AppColors.textMuted,
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
            child: GlassCard(
              color: AppColors.darkSurface.withValues(alpha: 0.8),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentVivid.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.accentVivid.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: AppColors.accentVivid,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
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
                            color: AppColors.textDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _buildScheduleSummary(group),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.glassBorderHighlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.accentVivid),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textDisplay,
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
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.forestPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderHighlight),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64.sp,
              color: AppColors.errorRed,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          SizedBox(height: 24.h),
          Text(
            'لم يتم العثور على المجموعة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDisplay,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          if (_error != null) ...[
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ).animate().fadeIn(delay: 300.ms),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentsTab() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64.sp,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا يوجد طلاب',
              style: TextStyle(
                color: AppColors.textDisplay,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم ينضم أي طالب لهذه المجموعة بعد',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final name = student['student_name'] as String? ?? 'طالب';
        final phone = student['student_phone'] as String? ?? '';
        final avatar = student['student_avatar'] as String?;
        final code = student['student_code'] as String?;
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child:
              GlassCard(
                    color: AppColors.darkSurface.withValues(alpha: 0.7),
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.glassBorderHighlight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24.r,
                            backgroundColor: AppColors.forestPrimary,
                            child: avatar != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: avatar,
                                      width: 48.r,
                                      height: 48.r,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  )
                                : Text(
                                    name.isNotEmpty ? name[0] : 'ط',
                                    style: TextStyle(
                                      color: AppColors.textDisplay,
                                      fontSize: 18.sp,
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
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textDisplay,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                phone.isNotEmpty ? phone : '—',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (code != null && code.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  'كود: $code',
                                  style: TextStyle(
                                    color: AppColors.textMuted.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.emeraldGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'نشط',
                            style: TextStyle(
                              color: AppColors.emeraldGreen,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideX(),
        );
      },
    );
  }

  Widget _buildScheduleTab() {
    if (_group!.schedules.isEmpty) {
      if (_group!.dayOfWeek != null) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: GlassCard(
            color: AppColors.darkSurface.withValues(alpha: 0.7),
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentVivid.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.accentVivid.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: AppColors.accentVivid,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'الموعد: ${_getFieldDayName(_group!.dayOfWeek)} • ${_group!.startTime}',
                    style: TextStyle(
                      color: AppColors.textDisplay,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 64.sp,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد مواعيد',
              style: TextStyle(
                color: AppColors.textDisplay,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم يتم تحديد مواعيد لهذه المجموعة',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _group!.schedules.length,
      itemBuilder: (context, index) {
        final schedule = _group!.schedules[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: GlassCard(
            color: AppColors.darkSurface.withValues(alpha: 0.7),
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.infoPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.infoPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: AppColors.infoPurple,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translateDay(schedule.dayOfWeek),
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.forestPrimary,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.glassBorderHighlight),
                  ),
                  child: Text(
                    schedule.roomName?.isNotEmpty == true
                        ? schedule.roomName!
                        : '—',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
      padding: EdgeInsets.all(20.w),
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCard(
          color: AppColors.darkSurface.withValues(alpha: 0.7),
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملخص سريع',
                style: TextStyle(
                  color: AppColors.textDisplay,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 20.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 16.w) / 2;
                  return Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    children: items.map((e) {
                      return SizedBox(
                        width: itemWidth,
                        child: _buildInfoPill(label: e.$1, value: e.$2, icon: e.$3),
                      );
                    }).toList(),
                  );
                },
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
      padding: EdgeInsets.all(20.w),
      physics: const BouncingScrollPhysics(),
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: repo.getGroupAttendanceForToday(widget.groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GlassCard(
                color: AppColors.darkSurface.withValues(alpha: 0.7),
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        backgroundColor: AppColors.accentVivid,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'تحميل ملخص حضور اليوم...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15.sp,
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

            return GlassCard(
              color: AppColors.darkSurface.withValues(alpha: 0.7),
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today_rounded,
                        color: AppColors.textDisplay,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'حضور اليوم',
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          label: 'حضور',
                          value: present,
                          color: AppColors.emeraldGreen,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'تأخير',
                          value: late,
                          color: AppColors.warmAmber,
                          icon: Icons.access_time_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'غياب',
                          value: absent,
                          color: AppColors.errorRed,
                          icon: Icons.cancel_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'لم يُسجل',
                          value: pending,
                          color: AppColors.textMuted,
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
        SizedBox(height: 20.h),
        GlassCard(
          color: AppColors.darkSurface.withValues(alpha: 0.7),
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Icon(
                    Icons.broadcast_on_personal_rounded,
                    size: 56.sp,
                    color: isLiveActive
                        ? AppColors.errorRed
                        : AppColors.textMuted,
                  )
                  .animate(target: isLiveActive ? 1 : 0)
                  .scale(
                    duration: 400.ms,
                    begin: Offset(0.8, 0.8),
                    end: Offset(1, 1),
                  ),
              SizedBox(height: 16.h),
              Text(
                'مراقبة الحضور (مباشر)',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                isLiveActive
                    ? 'الحصة جارية الآن. يمكنك بدء مراقبة الحضور.'
                    : 'لا توجد حصة جارية حالياً (يفتح قبل الموعد بـ 30 دقيقة).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: GeniusButton(
                  label: 'بدء المراقبة',
                  onPressed: () {
                    if (isLiveActive) {
                      context.push('/teacher/attendance/${widget.groupId}');
                      return;
                    }
                    _showMonitorWindowHint();
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(),
        SizedBox(height: 20.h),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    TeacherAttendanceHistoryScreen(groupId: widget.groupId),
              ),
            );
          },
          child: GlassCard(
            color: AppColors.darkSurface.withValues(alpha: 0.7),
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.infoPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.infoPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.infoPurple,
                  ),
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
                          color: AppColors.textDisplay,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'مراجعة الحضور للأيام السابقة',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn().slideY(),
        ),
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

    return _group!.schedules.any((s) {
      if (s.dayOfWeek.toLowerCase() != todayName.toLowerCase()) return false;

      final startMinutes = parseTimeToMinutes(s.startTime);
      if (startMinutes < 0) return false;
      final endMinutes = s.endTime.isNotEmpty
          ? parseTimeToMinutes(s.endTime)
          : startMinutes + 60;

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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.forestPrimary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.glassBorderHighlight),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8.w,
            top: -4.h,
            child: Icon(
              icon,
              size: 28.sp,
              color: AppColors.textMuted.withValues(alpha: 0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textDisplay,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
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
      const SnackBar(
        content: Text(
          'المراقبة متاحة قبل الحصة بـ 30 دقيقة وحتى بعدها بـ 30 دقيقة فقط',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.warmAmber,
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.sp,
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
