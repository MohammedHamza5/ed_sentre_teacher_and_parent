import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/provider/auth_provider.dart';
import '../provider/parent_provider.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _recentActivities = [];

  // Premium color palette
  static const _gradientStart = Color(0xFF6366F1); // Indigo
  static const _gradientEnd = Color(0xFF8B5CF6); // Purple
  static const _accentOrange = Color(0xFFFF9500);
  static const _accentGreen = Color(0xFF34C759);
  static const _accentBlue = Color(0xFF007AFF);
  static const _accentRed = Color(0xFFFF3B30);
  static const _accentTeal = Color(0xFF5AC8FA);

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
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, _gradientEnd],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // 1. PREMIUM GRADIENT HEADER
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_gradientStart, _gradientEnd],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 50.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Greeting + Actions
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'مرحباً بك 👋',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        authProvider.currentUser?.fullName ??
                                            'ولي الأمر',
                                        style: TextStyle(
                                          fontSize: 26.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _buildHeaderIcon(
                                        Icons.notifications_outlined,
                                        () => context.push(
                                          '/parent/notifications',
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      _buildHeaderIcon(
                                        Icons.person_outline,
                                        () => context.push('/parent/profile'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 24.h),

                              // Child Selector Pills
                              if (parentProvider.children.length > 1)
                                SizedBox(
                                  height: 40.h,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: parentProvider.children.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(width: 10.w),
                                    itemBuilder: (context, index) {
                                      final child =
                                          parentProvider.children[index];
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
                                            horizontal: 16.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                          ),
                                          child: Text(
                                            child.fullName ?? 'طالب',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? _gradientStart
                                                  : Colors.white,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ).animate().scale(delay: (index * 50).ms);
                                    },
                                  ),
                                ),

                              // Center Selector (if child has multiple centers)
                              if (parentProvider.hasMultipleCenters) ...[
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        color: Colors.white,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      DropdownButton<String>(
                                        value: parentProvider.selectedCenterId,
                                        dropdownColor: _gradientStart,
                                        underline: const SizedBox(),
                                        icon: Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                        ),
                                        items: parentProvider.childCenters.map((
                                          center,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: center.centerId,
                                            child: Text(
                                              center.centerName,
                                              style: TextStyle(fontSize: 14.sp),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (centerId) {
                                          if (centerId != null) {
                                            parentProvider.selectCenter(
                                              centerId,
                                            );
                                            if (mounted) _loadData();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. STATS CARDS
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 30.h, 16.w, 16.h),
                    sliver: SliverToBoxAdapter(child: _buildStatsRow()),
                  ),

                  // 3. QUICK ACTIONS - Colorful Grid
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الخدمات',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _buildQuickActionsGrid(),
                        ],
                      ),
                    ),
                  ),

                  // 4. RECENT ACTIVITY
                  SliverPadding(
                    padding: EdgeInsets.all(16.w),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'آخر التحديثات',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: Colors.white, size: 24.sp),
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
            _accentGreen,
            const Color(0xFFDCFCE7),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'الدرجات',
            averageGrade.toStringAsFixed(1),
            Icons.emoji_events_outlined,
            _accentOrange,
            const Color(0xFFFEF3C7),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'المستحقات',
            '${totalDue.toStringAsFixed(0)}',
            Icons.account_balance_wallet_outlined,
            totalDue > 0 ? _accentRed : _accentGreen,
            totalDue > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280)),
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
        'color': _accentGreen,
        'route': '/parent/attendance',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'الجدول',
        'color': _accentBlue,
        'route': '/parent/schedule',
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'الدرجات',
        'color': _accentOrange,
        'route': '/parent/grades',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'المدفوعات',
        'color': _accentRed,
        'route': '/parent/payments',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'الرسائل',
        'color': _accentTeal,
        'route': '/parent/messages',
      },
      {
        'icon': Icons.person_outline,
        'label': 'حسابي',
        'color': _gradientStart,
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
            final index = entry.key;
            final action = entry.value;
            return SizedBox(
              width: itemWidth,
              height: itemWidth, // aspectRatio 1.0
              child: _buildActionCard(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: () => context.push(action['route'] as String),
                delay: index * 80,
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
    int delay = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().scale(
      delay: delay.ms,
      duration: 300.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildRecentActivity() {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 40.sp,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد تحديثات حديثة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentActivities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final isAttendance = activity['type'] == 'attendance';
        final color = isAttendance
            ? (activity['status'] == 'present' ? _accentGreen : _accentRed)
            : _accentOrange;

        final itemWidget = Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isAttendance ? Icons.fact_check_outlined : Icons.star_outline,
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
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      activity['subtitle'] ?? '',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  timeago.format(activity['date'] as DateTime, locale: 'ar'),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        );
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _recentActivities.length - 1 ? 12.h : 0,
          ),
          child: itemWidget
              .animate()
              .fadeIn(delay: (index * 50).ms)
              .slideX(begin: 0.05),
        );
      }).toList(),
    );
  }
}
