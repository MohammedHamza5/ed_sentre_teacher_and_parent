import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/provider/auth_provider.dart';
import '../provider/parent_provider.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/widgets/genius/glass_card.dart';
import '../../../core/widgets/genius/staggered_list_animator.dart';
import '../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../shared/widgets/app_drawer.dart';

/// 🟢 Parent Home Screen - Radical Glassmorphism 2.0 Overhaul
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final parentProvider = context.read<ParentProvider>();

    if (parentProvider.children.isEmpty && authProvider.currentUser != null) {
      await parentProvider.loadChildren(authProvider.currentUser!.id);
    }

    if (parentProvider.children.isNotEmpty &&
        parentProvider.selectedChild == null) {
      await parentProvider.selectChild(parentProvider.children.first.id);
    }

    if (!mounted) return;

    if (parentProvider.selectedChild != null &&
        parentProvider.selectedCenter != null) {
      _dashboardData = await parentProvider.getChildDashboard();
      final activities = await parentProvider.getRecentActivity();
      if (mounted) setState(() => _recentActivities = activities);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final parentProvider = context.watch<ParentProvider>();
    final authProvider = context.watch<AuthProvider>();
    final selectedChild = parentProvider.selectedChild;

    return Scaffold(
      backgroundColor: AppColors.forestDeep, // Radical base color
      body: _isLoading
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ShimmerListItem(),
                    SizedBox(height: 16.h),
                    const ShimmerListItem(),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              backgroundColor: AppColors.accentVivid,
              color: AppColors.darkSurface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. PREMIUM GLASS HEADER
                  SliverToBoxAdapter(
                    child: GlassCard(
                      borderRadius: 32.r,
                      color: AppColors.forestPrimary.withValues(alpha: 0.8),
                      padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 30.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Greeting + Actions
                          // Top Nav Row: Logo + Drawer Menu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // First element in RTL renders on the FULL RIGHT
                              Row(
                                children: [
                                  const DrawerMenuButton(
                                    isTeacher: false,
                                    color: AppColors.textDisplay,
                                  ),
                                  SizedBox(width: 8.w),
                                  _buildHeaderIcon(
                                    Icons.person_outline,
                                    () => context.push('/parent/profile'),
                                  ),
                                  SizedBox(width: 8.w),
                                  _buildHeaderIcon(
                                    Icons.notifications_outlined,
                                    () => context.push('/parent/notifications'),
                                  ),
                                ],
                              ),
                              // Second element in RTL renders on the FULL LEFT
                              Row(
                                children: [
                                  Text(
                                    'EdSentre',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDisplay,
                                        ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Image.asset(
                                    'assets/icons/app_icon.png',
                                    height: 28.h,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          
                          // Greeting Row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً بك 👋',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                authProvider.currentUser?.fullName ??
                                    'ولي الأمر',
                                style: Theme.of(
                                  context,
                                ).textTheme.displaySmall,
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // Child Selector Pills
                          if (parentProvider.children.length > 1)
                            SizedBox(
                              height: 48.h,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: parentProvider.children.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 12.w),
                                itemBuilder: (context, index) {
                                  final child = parentProvider.children[index];
                                  final isSelected =
                                      child.id == selectedChild?.id;
                                  return GestureDetector(
                                    onTap: () async {
                                      await parentProvider.selectChild(
                                        child.id,
                                      );
                                      if (mounted) _loadData();
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 12.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accentVivid
                                            : AppColors.darkSurface.withValues(
                                                alpha: 0.5,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          24.r,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accentVivid
                                              : AppColors.glassBorderHighlight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          child.fullName ?? 'طالب',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: isSelected
                                                    ? AppColors.forestDeep
                                                    : AppColors.textMain,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ).animate().scale(
                                    delay: (index * 50).ms,
                                    curve: Curves.easeOutBack,
                                  );
                                },
                              ),
                            ),

                          // Center Selector
                          if (parentProvider.hasMultipleCenters) ...[
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.forestDeep.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppColors.glassBorderHighlight,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    color: AppColors.textDisplay,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: parentProvider.selectedCenterId,
                                      dropdownColor: AppColors.forestPrimary,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.textDisplay,
                                        size: 20.sp,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                      items: parentProvider.childCenters.map((
                                        center,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: center.centerId,
                                          child: Text(center.centerName),
                                        );
                                      }).toList(),
                                      onChanged: (centerId) {
                                        if (centerId != null) {
                                          parentProvider.selectCenter(centerId);
                                          if (mounted) _loadData();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 2. MAIN CONTENT (Staggered Animations)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    sliver: SliverToBoxAdapter(
                      child: StaggeredListAnimator(
                        isList: false,
                        children: [
                          // STATS ROW
                          SizedBox(height: 30.h),
                          _buildStatsRow(),

                          SizedBox(height: 28.h),

                          // QUICK ACTIONS
                          _buildSectionLabel(
                            'الخدمات',
                            Icons.grid_view_rounded,
                            AppColors.warmAmber,
                          ),
                          SizedBox(height: 16.h),
                          _buildQuickActionsGrid(),

                          SizedBox(height: 28.h),

                          // RECENT ACTIVITY
                          _buildSectionLabel(
                            'آخر التحديثات',
                            Icons.history_rounded,
                            AppColors.infoPurple,
                          ),
                          SizedBox(height: 16.h),
                          _buildRecentActivity(),

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

  Widget _buildSectionLabel(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.forestDeep.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorderHighlight),
        ),
        child: Icon(icon, color: AppColors.textDisplay, size: 24.sp),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _dashboardData['stats'] ?? {};
    final payment = _dashboardData['payment'] ?? {};

    final attendanceRate = stats['attendance_rate'] ?? 0;
    final averageGrade = stats['average_grade'] ?? 0;
    final totalDue = payment['total_due'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'الحضور',
            '$attendanceRate%',
            Icons.check_circle_outline,
            AppColors.accentVivid,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'الدرجات',
            averageGrade.toStringAsFixed(1),
            Icons.emoji_events_outlined,
            AppColors.warmAmber,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'المستحقات',
            '${totalDue.toStringAsFixed(0)}',
            Icons.account_balance_wallet_outlined,
            totalDue > 0 ? AppColors.errorRed : AppColors.accentVivid,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return GlassCard(
      padding: EdgeInsets.all(16.w),
      color: AppColors.forestPrimary.withValues(alpha: 0.4),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDisplay,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'icon': Icons.fact_check_outlined,
        'label': 'الحضور',
        'color': AppColors.accentVivid,
        'route': '/parent/attendance',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'الجدول',
        'color': AppColors.infoPurple,
        'route': '/parent/schedule',
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'الدرجات',
        'color': AppColors.warmAmber,
        'route': '/parent/grades',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'المدفوعات',
        'color': AppColors.errorRed,
        'route': '/parent/payments',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'الرسائل',
        'color': AppColors.accentMid,
        'route': '/parent/messages',
      },
      {
        'icon': Icons.person_outline,
        'label': 'حسابي',
        'color': AppColors.textDisplay,
        'route': '/parent/profile',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (16.w * 2)) / 3;
        return Wrap(
          spacing: 16.w,
          runSpacing: 16.h,
          children: actions.asMap().entries.map((entry) {
            final action = entry.value;
            return SizedBox(
              width: itemWidth,
              child: _buildActionCard(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: () => context.push(action['route'] as String),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        color: AppColors.forestPrimary.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 26.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms);
  }

  Widget _buildRecentActivity() {
    if (_recentActivities.isEmpty) {
      return GlassCard(
        padding: EdgeInsets.all(32.w),
        color: AppColors.darkSurface.withValues(alpha: 0.5),
        child: Column(
          children: [
            Icon(Icons.history, size: 48.sp, color: AppColors.textMuted),
            SizedBox(height: 16.h),
            Text(
              'لا توجد تحديثات حديثة',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentActivities.asMap().entries.map((entry) {
        final activity = entry.value;
        final isAttendance = activity['type'] == 'attendance';
        final color = isAttendance
            ? (activity['status'] == 'present'
                  ? AppColors.accentVivid
                  : AppColors.errorRed)
            : AppColors.warmAmber;

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GlassCard(
            color: AppColors.forestPrimary.withValues(alpha: 0.4),
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    isAttendance
                        ? Icons.fact_check_outlined
                        : Icons.star_outline,
                    color: color,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        activity['subtitle'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.glassBorderHighlight),
                  ),
                  child: Text(
                    timeago.format(activity['date'] as DateTime, locale: 'ar'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
