import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../provider/teacher_provider.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/genius_text_field.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_colors.dart';
import '../widgets/student_report_bottom_sheet.dart';
import '../widgets/export_center_bottom_sheet.dart';
/// 🎨 Teacher Students Screen - Forest Dark Edition
class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStudents = [];
  String? _lastLoadedCenterId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    final teacherProvider = context.read<TeacherProvider>();
    final allStudents = teacherProvider.students;

    if (query.isEmpty) {
      setState(() => _filteredStudents = allStudents);
    } else {
      setState(() {
        _filteredStudents = allStudents.where((s) {
          final name = (s['student_name'] ?? '').toString().toLowerCase();
          final code = (s['student_code'] ?? '').toString().toLowerCase();
          final group = (s['group_name'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              code.contains(query) ||
              group.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _refreshStudents() async {
    final teacherProvider = context.read<TeacherProvider>();
    await teacherProvider.refreshData(forceRefresh: true);
    _filterStudents();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherProvider>();
    final currentCenterId = teacherProvider.selectedCenterId;

    // React to center change by updating local filter instantly
    if (!teacherProvider.isLoading &&
        currentCenterId != null &&
        currentCenterId != _lastLoadedCenterId) {
      _lastLoadedCenterId = currentCenterId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _filterStudents();
      });
    }

    final bool isLoading = teacherProvider.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : _filteredStudents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshStudents,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    color: Theme.of(context).colorScheme.surface,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ).copyWith(bottom: 100.h),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(_filteredStudents[index])
                            .animate(
                              delay: Duration(milliseconds: (index % 15) * 50),
                            )
                            .fadeIn(duration: 300.ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
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
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 20.w,
        right: 20.w,
        bottom: 24.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/teacher'),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color:
                          (Theme.of(context).dividerTheme.color ??
                          Colors.grey.shade300),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 18.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              Expanded(
                child: Text(
                  'طلابي',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_filteredStudents.length}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              GestureDetector(
                onTap: _showExportCenterSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.import_export_rounded, size: 16.sp, color: Colors.teal.shade700),
                      SizedBox(width: 4.w),
                      Text(
                        'تصدير',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Search Field utilizing Glass Theme
          GeniusTextField(
            label: 'بحث',
            controller: _searchController,
            hint: 'ابحث عن طالب، كود، أو مجموعة...',
            prefixIcon: Icons.search_rounded,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEETS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showExportCenterSheet() {
    if (_filteredStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد طلاب لتصديرهم'), backgroundColor: Colors.orange),
      );
      return;
    }

    final teacherProvider = context.read<TeacherProvider>();
    final teacherName = teacherProvider.teacherProfile?.fullName ?? 'المعلم';
    final subjectName = teacherProvider.teacherProfile?.subject ?? 'عام';
    
    final query = _searchController.text.trim();
    final groupName = query.isNotEmpty ? 'بحث_$query' : 'كل_الطلاب';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportCenterBottomSheet(
        students: _filteredStudents,
        groupName: groupName,
        teacherName: teacherName,
        subjectName: subjectName,
      ),
    );
  }

  void _showStudentReportSheet(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StudentReportBottomSheet(student: student),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: GestureDetector(
        onTap: () => _showStudentReportSheet(student),
        child: GlassCard(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Avatar
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        (Theme.of(context).dividerTheme.color ??
                        Colors.grey.shade300),
                  ),
                ),
                child: CircleAvatar(
                  radius: 26.r,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: student['student_avatar'] != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: student['student_avatar'],
                            width: 52.r,
                            height: 52.r,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color:
                                  (Theme.of(context).textTheme.bodySmall?.color ??
                                  Colors.grey),
                            ),
                          ),
                        )
                      : Text(
                          (student['student_name'] ?? 'م')[0],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['student_name'] ?? 'طالب',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        _buildTag(
                          icon: Icons.class_outlined,
                          text: student['group_name'] ?? 'لا توجد مجموعة',
                          color: Colors.orange,
                        ),
                        if (student['course_name'] != null)
                          _buildTag(
                            icon: Icons.book_outlined,
                            text: student['course_name'],
                            color: Colors.purple,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.analytics_rounded,
                    color: Colors.amber,
                    onTap: () => _showStudentReportSheet(student),
                  ),
                  SizedBox(width: 8.w),
                  if (student['student_phone'] != null)
                    _buildActionButton(
                      icon: Icons.phone_rounded,
                      color: Colors.green,
                      onTap: () => _makePhoneCall(student['student_phone']),
                    ),
                  if (student['student_phone'] != null)
                    SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.sp,
                      color:
                          (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    double size = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: size.sp),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: ShimmerSkeleton(
              height: 90.h,
              width: double.infinity,
              borderRadius: 20.r,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final subtitle = _searchController.text.isNotEmpty
        ? 'لم يتم العثور على نتائج للبحث'
        : 'سيظهر طلابك هنا عند تسجيلهم في مجموعاتك';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      (Theme.of(context).dividerTheme.color ??
                      Colors.grey.shade300),
                ),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 64.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ).animate().scale(
              delay: 200.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
            SizedBox(height: 24.h),
            Text(
              'لا يوجد طلاب حتى الآن',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            SizedBox(height: 12.h),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    (Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
