/// Teacher Payments & Financials Screen
/// شاشة المالية والرواتب للمعلم
/// Shows per-group revenue, teacher share vs center share, and salary breakdown
library;

import 'dart:async';
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
import '../../../auth/provider/auth_provider.dart';
import '../../../../shared/models/models.dart';

class TeacherPaymentsScreen extends StatefulWidget {
  const TeacherPaymentsScreen({super.key});

  @override
  State<TeacherPaymentsScreen> createState() => _TeacherPaymentsScreenState();
}

class _TeacherPaymentsScreenState extends State<TeacherPaymentsScreen>
    with RouteAware {
  Map<String, dynamic> _salaryData = {};
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  /// Timer للتحديث التلقائي كل 30 ثانية (يلتقط أي تحصيل تم من تطبيق الإدارة)
  Timer? _autoRefreshTimer;

  /// RouteObserver للتعامل مع أحداث التنقل
  static final RouteObserver<ModalRoute<void>> _routeObserver =
      RouteObserver<ModalRoute<void>>();

  /// Getter عام لإضافته لـ MaterialApp.navigatorObservers
  static RouteObserver<ModalRoute<void>> get routeObserver => _routeObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // تسجيل هذه الشاشة كـ RouteAware للتحديث التلقائي عند العودة إليها
      final route = ModalRoute.of(context);
      if (route != null) {
        _routeObserver.subscribe(this, route);
      }
    });

    // ← تحديث تلقائي كل 30 ثانية: يضمن أن أي تحصيل تم من تطبيق الإدارة
    //   يظهر للمعلم دون الحاجة لإغلاق وفتح التطبيق
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // نُحدّث فقط إذا كانت الشاشة الحالية هي شاشة الشهر الحالي (لا داعي لتحديث الأشهر الماضية)
      final now = DateTime.now();
      if (_selectedMonth == now.month && _selectedYear == now.year && mounted && !_isLoading) {
        debugPrint('⏱️ [TeacherPayments] تحديث تلقائي دوري — فحص تحصيلات جديدة');
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // إيقاف التحديث التلقائي عند الخروج من الشاشة
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// يُستدعى تلقائياً عند العودة لهذه الشاشة من شاشة أخرى
  /// المشكلة 2: يضمن تحديث بيانات المعلم بعد أي عملية تحصيل من تطبيق الإدارة
  @override
  void didPopNext() {
    debugPrint('🔄 [TeacherPayments] العودة للشاشة — إعادة تحميل البيانات المالية');
    _loadData();
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
    final isIndependent = context.read<AuthProvider>().currentUser?.role == UserRole.centerAdmin ||
        _salaryData['salary_type'] == 'independent';

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
                  TeacherPaymentsSummaryCards(
                    salaryData: _salaryData,
                    isIndependent: isIndependent,
                  ),
                  SizedBox(height: 28.h),

                  // Per-Group Breakdown
                  TeacherPaymentsGroupBreakdown(
                    salaryData: _salaryData,
                    isIndependent: isIndependent,
                  ),
                  SizedBox(height: 28.h),

                  // Bonuses & Deductions
                  TeacherPaymentsBonuses(
                    bonuses: bonuses,
                    deductions: deductions,
                  ),
                  SizedBox(height: 28.h),

                  // Salary Status
                  TeacherPaymentsStatus(
                    salaryData: _salaryData,
                    isIndependent: isIndependent,
                  ),
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
      title: 'لم يُحسب الراتب بعد',
      subtitle:
          'يتم حساب الراتب تلقائياً بعد تسجيل جلسات الحضور وإتمام الحصص. تأكد من تسجيل الحضور في مجموعاتك لهذا الشهر.',
    );
  }
}
