import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../auth/provider/auth_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../provider/teacher_provider.dart';
import '../../ai/provider/ai_provider.dart';
import '../../../shared/models/models.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/widgets/genius/glass_card.dart';
import '../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../core/widgets/genius/staggered_list_animator.dart';
import '../../ai/widgets/weakness_card.dart';
import '../../ai/services/ai_weakness_detector.dart';
import '../../notifications/presentation/screens/teacher_notifications_screen.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/premium_widgets.dart'
    show AvatarWithBorder, EmptyState;

/// 🟢 Teacher Home Screen - Radical Glassmorphism 2.0 Overhaul
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  List<GroupModel> _todayGroups = [];
  List<WeaknessInsight> _weaknessInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final centerProvider = context.read<CenterProvider>();
    final teacherProvider = context.read<TeacherProvider>();

    if (authProvider.teacherProfile != null &&
        centerProvider.availableCenters.isEmpty) {
      await centerProvider.loadTeacherCenters(authProvider.teacherProfile!.id);
    }

    if (authProvider.currentUser?.id != null &&
        teacherProvider.teacherProfile == null) {
      await teacherProvider.loadTeacherData(authProvider.currentUser!.id);
    }

    if (centerProvider.currentCenterId != null) {
      await teacherProvider.selectCenter(centerProvider.currentCenterId!);

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

      _todayGroups = teacherProvider.groups.where((g) {
        final todayValue = (todayDate.weekday + 1) % 7;
        if (g.dayOfWeek == todayValue) return true;
        return g.schedules.any(
          (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
        );
      }).toList();

      if (_todayGroups.isNotEmpty) {
        final firstGroupId = _todayGroups.first.id;
        final groupStudents = teacherProvider.getStudentsForGroup(firstGroupId);

        if (groupStudents.isNotEmpty) {
          final aiProvider = context.read<AIProvider>();
          final studentId = groupStudents.first['id'];

          final insights = await aiProvider.analyzeStudentWeaknesses(
            studentId: studentId,
            centerId: centerProvider.currentCenterId!,
          );
          if (mounted) setState(() => _weaknessInsights = insights);
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final centerProvider = context.watch<CenterProvider>();
    final teacherProvider = context.watch<TeacherProvider>();
    final teacher = authProvider.teacherProfile;
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.forestDeep, // Radical base color
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: AppColors.accentVivid,
        color: AppColors.darkSurface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ═══════════════════════════════════════════════════════════
            // APP BAR
            // ═══════════════════════════════════════════════════════════
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 20.w,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // First element in RTL renders on the FULL RIGHT
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DrawerMenuButton(
                        isTeacher: true,
                        color: AppColors.textDisplay,
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textDisplay,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TeacherNotificationsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Second element in RTL renders on the FULL LEFT
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'EdSentre',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDisplay,
                            ),
                      ),
                      SizedBox(width: 12.w),
                      Image.asset(
                        'assets/icons/app_icon.png',
                        height: 32.h,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════════════
            // MAIN CONTENT (Staggered Animations)
            // ═══════════════════════════════════════════════════════════
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverToBoxAdapter(
                child: StaggeredListAnimator(
                  isList:
                      false, // Ensure we build a Column instead of another ListView
                  children: [
                    SizedBox(height: 8.h),

                    // Welcome & Core Stats
                    _buildHeroDashboard(
                      user,
                      teacher,
                      teacherProvider,
                      centerProvider,
                    ),

                    SizedBox(height: 28.h),

                    // AI Seer Let
                    if (_weaknessInsights.isNotEmpty) ...[
                      _buildSectionLabel(
                        'رؤى الذكاء الاصطناعي',
                        Icons.psychology_rounded,
                        AppColors.infoPurple,
                      ),
                      SizedBox(height: 12.h),
                      _buildAISection(),
                      SizedBox(height: 28.h),
                    ],

                    // Today's Routine
                    _buildSectionLabel(
                      'حصص اليوم',
                      Icons.calendar_today_rounded,
                      AppColors.accentVivid,
                      onTapAction: () => context.go('/teacher/schedule'),
                    ),
                    SizedBox(height: 12.h),
                    _buildTodayClasses(),

                    SizedBox(height: 28.h),

                    // Navigation Matrix
                    _buildSectionLabel(
                      'الوصول السريع',
                      Icons.grid_view_rounded,
                      AppColors.warmAmber,
                    ),
                    SizedBox(height: 12.h),
                    _buildQuickActions(),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO DASHBOARD (Welcome + Stats merged for glassmorphism layout)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroDashboard(
    UserModel? user,
    TeacherModel? teacher,
    TeacherProvider teacherProvider,
    CenterProvider centerProvider,
  ) {
    return GlassCard(
      padding: EdgeInsets.all(20.w),
      color: AppColors.forestPrimary.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWithBorder(imageUrl: user?.avatarUrl, radius: 28),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      teacher?.displayName ?? user?.fullName ?? 'معلم',
                      style: Theme.of(context).textTheme.displaySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (centerProvider.hasMultipleCenters)
                _buildCenterDropdown(centerProvider)
              else if (centerProvider.currentCenter != null)
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.accentVivid,
                  size: 24.sp,
                ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              _buildMicroStat(
                'حصص اليوم',
                '${_todayGroups.length}',
                Icons.groups_rounded,
                AppColors.accentVivid,
              ),
              _buildMicroStat(
                'الطلاب',
                '${teacherProvider.statsTotalStudents}',
                Icons.school_rounded,
                AppColors.warmAmber,
              ),
              _buildMicroStat(
                'الرسائل',
                '${teacherProvider.dashboardStats['unread_messages_count'] ?? 0}',
                Icons.chat_bubble_rounded,
                AppColors.infoPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterDropdown(CenterProvider centerProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.forestDeep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.glassBorderHighlight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: centerProvider.currentCenterId,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textDisplay,
            size: 16.sp,
          ),
          dropdownColor: AppColors.forestPrimary,
          style: Theme.of(context).textTheme.labelLarge,
          items: centerProvider.availableCenters.map((center) {
            return DropdownMenuItem(value: center.id, child: Text(center.name));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              centerProvider.selectCenter(value);
              _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMicroStat(
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(height: 1.0),
          ),
          SizedBox(height: 2.h),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'مساء الخير 🌤️';
    return 'مساء الخير 🌙';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionLabel(
    String title,
    IconData icon,
    Color iconColor, {
    VoidCallback? onTapAction,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (onTapAction != null)
          GestureDetector(
            onTap: onTapAction,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.forestPrimary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'عرض الكل',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.accentMid),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAISection() {
    return SizedBox(
      height: 160.h,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _weaknessInsights.length,
        separatorBuilder: (c, i) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          return Hero(
            tag: 'ai_insight_${_weaknessInsights[index].subjectName}_$index',
            child: Material(
              color: Colors.transparent,
              child: WeaknessCard(
                insight: _weaknessInsights[index],
              ), // We'll update WeaknessCard next
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayClasses() {
    if (_isLoading) {
      return Column(
        children: List.generate(
          2,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: const ShimmerListItem(),
          ),
        ),
      );
    }

    if (_todayGroups.isEmpty) {
      return const EmptyState(
        icon: Icons.weekend_rounded,
        title: 'لا توجد حصص اليوم!',
        subtitle: 'استمتع بيومك أو استعد للحصص القادمة',
      );
    }

    return StaggeredListAnimator(
      isList: false,
      delayBase: 100.ms,
      children: _todayGroups.map((group) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildClassCard(group),
        );
      }).toList(),
    );
  }

  Widget _buildClassCard(GroupModel group) {
    return GlassCard(
      onTap: () => context.go('/teacher/groups/${group.id}'),
      color: AppColors.forestPrimary.withValues(alpha: 0.4),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Elegant Time Pillar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.forestDeep,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.glassBorderHighlight),
            ),
            child: Column(
              children: [
                Text(
                  _getTodayStartTime(group)?.split(' ')[0] ?? '--',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.accentVivid,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((_getTodayStartTime(group)?.split(' ').length ?? 0) >= 2)
                  Text(
                    _getTodayStartTime(group)!.split(' ')[1],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.courseName ?? group.groupName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 14.sp,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        group.groupName,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.groups_rounded,
                      size: 14.sp,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${group.currentStudents}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS GRID
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.groups_rounded,
        label: 'المجموعات',
        route: '/teacher/groups',
      ),
      _QuickAction(
        icon: Icons.fact_check_rounded,
        label: 'الحضور',
        route: '/teacher/attendance',
      ),
      _QuickAction(
        icon: Icons.assignment_rounded,
        label: 'الواجبات',
        route: '/teacher/assignments',
      ),
      _QuickAction(
        icon: Icons.people_alt_rounded,
        label: 'الطلاب',
        route: '/teacher/students',
      ),
      _QuickAction(
        icon: Icons.folder_copy_rounded,
        label: 'الملزمات',
        route: '/teacher/materials',
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        label: 'المناهج',
        route: '/teacher/curriculum',
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'التقارير',
        route: '/teacher/reports',
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_rounded,
        label: 'المالية',
        route: '/teacher/payments',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (12.w * 3)) / 4;
        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: actions.map((action) {
            return SizedBox(width: itemWidth, child: _buildActionItem(action));
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionItem(_QuickAction action) {
    return GestureDetector(
      onTap: () => context.go(action.route),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.forestPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderHighlight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(action.icon, color: AppColors.accentVivid, size: 24.sp),
          ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
          SizedBox(height: 8.h),
          Text(
            action.label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String? _getTodayStartTime(GroupModel group) {
    if (group.schedules.isEmpty) return group.startTime;
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
    try {
      final todaySchedule = group.schedules.firstWhere(
        (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
      );
      return todaySchedule.startTime.isNotEmpty
          ? todaySchedule.startTime
          : group.startTime;
    } catch (_) {
      return group.startTime;
    }
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
  });
}
