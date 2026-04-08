import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/premium_widgets.dart'; // fallback if they have it
import 'exam_answer_review_screen.dart';
import 'grading_review_screen.dart';

/// Teacher Submissions / Grading Screen - Premium Edition 🚀
class SubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const SubmissionsScreen({super.key, required this.assignment});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<SubmissionModel> _submissions = [];
  List<Map<String, dynamic>> _allStudents = [];
  String _searchQuery = '';

  late TabController _tabController;

  String get _assignmentId => widget.assignment['id']?.toString() ?? '';
  String get _title => widget.assignment['title']?.toString() ?? 'بدون عنوان';
  String get _type => widget.assignment['type']?.toString() ?? 'assignment';
  double get _maxScore =>
      (widget.assignment['max_score'] as num?)?.toDouble() ?? 100;

  bool get _isInteractive => _type == 'quiz' || _type == 'exam';

  int get _totalCount => _submissions.length;
  int get _gradedCount => _submissions.where((s) => s.isGraded).length;
  int get _pendingCount => _totalCount - _gradedCount;

  double get _avgScore {
    final graded = _submissions.where((s) => s.isGraded).toList();
    if (graded.isEmpty) return 0;
    final total = graded.fold(0.0, (sum, s) => sum + (s.score ?? 0));
    return total / graded.length;
  }

  double get _avgPercentage {
    if (_maxScore == 0) return 0;
    return (_avgScore / _maxScore * 100).clamp(0, 100);
  }

  List<SubmissionModel> get _filteredSubmissions {
    return _submissions.where((sub) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = sub.studentName?.toLowerCase() ?? '';
      return name.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _missingStudents {
    final submittedIds = _submissions.map((s) => s.studentUserId).toSet();
    return _allStudents.where((student) {
      final studentUserId = student['student_user_id'] as String?;
      if (studentUserId == null) return false;
      if (submittedIds.contains(studentUserId)) return false;

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (student['student_name'] as String?)?.toLowerCase() ?? '';
      return name.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<SupabaseRepository>();
      final Future<List<SubmissionModel>> submissionsFuture =
          repository.getAssignmentSubmissions(_assignmentId);
      final Future<List<Map<String, dynamic>>> studentsFuture =
          repository.getAssignmentStudents(widget.assignment);

      final results = await Future.wait([submissionsFuture, studentsFuture]);

      if (mounted) {
        setState(() {
          _submissions = results[0] as List<SubmissionModel>;
          // Sort submissions by graded status, then by date
          _submissions.sort((a, b) {
            if (a.isGraded && !b.isGraded) return 1;
            if (!a.isGraded && b.isGraded) return -1;
            return b.submittedAt.compareTo(a.submittedAt);
          });
          _allStudents = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('==== Error loading submissions data: $e ====');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.accentVivid,
              ),
            )
          : _error != null
          ? _buildError()
          : Stack(
              children: [
                // Background Ambient Glow
                Positioned(
                  top: -100,
                  right: -50,
                  child: Container(
                    width: 300.w,
                    height: 300.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentVivid.withValues(alpha: 0.15),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                      child: Container(),
                    ),
                  ),
                ),
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 280.h,
                        pinned: true,
                        backgroundColor:
                            const Color(0xFF0F172A).withValues(alpha: 0.8),
                        iconTheme: const IconThemeData(color: Colors.white),
                        flexibleSpace: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: FlexibleSpaceBar(
                              titlePadding: EdgeInsets.zero,
                              collapseMode: CollapseMode.pin,
                              background: SafeArea(
                                child: Column(
                                  children: [
                                    SizedBox(height: 50.h),
                                    _buildPremiumDashboard(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottom: PreferredSize(
                          preferredSize: Size.fromHeight(48.h),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B)
                                  .withValues(alpha: 0.5),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: AppColors.accentVivid,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white54,
                              indicatorWeight: 3,
                              labelStyle: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo', // Assuming Cairo is used generally
                              ),
                              tabs: const [
                                Tab(text: 'لوحة التسليمات'),
                                Tab(text: 'المتأخرون'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubmissionsTab(),
                      _buildMissingTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: AppColors.accentVivid,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildPremiumDashboard() {
    final progress = _totalCount > 0 ? (_gradedCount / _totalCount) : 0.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            '$_type • إجمالي التسليمات: $_totalCount',
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular Avg Score
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48.w,
                      height: 48.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 4,
                            color: Colors.white12,
                          ),
                          CircularProgressIndicator(
                            value: _avgPercentage / 100,
                            strokeWidth: 4,
                            strokeCap: StrokeCap.round,
                            color: _avgPercentage >= 80
                                ? AppColors.emeraldGreen
                                : _avgPercentage >= 50
                                ? AppColors.warmAmber
                                : AppColors.errorRed,
                          ),
                          Text(
                            '${_avgPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'متوسط الدرجات',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.sp,
                          ),
                        ),
                        Text(
                          '${_avgScore.toStringAsFixed(1)} / ${_maxScore.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Overview Stats
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('تم التصحيح', style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                          Text('$_gradedCount', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4.h,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(AppColors.emeraldGreen),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('بانتظار التقيم', style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
                          Text('$_pendingCount', style: TextStyle(color: AppColors.warmAmber, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    final list = _filteredSubmissions;
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyMessage('لا توجد تسليمات', 'لم يتم العثور على تسليمات تطابق بحثك')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final sub = list[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 500)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildGlassSubmissionCard(sub),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMissingTab() {
    final list = _missingStudents;
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyMessage('لا يوجد طلاب التأخير', 'جميع الطلاب المضافين قاموا بالتسليم! 🎉')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildMissingStudentCard(list[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGlassSubmissionCard(SubmissionModel submission) {
    final isGraded = submission.isGraded;
    final pct = isGraded && _maxScore > 0
        ? ((submission.score ?? 0) / _maxScore).clamp(0.0, 1.0)
        : 0.0;

    final borderColor = isGraded
        ? (pct >= 0.8
            ? AppColors.emeraldGreen
            : pct >= 0.5
            ? AppColors.warmAmber
            : AppColors.errorRed)
        : Colors.white24;

    return GestureDetector(
      onTap: () => _onSubmissionTap(submission),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6), // Glass effect
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: isGraded && pct >= 0.8
              ? [
                  BoxShadow(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with interactive glow
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isGraded
                          ? [borderColor, borderColor.withValues(alpha: 0.5)]
                          : [AppColors.accentVivid, AppColors.secondary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: const Color(0xFF0F172A),
                    backgroundImage: submission.studentAvatar != null
                        ? NetworkImage(submission.studentAvatar!)
                        : null,
                    child: submission.studentAvatar == null
                        ? Icon(Icons.person, color: Colors.white70, size: 24.sp)
                        : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              submission.studentName ?? 'طالب',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isGraded && pct >= 0.9)
                            Padding(
                              padding: EdgeInsets.only(right: 6.w),
                              child: Text('🏆', style: TextStyle(fontSize: 14.sp)),
                            ),
                          if (isGraded && pct < 0.5)
                            Padding(
                              padding: EdgeInsets.only(right: 6.w),
                              child: Text('⚠️', style: TextStyle(fontSize: 14.sp)),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatDate(submission.submittedAt),
                        style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                // Score or Pending Badge
                if (isGraded)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${submission.score?.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: borderColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ' / ${_maxScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: borderColor.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentVivid, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.white, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'صحّح الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Interactive Smart Action Area
            if (isGraded) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isInteractive ? Icons.analytics_outlined : Icons.remove_red_eye_outlined,
                      color: Colors.white60,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _isInteractive ? 'عرض التحليل الذكي للإجابات' : 'مراجعة المرفقات والتعليق',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 12.sp),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMissingStudentCard(Map<String, dynamic> student) {
    final avatar = student['student_avatar'] as String?;
    final name = student['student_name'] as String? ?? 'طالب';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFF0F172A),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Icon(Icons.person_off, color: Colors.white54, size: 20.sp)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
               color: AppColors.errorRed.withValues(alpha: 0.15),
               borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  'متأخر',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
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
            child: Icon(Icons.error_outline, size: 48.sp, color: AppColors.errorRed),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error ?? 'حدث خطأ غير متوقع',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentVivid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: TextField(
        style: TextStyle(color: Colors.white, fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: 'ابحث عن طالب بالكود الأو بالاسم...',
          hintStyle: TextStyle(color: Colors.white30),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF1E293B).withValues(alpha: 0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    );
  }

  Widget _buildEmptyMessage(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 54.sp,
              color: Colors.white30,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white54, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  void _onSubmissionTap(SubmissionModel submission) {
    if (_isInteractive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamAnswerReviewScreen(
            submission: submission,
            maxScore: _maxScore,
            assignmentTitle: _title,
            assignment: widget.assignment,
          ),
        ),
      ).then((_) => _loadData()); // Reload after returning back
    } else {
      _onGradeTap(submission);
    }
  }

  void _onGradeTap(SubmissionModel submission) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GradingReviewScreen(submission: submission, maxScore: _maxScore),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0 && now.day == date.day) {
      return 'اليوم ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      return 'أمس ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
