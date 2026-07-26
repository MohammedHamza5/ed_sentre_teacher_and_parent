import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../auth/provider/auth_provider.dart';
import '../../provider/parent_provider.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/staggered_list_animator.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../widgets/parent_stats_section.dart';
import '../widgets/parent_quick_actions_grid.dart';
import '../widgets/parent_recent_activity_list.dart';


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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Radical base color
      body: _isLoading
          ? Padding(
              padding: EdgeInsets.all(20.w),
              child: const CardShimmerSkeleton(itemCount: 4),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              backgroundColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(context).colorScheme.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. PREMIUM GLASS HEADER
                  SliverToBoxAdapter(
                    child: GlassCard(
                      borderRadius: 32.r,
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                      padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 30.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Greeting + Actions
                          // Top Nav Row: Logo + Drawer Menu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // First element in RTL renders on the RIGHT (RTL Start: Logo & Brand Name)
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.asset(
                                        'assets/icons/app_icon.png',
                                        height: 26.h,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'EdSentre',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                              // Second element in RTL renders on the LEFT (RTL End: Action Buttons & Drawer)
                              Row(
                                children: [
                                  _buildHeaderIcon(
                                    Icons.notifications_outlined,
                                    () => context.push('/parent/notifications'),
                                  ),
                                  SizedBox(width: 8.w),
                                  _buildHeaderIcon(
                                    Icons.person_outline,
                                    () => context.push('/parent/profile'),
                                  ),
                                  SizedBox(width: 8.w),
                                  DrawerMenuButton(
                                    isTeacher: false,
                                    color: Theme.of(context).colorScheme.onSurface,
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
                                    ?.copyWith(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
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
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.surface.withValues(
                                                alpha: 0.5,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          24.r,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
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
                                                    ? Theme.of(context).scaffoldBackgroundColor
                                                    : Theme.of(context).colorScheme.onSurface,
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
                                color: Theme.of(context).scaffoldBackgroundColor.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: parentProvider.selectedCenterId,
                                      dropdownColor: Theme.of(context).colorScheme.surface,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Theme.of(context).colorScheme.onSurface,
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
                          SizedBox(height: 24.h),
                          ParentStatsSection(dashboardData: _dashboardData),

                          SizedBox(height: 28.h),

                          // QUICK ACTIONS
                          _buildSectionLabel(
                            'الخدمات',
                            Icons.grid_view_rounded,
                            AppColors.parentPrimary,
                          ),
                          SizedBox(height: 16.h),
                          const ParentQuickActionsGrid(),

                          SizedBox(height: 28.h),

                          // RECENT ACTIVITY
                          _buildSectionLabel(
                            'آخر التحديثات',
                            Icons.history_rounded,
                            AppColors.warningAmber,
                          ),
                          SizedBox(height: 16.h),
                          ParentRecentActivityList(recentActivities: _recentActivities),

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
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24.sp),
      ),
    );
  }
}
