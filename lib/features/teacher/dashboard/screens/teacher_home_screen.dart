import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../auth/provider/auth_provider.dart';
import '../../../../core/providers/center_provider.dart';
import '../../provider/teacher_provider.dart';
import '../../../ai/provider/ai_provider.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';
import '../../../../core/widgets/genius/staggered_list_animator.dart';
import '../../../ai/widgets/weakness_card.dart';
import '../../../ai/services/ai_weakness_detector.dart';
import '../../../../shared/widgets/app_drawer.dart';

// 🟢 Modular Sub-Widgets (Section 1.2 & 2.2 Complexity Compliance)
import '../widgets/dashboard_section_label.dart';
import '../widgets/teacher_hero_dashboard.dart';
import '../widgets/teacher_quick_actions.dart';
import '../widgets/teacher_today_classes.dart';

/// 🟢 Teacher Home Screen - Decomposed, Adaptive Light/Dark Mode, High-Contrast Power Operator Identity
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
    final aiProvider = context.read<AIProvider>();

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
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
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
          final studentId = groupStudents.first['id'];

          Future.microtask(() async {
            try {
              final insights = await aiProvider.analyzeStudentWeaknesses(
                studentId: studentId,
                centerId: centerProvider.currentCenterId!,
              );
              if (mounted) setState(() => _weaknessInsights = insights);
            } catch (e) {
              debugPrint('AI insight load error: $e');
            }
          });
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
      backgroundColor: context.themeBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: context.teacherAccent,
        backgroundColor: context.themeCard,
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
              backgroundColor: context.themeBackground,
              automaticallyImplyLeading: false,
              titleSpacing: 20.w,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? AppColors.navyCard : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            height: 28.h,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.school_rounded,
                              color: context.teacherAccent,
                              size: 28.sp,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapW8,
                      Text(
                        'إدسنتر',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: context.teacherAccent,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: AppSpacing.touchTargetMin, minHeight: AppSpacing.touchTargetMin),
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: context.themeTextPrimary,
                          size: 26.sp,
                        ),
                        onPressed: () => context.push('/teacher/notifications'),
                      ),
                      AppSpacing.gapW8,
                      const DrawerMenuButton(isTeacher: true),
                    ],
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════════════
            // MAIN CONTENT (Decomposed & Accelerated)
            // ═══════════════════════════════════════════════════════════
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverToBoxAdapter(
                child: StaggeredListAnimator(
                  isList: false,
                  children: [
                    AppSpacing.gapH12,

                    // 1. Hero Dashboard (Power Operator Identity)
                    TeacherHeroDashboard(
                      user: user,
                      teacher: teacher,
                      teacherProvider: teacherProvider,
                      centerProvider: centerProvider,
                      todayGroupsCount: _todayGroups.length,
                      onCenterChanged: _loadData,
                    ),

                    AppSpacing.gapH24,

                    // 2. AI Recommendation Section
                    if (_weaknessInsights.isNotEmpty) ...[
                      const DashboardSectionLabel(
                        title: 'رؤى الذكاء الاصطناعي',
                        icon: Icons.psychology_outlined,
                        iconColor: AppColors.teal,
                      ),
                      AppSpacing.gapH12,
                      _buildAISection(),
                      AppSpacing.gapH24,
                    ],

                    // 3. Today's Classes (Powered by CardShimmerSkeleton)
                    DashboardSectionLabel(
                      title: 'حصص اليوم',
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppColors.electric,
                      onTapAction: () => context.go('/teacher/schedule'),
                    ),
                    AppSpacing.gapH12,
                    TeacherTodayClasses(
                      isLoading: _isLoading,
                      todayGroups: _todayGroups,
                    ),

                    AppSpacing.gapH24,

                    // 4. Quick Actions Grid (Touch Safe)
                    const DashboardSectionLabel(
                      title: 'الوصول السريع',
                      icon: Icons.grid_view_rounded,
                      iconColor: AppColors.gold,
                    ),
                    AppSpacing.gapH12,
                    const TeacherQuickActions(),

                    AppSpacing.gapH32,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        separatorBuilder: (c, i) => AppSpacing.gapW12,
        itemBuilder: (context, index) {
          return Hero(
            tag: 'ai_insight_${_weaknessInsights[index].subjectName}_$index',
            child: Material(
              color: Colors.transparent,
              child: WeaknessCard(
                insight: _weaknessInsights[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

