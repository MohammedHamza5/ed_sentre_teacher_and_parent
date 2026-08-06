import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../provider/teacher_provider.dart';
import '../../../../core/widgets/genius/genius_text_field.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';
import '../widgets/student_report_bottom_sheet.dart';
import '../widgets/export_center_bottom_sheet.dart';
import '../widgets/audio_journal_bottom_sheet.dart';
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

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
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
    final specializations = teacherProvider.teacherProfile?.specializations;
    final subjectName = (specializations != null && specializations.isNotEmpty) 
        ? specializations.first 
        : 'عام';
    
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StudentReportBottomSheet(student: student),
    );
  }

  void _showAudioJournalSheet(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => AudioJournalBottomSheet(student: student),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final String studentName = student['student_name'] ?? 'طالب';
    final String? studentCode = student['student_code']?.toString();
    final String? phone = student['parent_phone']?.toString() ?? student['student_phone']?.toString();
    final String groupName = student['group_name'] ?? 'بدون مجموعة';
    final String courseName = student['course_name'] ?? 'المادة الدراسية';

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          children: [
            // Top Section: Info + Quick Actions
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with Gradient Ring
                  Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: CircleAvatar(
                        radius: 26.r,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.4),
                        child: student['student_avatar'] != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: student['student_avatar'],
                                  width: 52.r,
                                  height: 52.r,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.person_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : Text(
                                studentName.isNotEmpty ? studentName[0] : 'م',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),

                  // Name & Tags Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                studentName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (studentCode != null && studentCode.isNotEmpty) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  '#$studentCode',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 10.h),

                        // Chips Row
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: [
                            _buildTag(
                              icon: Icons.groups_rounded,
                              text: groupName,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            _buildTag(
                              icon: Icons.menu_book_rounded,
                              text: courseName,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Buttons Cluster
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.mic_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () => _showAudioJournalSheet(student),
                        tooltip: 'ملاحظة صوتية',
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        _buildActionButton(
                          icon: Icons.chat_outlined,
                          color: const Color(0xFF22C55E),
                          onTap: () => _openWhatsApp(phone),
                          tooltip: 'واتساب',
                        ),
                        SizedBox(width: 6.w),
                        _buildActionButton(
                          icon: Icons.phone_forwarded_rounded,
                          color: const Color(0xFF0EA5E9),
                          onTap: () => _makePhoneCall(phone),
                          tooltip: 'اتصال',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Full-Width CTA Banner
            InkWell(
              onTap: () => _showStudentReportSheet(student),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22.r)),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(22.r),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          size: 16.sp,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'عرض التقرير الشامل وتقييم المستوى',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    String? tooltip,
    double size = 18,
  }) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(9.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: size.sp),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
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
