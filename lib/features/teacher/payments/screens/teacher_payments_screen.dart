/// Teacher Payments & Financials Screen
/// شاشة المالية والرواتب للمعلم
/// Shows per-group revenue, teacher share vs center share, and salary breakdown
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/premium_widgets.dart';
import '../../provider/teacher_provider.dart';

import '../widgets/teacher_payments_header.dart';
import '../widgets/teacher_payments_month_selector.dart';
import '../widgets/teacher_payments_summary_cards.dart';
import '../widgets/teacher_payments_group_breakdown.dart';
import '../widgets/teacher_payments_bonuses.dart';
import '../widgets/teacher_payments_status.dart';

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
    final bonuses = _salaryData['bonuses'] as List? ?? [];
    final deductions = _salaryData['deductions'] as List? ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: TeacherPaymentsHeader(
              teacherName: _salaryData['teacher_name'] ?? 'تفاصيل مالية',
            ),
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: 16.h),
                TeacherPaymentsMonthSelector(
                  selectedMonth: _selectedMonth,
                  selectedYear: _selectedYear,
                  onMonthChanged: (month, year) {
                    setState(() {
                      _selectedMonth = month;
                      _selectedYear = year;
                    });
                    _loadData();
                  },
                ),
                SizedBox(height: 24.h),

                if (_isLoading)
                  _buildLoadingState()
                else if (_salaryData.isEmpty)
                  _buildEmptyState()
                else ...[
                  // Summary Cards
                  TeacherPaymentsSummaryCards(salaryData: _salaryData),
                  SizedBox(height: 28.h),

                  // Per-Group Breakdown
                  TeacherPaymentsGroupBreakdown(salaryData: _salaryData),
                  SizedBox(height: 28.h),

                  // Bonuses & Deductions
                  TeacherPaymentsBonuses(
                    bonuses: bonuses,
                    deductions: deductions,
                  ),
                  SizedBox(height: 28.h),

                  // Salary Status
                  TeacherPaymentsStatus(salaryData: _salaryData),
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
}
