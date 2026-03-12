import 'package:flutter/material.dart';
import '../../../shared/widgets/app_drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// Removed unused AppColors
import '../../auth/provider/auth_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/group_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../shared/widgets/premium_plus_widgets.dart';

/// 🎨 Teacher Schedule Screen - Premium Dark Mode Design
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
    _DayItem(index: 0, name: 'السبت', shortName: 'س'),
    _DayItem(index: 1, name: 'الأحد', shortName: 'ح'),
    _DayItem(index: 2, name: 'الاثنين', shortName: 'ث'),
    _DayItem(index: 3, name: 'الثلاثاء', shortName: 'ث'),
    _DayItem(index: 4, name: 'الأربعاء', shortName: 'ر'),
    _DayItem(index: 5, name: 'الخميس', shortName: 'خ'),
    _DayItem(index: 6, name: 'الجمعة', shortName: 'ج'),
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
      // 1. Check for specific schedule on this day
      final schedulesOnDay = group.schedules
          .where((s) => s.dayOfWeek.toLowerCase() == selectedDayName)
          .toList();

      if (schedulesOnDay.isNotEmpty) {
        // Create a display group for EACH schedule (in case of multiple sessions/day)
        for (var schedule in schedulesOnDay) {
          filtered.add(
            group.copyWith(
              startTime: schedule.startTime,
              endTime: schedule.endTime,
              dayOfWeek: selectedDayEnum.value, // Update day to match
            ),
          );
        }
      }
      // 2. Fallback: If no schedules list, check legacy day_of_week
      else if (group.schedules.isEmpty &&
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'جدول الحصص',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _loadSchedule,
          ),
          const DrawerMenuButton(isTeacher: true),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedule,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
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

  // Header replaced by AppBar

  // ═══════════════════════════════════════════════════════════════════════════
  // DAY SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDaySelector() {
    return SizedBox(
      height: 95.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (c, i) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day.index == _selectedDayIndex;
          final hasSession = _hasSessionsOnDay(day.index);

          return Container(
            width: 68.w,
            margin: EdgeInsets.symmetric(vertical: 4.h),
            child: GlassMorphismCard(
              onTap: () {
                setState(() {
                  _selectedDayIndex = day.index;
                  _filterGroupsByDay();
                });
              },
              padding: EdgeInsets.symmetric(vertical: 12.h),
              borderRadius: 20.r,
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).cardTheme.color,
              hasNeonBorder: isSelected,
              neonColor: Theme.of(context).colorScheme.primary,
              animationDelay: 50 * index,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.name,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13.sp,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (hasSession)
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    )
                  else
                    SizedBox(height: 6.w),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHEDULE CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScheduleCard(GroupModel group, int index) {
    return GlassMorphismCard(
      margin: EdgeInsets.only(bottom: 16.h),
      hasNeonBorder: true,
      neonColor: Theme.of(context).colorScheme.primary,
      animationDelay: 100 * index,
      child: Row(
        children: [
          // Time Column
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
                SizedBox(height: 6.h),
                Text(
                  group.startTime?.split(' ')[0] ?? '--:--',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (group.endTime != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    group.endTime!.split(' ')[0],
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 16.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.courseName ?? group.groupName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Flexible(
                      child: _buildInfoChip(
                        Icons.groups_rounded,
                        group.groupName,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _buildInfoChip(
                      Icons.people_outline_rounded,
                      '${group.currentStudents} طالب',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
            child: ShimmerLoading(height: 100.h, borderRadius: 20.r),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.weekend_rounded,
      title: 'لا توجد حصص في هذا اليوم',
      subtitle: 'استمتع بوقتك! ☕',
    );
  }

  bool _hasSessionsOnDay(int dayNum) {
    return _allGroups.any((g) => g.dayOfWeek == dayNum);
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
