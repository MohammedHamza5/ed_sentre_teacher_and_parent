import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/models.dart';
import '../widgets/submissions/missing_student_card.dart';
import '../widgets/submissions/submission_glass_card.dart';
import '../widgets/submissions/submissions_dashboard.dart';
import '../widgets/submissions/submissions_empty_state.dart';
import '../widgets/submissions/submissions_search_bar.dart';
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
      final Future<List<SubmissionModel>> submissionsFuture = repository
          .getAssignmentSubmissions(_assignmentId);
      final Future<List<Map<String, dynamic>>> studentsFuture = repository
          .getAssignmentStudents(widget.assignment);

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
                        backgroundColor: const Color(
                          0xFF0F172A,
                        ).withValues(alpha: 0.8),
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
                                    SubmissionsDashboard(
                                      title: _title,
                                      type: _type,
                                      totalCount: _totalCount,
                                      gradedCount: _gradedCount,
                                      pendingCount: _pendingCount,
                                      avgPercentage: _avgPercentage,
                                      avgScore: _avgScore,
                                      maxScore: _maxScore,
                                    ),
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
                              color: const Color(
                                0xFF1E293B,
                              ).withValues(alpha: 0.5),
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
                                fontFamily:
                                    'Cairo', // Assuming Cairo is used generally
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
                    children: [_buildSubmissionsTab(), _buildMissingTab()],
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

  Widget _buildSubmissionsTab() {
    final list = _filteredSubmissions;
    return Column(
      children: [
        SubmissionsSearchBar(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
        Expanded(
          child: list.isEmpty
              ? const SubmissionsEmptyState(
                  title: 'لا توجد تسليمات',
                  subtitle: 'لم يتم العثور على تسليمات تطابق بحثك',
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final sub = list[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(
                        milliseconds: 400 + (index * 50).clamp(0, 500),
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: SubmissionGlassCard(
                        submission: sub,
                        maxScore: _maxScore,
                        isInteractive: _isInteractive,
                        onTap: () => _onSubmissionTap(sub),
                      ),
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
        SubmissionsSearchBar(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
        Expanded(
          child: list.isEmpty
              ? const SubmissionsEmptyState(
                  title: 'لا يوجد طلاب التأخير',
                  subtitle: 'جميع الطلاب المضافين قاموا بالتسليم! 🎉',
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(
                        milliseconds: 300 + (index * 50).clamp(0, 500),
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: MissingStudentCard(student: list[index]),
                    );
                  },
                ),
        ),
      ],
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 80.w),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? 'خطأ غير معروف',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentVivid,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
