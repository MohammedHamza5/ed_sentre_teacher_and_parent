import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/group_model.dart';
import '../../../../shared/models/enums.dart';
import '../../../../core/widgets/genius/glass_card.dart';

/// 🎨 Teacher Schedule Screen - Forest Dark Edition
class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  late int _selectedDayIndex;
  bool _isLoading = true;
  List<GroupModel> _allGroups = [];
  List<GroupModel> _displayedGroups = [];

  final List<_DayItem> _days = [
    const _DayItem(index: 0, name: 'السبت', shortName: 'س'),
    const _DayItem(index: 1, name: 'الأحد', shortName: 'ح'),
    const _DayItem(index: 2, name: 'الاثنين', shortName: 'ن'),
    const _DayItem(index: 3, name: 'الثلاثاء', shortName: 'ث'),
    const _DayItem(index: 4, name: 'الأربعاء', shortName: 'ر'),
    const _DayItem(index: 5, name: 'الخميس', shortName: 'خ'),
    const _DayItem(index: 6, name: 'الجمعة', shortName: 'ج'),
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    _selectedDayIndex = (today + 1) % 7;
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final centerProvider = Provider.of<CenterProvider>(
        context,
        listen: false,
      );
      final repo = Provider.of<SupabaseRepository>(context, listen: false);

      final teacherId = authProvider.teacherProfile?.id;

      if (teacherId != null && centerProvider.availableCenters.isEmpty) {
        await centerProvider.loadTeacherCenters(teacherId);
      }

      final centerId = centerProvider.currentCenterId;

      if (teacherId != null && centerId != null) {
        final groups = await repo.getTeacherGroups(teacherId, centerId);
        _allGroups = groups;
      }
      _filterGroupsByDay();
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterGroupsByDay() {
    if (!mounted) return;

    final selectedDayEnum = DayOfWeek.fromInt(_selectedDayIndex);
    final selectedDayName = selectedDayEnum.englishName.toLowerCase();

    final filtered = <GroupModel>[];

    for (var group in _allGroups) {
      final schedulesOnDay = group.schedules
          .where((s) => s.dayOfWeek.toLowerCase() == selectedDayName)
          .toList();

      if (schedulesOnDay.isNotEmpty) {
        for (var schedule in schedulesOnDay) {
          filtered.add(
            group.copyWith(
              startTime: schedule.startTime,
              endTime: schedule.endTime,
              dayOfWeek: selectedDayEnum.value,
            ),
          );
        }
      } else if (group.schedules.isEmpty &&
          group.dayOfWeek == _selectedDayIndex) {
        filtered.add(group);
      }
    }

    setState(() {
      _displayedGroups = filtered
        ..sort(
          (a, b) => (a.startTime ?? '00:00').compareTo(b.startTime ?? '00:00'),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      appBar: AppBar(
        title: Text(
          'جدول الحصص',
          style: TextStyle(
            color: AppColors.textDisplay,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.forestDeep,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDisplay),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.accentVivid,
            ),
            onPressed: _loadSchedule,
          ),
          const SizedBox.shrink(),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedule,
        backgroundColor: AppColors.accentVivid,
        color: AppColors.darkSurface,
        child: Column(
          children: [
            SizedBox(height: 20.h),
            _buildDaySelector(),
            SizedBox(height: 24.h),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _displayedGroups.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                      ).copyWith(bottom: 100.h),
                      itemCount: _displayedGroups.length,
                      itemBuilder: (context, index) {
                        final group = _displayedGroups[index];
                        return _buildScheduleCard(group, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAY SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDaySelector() {
    return SizedBox(
      height: 90.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (c, i) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day.index == _selectedDayIndex;
          final hasSession = _hasSessionsOnDay(day.index);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = day.index;
                _filterGroupsByDay();
              });
            },
            child:
                Container(
                      width: 72.w,
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentVivid.withValues(alpha: 0.15)
                            : AppColors.darkSurface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentVivid
                              : AppColors.glassBorderHighlight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accentVivid
                                  : AppColors.textDisplay,
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (hasSession)
                            Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentVivid
                                        : AppColors.emeraldGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.accentVivid
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 6,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .scale(
                                  duration: 800.ms,
                                  begin: Offset(0.8, 0.8),
                                  end: Offset(1.2, 1.2),
                                )
                          else
                            SizedBox(height: 8.h),
                        ],
                      ),
                    )
                    .animate(delay: Duration(milliseconds: 50 * index))
                    .fadeIn()
                    .scale(),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHEDULE CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScheduleCard(GroupModel group, int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: GlassCard(
        color: AppColors.darkSurface.withValues(alpha: 0.7),
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // Time Column
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: AppColors.accentVivid.withValues(alpha: 0.15),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(24.r),
                ),
                border: Border(
                  left: BorderSide(color: AppColors.glassBorderHighlight),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.accentVivid,
                    size: 24.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    group.startTime?.split(' ')[0] ?? '--:--',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentVivid,
                    ),
                  ),
                  if (group.endTime != null && group.endTime!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      group.endTime!.split(' ')[0],
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.accentVivid.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.courseName ?? group.groupName,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDisplay,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _buildInfoChip(Icons.groups_rounded, group.groupName),
                        _buildInfoChip(
                          Icons.people_alt_rounded,
                          '${group.currentStudents} طالب',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.forestPrimary,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.glassBorderHighlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.textMuted),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textDisplay,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: AppColors.darkSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.glassBorderHighlight),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  backgroundColor: AppColors.accentVivid,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.weekend_rounded,
              size: 64.sp,
              color: AppColors.infoPurple,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          SizedBox(height: 24.h),
          Text(
            'لا توجد حصص في هذا اليوم',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDisplay,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          SizedBox(height: 12.h),
          Text(
            'استمتع بوقتك! ☕',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  bool _hasSessionsOnDay(int dayNum) {
    // Determine if day has any schedules. Keep it simple and match original logic.
    final dayName = DayOfWeek.fromInt(dayNum).englishName.toLowerCase();
    for (var group in _allGroups) {
      if (group.schedules.any((s) => s.dayOfWeek.toLowerCase() == dayName)) {
        return true;
      }
      if (group.schedules.isEmpty && group.dayOfWeek == dayNum) return true;
    }
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER
// ═══════════════════════════════════════════════════════════════════════════

class _DayItem {
  final int index;
  final String name;
  final String shortName;

  const _DayItem({
    required this.index,
    required this.name,
    required this.shortName,
  });
}
