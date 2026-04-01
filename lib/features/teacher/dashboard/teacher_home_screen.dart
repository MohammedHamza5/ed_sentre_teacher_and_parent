import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../auth/provider/auth_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../provider/teacher_provider.dart';
import '../../ai/provider/ai_provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../shared/widgets/premium_plus_widgets.dart';
import '../../ai/widgets/weakness_card.dart';
import '../../ai/services/ai_weakness_detector.dart';
import '../../notifications/presentation/screens/teacher_notifications_screen.dart';
import '../../../shared/widgets/app_drawer.dart';

/// 🎨 Teacher Home Screen - Premium Dark Mode Design
/// A modern dashboard for teachers with smooth animations and glass effects
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
    // Set status bar style for dark mode
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final centerProvider = context.read<CenterProvider>();
    final teacherProvider = context.read<TeacherProvider>();

    // Load centers for teacher (if not loaded)
    if (authProvider.teacherProfile != null &&
        centerProvider.availableCenters.isEmpty) {
      await centerProvider.loadTeacherCenters(authProvider.teacherProfile!.id);
    }

    // Initialize TeacherProvider with user ID if not loaded
    if (authProvider.currentUser?.id != null &&
        teacherProvider.teacherProfile == null) {
      await teacherProvider.loadTeacherData(authProvider.currentUser!.id);
    }

    // Select center in TeacherProvider
    if (centerProvider.currentCenterId != null) {
      await teacherProvider.selectCenter(centerProvider.currentCenterId!);

      // Update today's groups from provider
      // Update today's groups from provider based on SCHEDULES
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
      // Note: DateTime.weekday is 1 (Mon) to 7 (Sun)
      final todayName = dayNames[todayDate.weekday - 1];

      _todayGroups = teacherProvider.groups.where((g) {
        // Check if primary day matches (fallback)
        final todayValue = (todayDate.weekday + 1) % 7;
        if (g.dayOfWeek == todayValue) return true;

        // Check schedules
        return g.schedules.any(
          (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
        );
      }).toList();

      debugPrint('📅 [TeacherHome] Today\'s Date: $todayDate ($todayName)');
      debugPrint(
        '📅 [TeacherHome] Total Groups: ${teacherProvider.groups.length}',
      );
      debugPrint(
        '📅 [TeacherHome] Today\'s Groups Filtered: ${_todayGroups.length}',
      );
      for (var g in _todayGroups) {
        debugPrint(
          '   - Group: ${g.groupName} (Schedules: ${g.schedules.length})',
        );
      }

      // AI Logic (The Seer)
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
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor, (removed to use Theme)
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ═══════════════════════════════════════════════════════════
            // APP BAR — Clean: max 2 icons
            // ═══════════════════════════════════════════════════════════
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Cairo',
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TeacherNotificationsScreen(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: DrawerMenuButton(
                    isTeacher: true,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            // ═══════════════════════════════════════════════════════════
            // MAIN CONTENT
            // ═══════════════════════════════════════════════════════════
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(height: 8.h),

                  // Teacher Welcome Card
                  _buildTeacherWelcomeCard(user, teacher, teacherProvider),

                  SizedBox(height: 16.h),

                  // Center Selector
                  if (centerProvider.hasMultipleCenters)
                    _buildCenterSelector(centerProvider)
                  else if (centerProvider.currentCenter != null)
                    _buildCurrentCenter(centerProvider),

                  SizedBox(height: 24.h),

                  // 1. Quick Stats
                  _buildQuickStats(teacherProvider),

                  SizedBox(height: 28.h),

                  // 2. AI Insights (The Seer)
                  if (_weaknessInsights.isNotEmpty) ...[
                    _buildAISection(),
                    SizedBox(height: 28.h),
                  ],

                  // 3. Today's Classes
                  PremiumSectionHeader(
                    title: 'حصص اليوم',
                    icon: Icons.calendar_today_rounded,
                    subtitle: 'جدول حصصك لهذا اليوم',
                    actions: [
                      HeaderAction(
                        icon: Icons.calendar_month_rounded,
                        onTap: () => context.go('/teacher/schedule'),
                        tooltip: 'الجدول الكامل',
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildTodayClasses(),

                  SizedBox(height: 28.h),

                  // 4. Quick Actions
                  PremiumSectionHeader(
                    title: 'الوصول السريع',
                    icon: Icons.grid_view_rounded,
                    subtitle: 'أدواتك المفضلة',
                  ),
                  SizedBox(height: 16.h),
                  _buildQuickActions(),

                  SizedBox(height: 100.h), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Welcome Card (teacher info moved here from AppBar)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTeacherWelcomeCard(
    UserModel? user,
    TeacherModel? teacher,
    TeacherProvider teacherProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AvatarWithBorder(imageUrl: user?.avatarUrl, radius: 28),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white70,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  teacher?.displayName ?? user?.fullName ?? 'معلم',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (teacherProvider.groups.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      '${teacherProvider.groups.length} مجموعة نشطة',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white60,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.school_rounded, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // (Header code removed to use SliverAppBar)

  Widget _buildCenterSelector(CenterProvider centerProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: centerProvider.currentCenterId,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
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
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildCurrentCenter(CenterProvider centerProvider) {
    return Row(
      children: [
        Icon(
          Icons.location_on_rounded,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          size: 18.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          centerProvider.currentCenter!.name,
          style: TextStyle(
            fontSize: 15.sp,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'مساء الخير 🌤️';
    return 'مساء الخير 🌙';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK STATS - Animated Stat Cards
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickStats(TeacherProvider teacherProvider) {
    final stats = teacherProvider.dashboardStats;
    final todayClassesCount = _todayGroups.length;
    // Use the getter we fixed in TeacherProvider which maps to 'students_count'
    final totalStudents = teacherProvider.statsTotalStudents;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PremiumStatCard(
              title: 'حصص اليوم',
              value: '$todayClassesCount',
              icon: Icons.groups_rounded,
              animationDelay: 0,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: PremiumStatCard(
              title: 'إجمالي الطلاب',
              value: '$totalStudents',
              icon: Icons.school_rounded,
              animationDelay: 100,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: PremiumStatCard(
              title: 'الرسائل',
              value: '${stats['unread_messages_count'] ?? 0}',
              icon: Icons.mark_chat_unread_rounded,
              animationDelay: 200,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI SECTION - The Seer
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAISection() {
    return Column(
      children: [
        PremiumSectionHeader(
          title: 'رؤى الذكاء الاصطناعي',
          icon: Icons.psychology_rounded,
          subtitle: 'تحليلات ذكية لأداء طلابك',
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 160.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _weaknessInsights.length,
            separatorBuilder: (c, i) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              return WeaknessCard(insight: _weaknessInsights[index]);
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TODAY'S CLASSES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTodayClasses() {
    if (_isLoading) {
      return Column(
        children: List.generate(
          2,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ShimmerLoading(height: 100.h, borderRadius: 20.r),
          ),
        ),
      );
    }

    if (_todayGroups.isEmpty) {
      return EmptyState(
        icon: Icons.weekend_rounded,
        title: 'لا توجد حصص اليوم!',
        subtitle: 'استمتع بيومك أو استعد للحصص القادمة',
      );
    }

    return Column(
      children: _todayGroups.asMap().entries.map((entry) {
        final index = entry.key;
        final group = entry.value;
        return _buildClassCard(group, index);
      }).toList(),
    );
  }

  Widget _buildClassCard(GroupModel group, int index) {
    return Card(
          margin: EdgeInsets.only(bottom: 14.h),
          child: InkWell(
            onTap: () => context.go('/teacher/groups/${group.id}'),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Time Pillar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getTodayStartTime(group)?.split(' ')[0] ?? '--',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if ((_getTodayStartTime(group)?.split(' ').length ??
                                0) >=
                            2)
                          Text(
                            _getTodayStartTime(group)!.split(' ')[1],
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                            Expanded(
                              child: _buildClassInfo(
                                Icons.class_outlined,
                                group.groupName,
                                isFlexible: true,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _buildClassInfo(
                              Icons.people_outline,
                              '${group.currentStudents}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideY(begin: 0.1);
  }

  Widget _buildClassInfo(
    IconData icon,
    String text, {
    bool isFlexible = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.w),
        if (isFlexible)
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
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
        final itemWidth = (constraints.maxWidth - (12.w * 2)) / 3;
        final itemHeight = itemWidth / 0.85;
        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: actions.asMap().entries.map((entry) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _buildActionItem(entry.value, entry.key),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionItem(_QuickAction action, int index) {
    return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => context.go(action.route),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index))
        .scale(begin: const Offset(0.9, 0.9));
  }

  String? _getTodayStartTime(GroupModel group) {
    if (group.schedules.isEmpty) {
      debugPrint(
        '⏰ [TeacherHome] Group ${group.groupName} has NO schedules. Using fallback: ${group.startTime}',
      );
      return group.startTime;
    }

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
      final result = todaySchedule.startTime.isNotEmpty
          ? todaySchedule.startTime
          : group.startTime;
      debugPrint(
        '⏰ [TeacherHome] Found schedule for ${group.groupName} on $todayName: $result',
      );
      return result;
    } catch (_) {
      debugPrint(
        '⏰ [TeacherHome] No specific schedule for ${group.groupName} on $todayName. Using fallback.',
      );
      return group.startTime;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASS
// ═══════════════════════════════════════════════════════════════════════════

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
