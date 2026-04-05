/// Teacher Payments & Financials Screen
/// شاشة المالية والرواتب للمعلم
/// Shows per-group revenue, teacher share vs center share, and salary breakdown
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Removed AppColors import
import '../../../shared/widgets/premium_widgets.dart';
import '../provider/teacher_provider.dart';

class TeacherPaymentsScreen extends StatefulWidget {
  const TeacherPaymentsScreen({super.key});

  @override
  State<TeacherPaymentsScreen> createState() => _TeacherPaymentsScreenState();
}

class _TeacherPaymentsScreenState extends State<TeacherPaymentsScreen> {
  Map<String, dynamic> _salaryData = {};
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final teacherProvider = context.read<TeacherProvider>();
      final data = await teacherProvider.getSalaryBreakdown(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) {
        setState(() {
          _salaryData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [TeacherPayments] Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader()),

          // Content
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: 16.h),
                _buildMonthSelector(),
                SizedBox(height: 24.h),

                if (_isLoading)
                  _buildLoadingState()
                else if (_salaryData.isEmpty)
                  _buildEmptyState()
                else ...[
                  // Summary Cards
                  _buildSummaryCards(),
                  SizedBox(height: 28.h),

                  // Per-Group Breakdown
                  _buildGroupBreakdown(),
                  SizedBox(height: 28.h),

                  // Bonuses & Deductions
                  _buildBonusesDeductions(),
                  SizedBox(height: 28.h),

                  // Salary Status
                  _buildSalaryStatus(),
                ],

                SizedBox(height: 100.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => context.go('/teacher'),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ).animate().fadeIn().scale(),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المالية والرواتب',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ).animate().fadeIn().slideX(begin: 0.2),
                          SizedBox(height: 4.h),
                          Text(
                            _salaryData['teacher_name'] ?? 'تفاصيل مالية',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.2),
                        ],
                      ),
                    ),
                    // Money icon
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ).animate(delay: 200.ms).fadeIn().scale(),
                    SizedBox(width: 8.w),
                    const SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MONTH SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMonthSelector() {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return PremiumCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month
          _buildMonthArrow(
            Icons.chevron_right_rounded,
            onTap: () {
              setState(() {
                if (_selectedMonth == 1) {
                  _selectedMonth = 12;
                  _selectedYear--;
                } else {
                  _selectedMonth--;
                }
              });
              _loadData();
            },
          ),

          // Current month display
          Column(
            children: [
              Text(
                months[_selectedMonth - 1],
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$_selectedYear',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          // Next month
          _buildMonthArrow(
            Icons.chevron_left_rounded,
            onTap: () {
              setState(() {
                if (_selectedMonth == 12) {
                  _selectedMonth = 1;
                  _selectedYear++;
                } else {
                  _selectedMonth++;
                }
              });
              _loadData();
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildMonthArrow(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 24.sp,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryCards() {
    final grossPreview =
        (_salaryData['gross_preview'] as num?)?.toDouble() ?? 0;
    final salaryType = _salaryData['salary_type'] ?? 'fixed';
    final percentage =
        (_salaryData['salary_percentage'] as num?)?.toDouble() ?? 0;

    // Calculate total collected across all groups
    double totalCollected = 0;
    double centerShare = 0;
    final percentageItems = _salaryData['percentage_items'] as List? ?? [];
    for (var item in percentageItems) {
      totalCollected += (item['collected'] as num?)?.toDouble() ?? 0;
      centerShare += (item['center_share'] as num?)?.toDouble() ?? 0;
    }

    return Column(
      children: [
        // Main Salary Card - Hero
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'إجمالي نصيبك',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${_formatCurrency(grossPreview)} ج.م',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  salaryType == 'percentage'
                      ? 'نسبة ${percentage.toInt()}%'
                      : salaryType == 'per_session'
                      ? 'بالحصة'
                      : 'راتب ثابت',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

        SizedBox(height: 16.h),

        // Secondary Stats
        if (salaryType == 'percentage') ...[
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'إجمالي التحصيل',
                  value: _formatCurrency(totalCollected),
                  icon: Icons.payments_rounded,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  title: 'نصيب السنتر',
                  value: _formatCurrency(centerShare),
                  icon: Icons.account_balance_rounded,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.error,
                      Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: Colors.white, size: 18.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$value ج.م',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP BREAKDOWN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGroupBreakdown() {
    final salaryType = _salaryData['salary_type'] ?? 'fixed';
    final items = salaryType == 'percentage'
        ? (_salaryData['percentage_items'] as List? ?? [])
        : salaryType == 'per_session'
        ? (_salaryData['sessions'] as List? ?? [])
        : [];

    if (items.isEmpty && salaryType == 'fixed') {
      // Fixed salary - show single card
      return _buildFixedSalarySection();
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SectionHeader(title: 'تفاصيل المجموعات', icon: Icons.groups_rounded),
        SizedBox(height: 16.h),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;

          if (salaryType == 'percentage') {
            return _buildPercentageGroupCard(item, index);
          } else {
            return _buildSessionGroupCard(item, index);
          }
        }),
      ],
    );
  }

  Widget _buildFixedSalarySection() {
    final baseSalary = (_salaryData['base_salary'] as num?)?.toDouble() ?? 0;
    return Column(
      children: [
        SectionHeader(title: 'تفاصيل الراتب', icon: Icons.receipt_long_rounded),
        SizedBox(height: 16.h),
        PremiumCard(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'راتب ثابت شهري',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'يُصرف شهرياً بغض النظر عن التحصيل',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatCurrency(baseSalary)} ج.م',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: 0.1),
      ],
    );
  }

  Widget _buildPercentageGroupCard(Map<String, dynamic> item, int index) {
    final groupName = item['group'] ?? 'مجموعة';
    final students = (item['students'] as num?)?.toInt() ?? 0;
    final collected = (item['collected'] as num?)?.toDouble() ?? 0;
    final percentage = (item['percentage'] as num?)?.toDouble() ?? 0;
    final teacherTotal = (item['total'] as num?)?.toDouble() ?? 0;
    final centerTotal = (item['center_share'] as num?)?.toDouble() ?? 0;

    return PremiumCard(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$students طالب',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Revenue Progress Bar
              _buildRevenueBar(teacherTotal, centerTotal),

              SizedBox(height: 16.h),

              // Details Row
              Row(
                children: [
                  _buildDetailChip(
                    'المحصّل',
                    '${_formatCurrency(collected)} ج.م',
                    Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  _buildDetailChip(
                    'نصيبك (${percentage.toInt()}%)',
                    '${_formatCurrency(teacherTotal)} ج.م',
                    Colors.green,
                  ),
                  SizedBox(width: 8.w),
                  _buildDetailChip(
                    'السنتر',
                    '${_formatCurrency(centerTotal)} ج.م',
                    Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.1);
  }

  Widget _buildRevenueBar(double teacherShare, double centerShare) {
    final total = teacherShare + centerShare;
    final teacherRatio = total > 0 ? teacherShare / total : 0.0;

    return Column(
      children: [
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  'نصيبك',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  'السنتر',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // Progress
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: SizedBox(
            height: 10.h,
            child: Row(
              children: [
                Expanded(
                  flex: (teacherRatio * 100).toInt().clamp(1, 99),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.green),
                  ),
                ),
                Expanded(
                  flex: ((1 - teacherRatio) * 100).toInt().clamp(1, 99),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionGroupCard(Map<String, dynamic> item, int index) {
    final groupName = item['group'] ?? 'مجموعة';
    final count = (item['count'] as num?)?.toInt() ?? 0;
    final rate = (item['rate'] as num?)?.toDouble() ?? 0;
    final total = (item['total'] as num?)?.toDouble() ?? 0;

    return PremiumCard(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'حصة',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withValues(alpha: 0.85),
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
                      groupName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'سعر الحصة: ${_formatCurrency(rate)} ج.م',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatCurrency(total)} ج.م',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.1);
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BONUSES & DEDUCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBonusesDeductions() {
    final bonuses = _salaryData['bonuses'] as List? ?? [];
    final deductions = _salaryData['deductions'] as List? ?? [];

    if (bonuses.isEmpty && deductions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(title: 'المكافآت والخصومات', icon: Icons.tune_rounded),
        SizedBox(height: 16.h),
        ...bonuses.map(
          (b) => _buildAdjustmentTile(
            b['description'] ?? 'مكافأة',
            (b['amount'] as num?)?.toDouble() ?? 0,
            isBonus: true,
          ),
        ),
        ...deductions.map(
          (d) => _buildAdjustmentTile(
            d['description'] ?? 'خصم',
            (d['amount'] as num?)?.toDouble() ?? 0,
            isBonus: false,
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentTile(
    String description,
    double amount, {
    required bool isBonus,
  }) {
    return PremiumCard(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color:
                  (isBonus ? Colors.green : Theme.of(context).colorScheme.error)
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isBonus
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isBonus
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${isBonus ? '+' : '-'}${_formatCurrency(amount)} ج.م',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isBonus
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SALARY STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSalaryStatus() {
    final status = _salaryData['status'] ?? 'draft';
    final salaryId = _salaryData['salary_id'];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'paid':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'تم الصرف ✅';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'approved':
        statusColor = const Color(0xFF2196F3);
        statusText = 'معتمد - في انتظار الصرف';
        statusIcon = Icons.verified_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFFFA726);
        statusText = 'قيد المراجعة';
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      default:
        statusColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7);
        statusText = salaryId != null ? 'محسوب — لم يُصرف بعد' : 'لم يُحسب بعد';
        statusIcon = Icons.info_outline_rounded;
    }

    return PremiumCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الراتب',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOADING & EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ShimmerLoading(height: 100.h, borderRadius: 20.r),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'لا توجد بيانات مالية',
      subtitle: 'لم يتم حساب الراتب لهذا الشهر بعد',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILS
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatCurrency(double amount) {
    if (amount == 0) return '0';
    final formatter = NumberFormat('#,##0.##', 'ar');
    return formatter.format(amount);
  }
}
