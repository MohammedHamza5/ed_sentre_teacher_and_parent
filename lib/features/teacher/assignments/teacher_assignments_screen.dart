import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers/center_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/models.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/widgets/genius/glass_card.dart';
import '../../../core/widgets/genius/genius_button.dart';

import 'create_assignment_screen.dart';
import 'submissions_screen.dart';

/// Teacher Assignments Screen - Forest Dark Mode
class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedCourseId = 'all';
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _assignments = [];
  Map<String, dynamic> _stats = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<GroupModel> _groups = [];
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData(reset: true);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final auth = context.read<AuthProvider>();
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final teacherId = auth.teacherProfile?.id;
      final centerId = centerProvider.currentCenterId;
      if (teacherId != null && centerId != null) {
        _groups = await repository.getTeacherGroups(teacherId, centerId);
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadData();
  }

  Future<void> _loadData({bool reset = false}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
        _assignments = [];
      }
      _error = null;
    });

    try {
      final repository = context.read<SupabaseRepository>();
      final centerProvider = context.read<CenterProvider>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) {
        setState(() {
          _error = 'لم يتم تحديد السنتر';
          _isLoading = false;
        });
        return;
      }

      final assignments = await repository.getTeacherAssignments(
        centerId: centerId,
        courseId: _selectedCourseId == 'all' ? null : _selectedCourseId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      final stats = reset
          ? await repository.getTeacherAssignmentStats(centerId)
          : _stats;

      if (mounted) {
        setState(() {
          if (reset) {
            _assignments = assignments;
          } else {
            _assignments.addAll(assignments);
          }
          _stats = stats;
          _currentPage += 1;
          _hasMore = assignments.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading assignments: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.h,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.forestPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.forestPrimary,
                          AppColors.forestPrimary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.assignment_outlined,
                            size: 150.sp,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 20.w, bottom: 60.h),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.assignment_rounded,
                                        color: Colors.white,
                                        size: 22.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'الواجبات والامتحانات',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'إدارة التقييمات والواجبات المنزلية',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Stats Row
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 16.w,
                              bottom: 60.h,
                              right: 200.w,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildHeaderStat(
                                    '${_stats['total_assignments'] ?? 0}',
                                    'الكل',
                                  ),
                                  SizedBox(width: 10.w),
                                  _buildHeaderStat(
                                    '${_stats['pending_grading'] ?? 0}',
                                    'للتصحيح',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accentVivid,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  tabs: const [
                    Tab(text: 'الكل'),
                    Tab(text: 'واجبات'),
                    Tab(text: 'امتحانات'),
                    Tab(text: 'مؤرشفة'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => _loadData(reset: true),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ];
          },
          body: _isLoading
              ? _buildLoadingSkeleton()
              : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAssignmentsList(null),
                    _buildAssignmentsList('assignment'),
                    _buildAssignmentsList('exam'),
                    _buildAssignmentsList(null, archivedOnly: true),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context),
        backgroundColor: AppColors.accentVivid,
        elevation: 0,
        icon: const Icon(Icons.add, color: AppColors.forestDeep),
        label: const Text(
          'إنشاء جديد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.forestDeep,
          ),
        ),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.glassBorderHighlight),
          ),
          child: Shimmer.fromColors(
            baseColor: AppColors.textDisplay.withValues(alpha: 0.1),
            highlightColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 14.h,
                            color: Colors.white,
                            margin: EdgeInsets.only(right: 40.w),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 100.w,
                            height: 10.h,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(height: 1, color: Colors.white),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 60.w, height: 12.h, color: Colors.white),
                    Container(width: 60.w, height: 12.h, color: Colors.white),
                    Container(width: 60.w, height: 12.h, color: Colors.white),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 36.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40.sp,
              color: AppColors.errorRed,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _error ?? 'حدث خطأ',
            style: TextStyle(
              color: AppColors.textDisplay.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 12.h),
          GeniusButton(
            label: 'إعادة المحاولة',
            icon: Icons.refresh,
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(
    String? typeFilter, {
    bool archivedOnly = false,
  }) {
    final filtered = _assignments.where((a) {
      final archived = _isArchived(a);
      if (archivedOnly && !archived) return false;
      if (!archivedOnly && archived) return false;
      if (typeFilter == null) return true;
      if (typeFilter == 'exam') {
        return a['type'] == 'exam' || a['type'] == 'quiz';
      }
      return a['type'] == typeFilter;
    }).toList();

    final filteredWithSearch =
        filtered.where((a) {
          if (_searchQuery.isEmpty) return true;
          final title = (a['title'] ?? '').toString().toLowerCase();
          final course = (a['course_name'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) || course.contains(_searchQuery);
        }).toList()..sort((a, b) {
          final aDue = DateTime.tryParse(a['due_date'] ?? '');
          final bDue = DateTime.tryParse(b['due_date'] ?? '');
          final aEnded = aDue != null && DateTime.now().isAfter(aDue);
          final bEnded = bDue != null && DateTime.now().isAfter(bDue);
          if (aEnded != bEnded) return aEnded ? 1 : -1;
          if (aDue != null && bDue != null) return aDue.compareTo(bDue);
          return 0;
        });

    final filteredFinal = filteredWithSearch.where((a) {
      if (_statusFilter == 'all') return true;
      final dueDate = DateTime.tryParse(a['due_date'] ?? '');
      final ended = dueDate != null && DateTime.now().isAfter(dueDate);
      if (_statusFilter == 'active') return !ended;
      if (_statusFilter == 'ended') return ended;
      return true;
    }).toList();

    if (filteredFinal.isEmpty) return _buildEmptyState();

    if (filteredFinal.length < 6 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredFinal.length + 2 + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) return _buildSearchAndFilters();
          if (_isLoadingMore && index == filteredFinal.length + 1) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: AppColors.accentVivid,
                ),
              ),
            );
          }
          if (index == filteredFinal.length + 1 + (_isLoadingMore ? 1 : 0)) {
            return SizedBox(height: 60.h);
          }
          final itemIndex = index - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildAssignmentCard(filteredFinal[itemIndex], itemIndex),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.glassBorderHighlight),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            style: TextStyle(color: AppColors.textDisplay, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'ابحث عن واجب أو مادة...',
              hintStyle: TextStyle(
                color: AppColors.textDisplay.withValues(alpha: 0.3),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textDisplay.withValues(alpha: 0.7),
                size: 20.sp,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 18.sp,
                      ),
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.glassBorderHighlight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.glassBorderHighlight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.accentVivid),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 36.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatusChip('all', 'الكل'),
                SizedBox(width: 8.w),
                _buildStatusChip('active', 'نشطة'),
                SizedBox(width: 8.w),
                _buildStatusChip('ended', 'منتهية'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentVivid : (AppColors.darkSurface),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.accentVivid
                : AppColors.glassBorderHighlight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : AppColors.textDisplay.withValues(alpha: 0.7),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderHighlight),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 52.sp,
              color: AppColors.textDisplay.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد بيانات',
            style: TextStyle(
              color: AppColors.textDisplay,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'اضغط على "إنشاء جديد" للبدء',
            style: TextStyle(
              color: AppColors.textDisplay.withValues(alpha: 0.3),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment, int index) {
    final title = assignment['title'] as String? ?? 'بدون عنوان';
    final courseName = assignment['course_name'] as String? ?? 'غير محدد';
    final type = assignment['type'] as String? ?? 'assignment';
    final dueDateStr = assignment['due_date'] as String?;
    final DateTime? dueDate = dueDateStr != null
        ? DateTime.tryParse(dueDateStr)
        : null;
    final publishDate = _getPublishDate(assignment);
    final isArchived = _isArchived(assignment);
    final maxScore = assignment['max_score'] ?? 0;
    // Extract submissions count from Supabase aggregate
    int subCount = 0;
    final subData = assignment['assignment_submissions'];
    if (subData is List && subData.isNotEmpty) {
      subCount = (subData[0]['count'] as num?)?.toInt() ?? 0;
    } else {
      subCount = (assignment['submissions_count'] as num?)?.toInt() ?? 0;
    }

    final isEnded = dueDate != null && DateTime.now().isAfter(dueDate);
    final isScheduled =
        publishDate != null && DateTime.now().isBefore(publishDate);

    Color typeColor;
    IconData typeIcon;
    String typeName;

    switch (type) {
      case 'exam':
        typeColor = Colors.orange;
        typeIcon = Icons.quiz_outlined;
        typeName = 'امتحان';
        break;
      case 'quiz':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.bolt;
        typeName = 'كويز';
        break;
      default:
        typeColor = AppColors.accentVivid;
        typeIcon = Icons.assignment_outlined;
        typeName = 'واجب';
    }

    return GlassCard(
      onTap: () => _openAssignmentDetails(assignment),
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      borderColor: (!isEnded && !isArchived)
          ? (isScheduled ? Colors.orange : AppColors.accentVivid)
          : null,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isEnded
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3)
                            : AppColors.textDisplay,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$typeName • $courseName',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              if (isArchived)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                    'مؤرشف',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.accentVivid,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              if (isArchived) SizedBox(width: 6.w),
              if (isScheduled)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'مجدول',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.orange,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              if (isScheduled) SizedBox(width: 6.w),
              if (isEnded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'منتهي',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(height: 1, color: AppColors.glassBorderHighlight),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildIconText(
                Icons.people_outline,
                '$subCount تسليم',
                AppColors.textDisplay.withValues(alpha: 0.7),
              ),
              const Spacer(),
              _buildIconText(
                Icons.grade_outlined,
                '$maxScore درجة',
                AppColors.textDisplay.withValues(alpha: 0.7),
              ),
              const Spacer(),
              _buildIconText(
                Icons.calendar_today_outlined,
                _formatDate(dueDate),
                isEnded ? AppColors.errorRed : Colors.green,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  onTap: () => _viewSubmissions(assignment),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  borderRadius: 10.r,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderColor: AppColors.accentVivid,
                  child: Center(
                    child: Text(
                      'التصحيح',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.accentVivid,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GlassCard(
                onTap: () => _showMoreOptions(assignment),
                padding: EdgeInsets.all(8.w),
                borderRadius: 10.r,
                color: Colors.white.withValues(alpha: 0.05),
                child: Icon(
                  Icons.more_horiz,
                  size: 18.sp,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(fontSize: 11.sp, color: color),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'بلا موعد';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff < 0) return 'منذ ${diff.abs()} يوم';
    return 'بعد $diff يوم';
  }

  DateTime? _getPublishDate(Map<String, dynamic> assignment) {
    final settings = assignment['settings'];
    Map<String, dynamic>? settingsMap;
    if (settings is Map) {
      settingsMap = Map<String, dynamic>.from(settings);
    } else if (settings is String) {
      try {
        settingsMap = Map<String, dynamic>.from(jsonDecode(settings) as Map);
      } catch (_) {}
    }
    final publishAt = settingsMap?['publish_at'];
    if (publishAt is String) {
      return DateTime.tryParse(publishAt);
    }
    return null;
  }

  bool _isArchived(Map<String, dynamic> assignment) {
    final settings = _extractSettingsMap(assignment);
    return settings['archived'] == true;
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.glassBorderHighlight,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'إنشاء جديد',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDisplay,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _buildCreateOption(
                    icon: Icons.assignment,
                    label: 'واجب',
                    color: AppColors.accentVivid,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToCreate('assignment');
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildCreateOption(
                    icon: Icons.quiz,
                    label: 'امتحان',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToCreate('exam');
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildCreateOption(
                    icon: Icons.bolt,
                    label: 'كويز سريع',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToCreate('quiz');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreate(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateAssignmentScreen(type: type)),
    );

    if (result == true) _loadData();
  }

  void _openAssignmentDetails(Map<String, dynamic> assignment) {
    _showMoreOptions(assignment);
  }

  void _viewSubmissions(Map<String, dynamic> assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionsScreen(assignment: assignment),
      ),
    ).then((_) => _loadData(reset: true));
  }

  void _showMoreOptions(Map<String, dynamic> assignment) {
    final isArchived = _isArchived(assignment);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.glassBorderHighlight,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.group_add,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'نشر لمجموعات إضافية',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openAddToGroups(assignment);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.copy,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'نسخ',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.share,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'مشاركة',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'تعديل موعد الظهور',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editPublishAt(assignment);
                },
              ),
              ListTile(
                leading: Icon(
                  isArchived ? Icons.unarchive : Icons.archive,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  isArchived ? 'إلغاء الأرشفة' : 'أرشفة',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleArchive(assignment, !isArchived);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.errorRed),
                title: Text('حذف', style: TextStyle(color: AppColors.errorRed)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAssignment(assignment);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleArchive(
    Map<String, dynamic> assignment,
    bool archived,
  ) async {
    try {
      final repository = context.read<SupabaseRepository>();
      final settings = _extractSettingsMap(assignment);
      settings['archived'] = archived;
      await repository.updateAssignment(assignment['id'], {
        'settings': _buildSettingsPayload(assignment, settings),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              archived
                  ? 'تمت الأرشفة ويمكنك إيجادها في تبويب مؤرشفة'
                  : 'تم إلغاء الأرشفة',
            ),
          ),
        );
        _loadData(reset: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
      }
    }
  }

  Future<void> _editPublishAt(Map<String, dynamic> assignment) async {
    final currentPublish = _getPublishDate(assignment) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentPublish,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentPublish.hour,
        minute: currentPublish.minute,
      ),
    );
    if (pickedTime == null || !mounted) return;

    final publishDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final dueDate = DateTime.tryParse(assignment['due_date'] ?? '');
    if (dueDate != null && publishDateTime.isAfter(dueDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موعد الظهور يجب أن يسبق موعد التسليم')),
        );
      }
      return;
    }

    try {
      final repository = context.read<SupabaseRepository>();
      final settings = _extractSettingsMap(assignment);
      settings['publish_at'] = publishDateTime.toIso8601String();
      await repository.updateAssignment(assignment['id'], {
        'settings': _buildSettingsPayload(assignment, settings),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث موعد الظهور')));
        _loadData(reset: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
      }
    }
  }

  Future<void> _openAddToGroups(Map<String, dynamic> assignment) async {
    if (_isLoadingGroups) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('جاري تحميل المجموعات...')));
      return;
    }
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد مجموعات متاحة')));
      return;
    }

    final currentGroupId = assignment['group_id'] as String?;
    final selectedIds = <String>{};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableGroups = _groups
                .where((g) => g.id != currentGroupId)
                .toList();
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'اختيار المجموعات',
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          final allSelected =
                              selectedIds.length == availableGroups.length;
                          if (allSelected) {
                            selectedIds.clear();
                          } else {
                            selectedIds
                              ..clear()
                              ..addAll(availableGroups.map((g) => g.id));
                          }
                          setSheetState(() {});
                        },
                        child: Text(
                          selectedIds.length == availableGroups.length
                              ? 'إلغاء الكل'
                              : 'تحديد الكل',
                          style: TextStyle(color: AppColors.accentVivid),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: availableGroups.map((group) {
                        final isChecked = selectedIds.contains(group.id);
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: AppColors.accentVivid,
                          onChanged: (v) {
                            if (v == true) {
                              selectedIds.add(group.id);
                            } else {
                              selectedIds.remove(group.id);
                            }
                            setSheetState(() {});
                          },
                          title: Text(
                            group.groupName,
                            style: TextStyle(color: AppColors.textDisplay),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, selectedIds),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentVivid,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text(
                        'تم',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _duplicateAssignmentToGroups(assignment, result);
    }
  }

  Map<String, dynamic> _extractSettingsMap(Map<String, dynamic> assignment) {
    final settings = assignment['settings'];
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }
    if (settings is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(settings) as Map);
      } catch (_) {}
    }
    return {};
  }

  Object _buildSettingsPayload(
    Map<String, dynamic> assignment,
    Map<String, dynamic> settings,
  ) {
    final original = assignment['settings'];
    if (original is String) {
      return jsonEncode(settings);
    }
    return settings;
  }

  Future<void> _duplicateAssignmentToGroups(
    Map<String, dynamic> assignment,
    Set<String> groupIds,
  ) async {
    try {
      final repository = context.read<SupabaseRepository>();
      final centerProvider = context.read<CenterProvider>();
      final centerId =
          assignment['center_id'] as String? ?? centerProvider.currentCenterId;
      if (centerId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لم يتم تحديد السنتر')));
        return;
      }

      final settings = _extractSettingsMap(assignment);
      settings.putIfAbsent(
        'publish_at',
        () => DateTime.now().toIso8601String(),
      );

      for (final groupId in groupIds) {
        final group = _groups.firstWhere((g) => g.id == groupId);
        final data = {
          'title': assignment['title'],
          'description': assignment['description'],
          'center_id': centerId,
          'group_id': groupId,
          'course_id': group.courseId,
          'type': assignment['type'],
          'max_score': assignment['max_score'],
          'due_date': assignment['due_date'],
          'file_url': assignment['file_url'],
          'file_type': assignment['file_type'],
          'file_size': assignment['file_size'],
          'questions': assignment['questions'],
          'settings': settings,
        };
        await repository.addAssignment(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الإضافة للمجموعات بنجاح')),
        );
        _loadData(reset: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e')));
      }
    }
  }

  Future<void> _deleteAssignment(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'حذف الواجب',
          style: TextStyle(color: AppColors.textDisplay),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${assignment['title']}"؟',
          style: TextStyle(color: AppColors.textDisplay.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.textDisplay.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final repository = context.read<SupabaseRepository>();
        final assignmentId = assignment['id']?.toString();
        if (assignmentId == null || assignmentId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحديد العنصر للحذف')),
          );
          return;
        }
        await repository.deleteAssignment(assignmentId);
        if (mounted) {
          setState(() {
            _assignments.removeWhere(
              (item) => item['id']?.toString() == assignmentId,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الواجب'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(reset: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
        }
      }
    }
  }
}
