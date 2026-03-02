import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_colors.dart';
import '../provider/teacher_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/widgets/premium_widgets.dart';

/// 🎨 Teacher Students Screen - Premium Dark Mode Design
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
  // Track the last loaded center to avoid redundant reloads
  String? _lastLoadedCenterId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial load attempt - may be skipped if provider is still loading
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents(reset: true));
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

    // If provider is still loading, don't proceed - the build() watcher will trigger a retry
    if (teacherProvider.isLoading) return;
    if (teacherId == null || centerId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = teacherProvider.error ??
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
    // Watch TeacherProvider so we rebuild when it finishes loading.
    // This fixes the race condition where initState fires before the provider is ready.
    final teacherProvider = context.watch<TeacherProvider>();
    final currentCenterId = teacherProvider.selectedCenterId;

    // Auto-trigger load when: provider finished loading AND center changed (or first load)
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
      backgroundColor: AppColors.darkBackground,
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
                    color: AppColors.primary,
                    backgroundColor: AppColors.darkCard,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ).copyWith(bottom: 100.h),
                      itemCount: _filteredStudents.length +
                          (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isLoadingMore &&
                            index == _filteredStudents.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }
                        return _buildStudentCard(
                          _filteredStudents[index],
                          index,
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
        bottom: 20.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.go('/teacher'),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.darkBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 18.sp,
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // Title
              Expanded(
                child: Text(
                  'طلابي',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),

              // Count Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '${_filteredStudents.length}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.darkBorder.withValues(alpha: 0.5),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.textOnDark, fontSize: 15.sp),
              decoration: InputDecoration(
                hintText: 'ابحث عن طالب...',
                hintStyle: TextStyle(
                  color: AppColors.textOnDarkHint,
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textOnDarkSecondary,
                  size: 22.sp,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterStudents();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textOnDarkHint,
                          size: 20.sp,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return PremiumCard(
          onTap: () {
            // Navigate to student details
          },
          margin: EdgeInsets.only(bottom: 14.h),
          child: Row(
            children: [
              // Avatar
              AvatarWithBorder(
                imageUrl: student['student_avatar'],
                radius: 28,
                borderGradient: AppColors.primaryGradient,
                placeholderIcon: Icons.person_rounded,
              ),
              SizedBox(width: 16.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['student_name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
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
                          text: student['group_name'] ?? 'No Group',
                          color: AppColors.warning,
                        ),
                        if (student['course_name'] != null)
                          _buildTag(
                            icon: Icons.book_outlined,
                            text: student['course_name'],
                            color: AppColors.info,
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
                      color: AppColors.success,
                      onTap: () => _makePhoneCall(student['student_phone']),
                    ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.sp,
                      color: AppColors.textOnDarkHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn()
        .slideX(begin: 0.1);
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
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: ShimmerLoading(height: 90.h, borderRadius: 20.r),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Show error details if there's a known error to help with debugging
    final subtitle = _errorMessage != null
        ? _errorMessage!
        : _searchController.text.isNotEmpty
            ? 'لم يتم العثور على نتائج للبحث'
            : 'سيظهر طلابك هنا عند تسجيلهم في مجموعاتك';

    return EmptyState(
      icon: _errorMessage != null
          ? Icons.error_outline_rounded
          : Icons.people_outline_rounded,
      title: _errorMessage != null ? 'تعذّر تحميل الطلاب' : 'لا يوجد طلاب حتى الآن',
      subtitle: subtitle,
    );
  }
}
