import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/config/app_colors.dart';
import '../provider/teacher_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../core/widgets/genius/glass_card.dart';
import '../../../core/widgets/genius/genius_text_field.dart';
import '../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../core/widgets/genius/staggered_list_animator.dart';

/// 🎨 Teacher Students Screen - Forest Dark Edition
class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _lastLoadedCenterId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadStudents(reset: true),
    );
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadStudents();
  }

  Future<void> _loadStudents({bool reset = false}) async {
    final teacherProvider = context.read<TeacherProvider>();
    final teacherId = teacherProvider.teacherId;
    final centerId = teacherProvider.selectedCenterId;

    if (teacherProvider.isLoading) return;
    if (teacherId == null || centerId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              teacherProvider.error ??
              'لم يتم تحميل بيانات المعلم. يرجى العودة للرئيسية والمحاولة مرة أخرى.';
        });
      }
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
        _allStudents = [];
        _filteredStudents = [];
      });
    }

    try {
      final repo = context.read<SupabaseRepository>();
      final students = await repo.getTeacherStudents(
        teacherId: teacherId,
        centerId: centerId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _allStudents = students;
          } else {
            _allStudents.addAll(students);
          }
          _currentPage += 1;
          _hasMore = students.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
        _filterStudents();
      }
    } catch (e) {
      debugPrint('❌ [StudentsScreen] _loadStudents Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'حدث خطأ أثناء تحميل الطلاب: $e';
        });
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredStudents = _allStudents);
    } else {
      setState(() {
        _filteredStudents = _allStudents.where((s) {
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

    if (!teacherProvider.isLoading &&
        currentCenterId != null &&
        currentCenterId != _lastLoadedCenterId &&
        !_isLoadingMore) {
      _lastLoadedCenterId = currentCenterId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadStudents(reset: true);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredStudents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => _loadStudents(reset: true),
                    backgroundColor: AppColors.accentVivid,
                    color: AppColors.darkSurface,
                    child: StaggeredListAnimator(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ).copyWith(bottom: 100.h),
                      children: List.generate(
                        _filteredStudents.length + (_isLoadingMore ? 1 : 0),
                        (index) {
                          if (_isLoadingMore &&
                              index == _filteredStudents.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  backgroundColor: AppColors.accentVivid,
                                ),
                              ),
                            );
                          }
                          return _buildStudentCard(_filteredStudents[index]);
                        },
                      ),
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
        color: AppColors.forestPrimary,
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
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.glassBorderHighlight),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 18.sp,
                    color: AppColors.textDisplay,
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              Expanded(
                child: Text(
                  'طلابي',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDisplay,
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.accentVivid.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.accentVivid.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_filteredStudents.length}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentVivid,
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              const SizedBox.shrink(),
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
  // STUDENT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: GlassCard(
        color: AppColors.darkSurface.withValues(alpha: 0.7),
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Avatar
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorderHighlight),
              ),
              child: CircleAvatar(
                radius: 26.r,
                backgroundColor: AppColors.forestPrimary,
                child: student['student_avatar'] != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: student['student_avatar'],
                          width: 52.r,
                          height: 52.r,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Text(
                        (student['student_name'] ?? 'م')[0],
                        style: TextStyle(
                          color: AppColors.textDisplay,
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
                      color: AppColors.textDisplay,
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
                        color: AppColors.warmAmber,
                      ),
                      if (student['course_name'] != null)
                        _buildTag(
                          icon: Icons.book_outlined,
                          text: student['course_name'],
                          color: AppColors.infoPurple,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                if (student['student_phone'] != null)
                  _buildActionButton(
                    icon: Icons.phone_rounded,
                    color: AppColors.emeraldGreen,
                    onTap: () => _makePhoneCall(student['student_phone']),
                  ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.textDisplay.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
    final subtitle = _errorMessage != null
        ? _errorMessage!
        : _searchController.text.isNotEmpty
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
                color: AppColors.forestPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorderHighlight),
              ),
              child: Icon(
                _errorMessage != null
                    ? Icons.error_outline_rounded
                    : Icons.people_outline_rounded,
                size: 64.sp,
                color: _errorMessage != null
                    ? AppColors.errorRed
                    : AppColors.accentVivid,
              ),
            ).animate().scale(
              delay: 200.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
            SizedBox(height: 24.h),
            Text(
              _errorMessage != null
                  ? 'تعذّر تحميل الطلاب'
                  : 'لا يوجد طلاب حتى الآن',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDisplay,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            SizedBox(height: 12.h),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
