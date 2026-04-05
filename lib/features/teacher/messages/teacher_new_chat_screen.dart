import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/providers/center_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/models.dart';
import '../../../core/widgets/genius/glass_card.dart';
import '../../../core/widgets/genius/genius_text_field.dart';
import '../../../core/widgets/genius/shimmer_skeleton.dart';
import '../provider/teacher_provider.dart';
import 'teacher_chat_screen.dart';

/// Teacher New Chat Screen — Select a student to start a new conversation
class TeacherNewChatScreen extends StatefulWidget {
  const TeacherNewChatScreen({super.key});

  @override
  State<TeacherNewChatScreen> createState() => _TeacherNewChatScreenState();
}

class _TeacherNewChatScreenState extends State<TeacherNewChatScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final teacherProvider = context.read<TeacherProvider>();
    final teacherId = teacherProvider.teacherId;
    final centerId = teacherProvider.selectedCenterId;

    if (teacherId == null || centerId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لم يتم تحميل بيانات المعلم';
        });
      }
      return;
    }

    try {
      final repo = context.read<SupabaseRepository>();
      final students = await repo.getTeacherStudents(
        teacherId: teacherId,
        centerId: centerId,
        limit: 200,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  Future<void> _startConversation(Map<String, dynamic> student) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final repo = context.read<SupabaseRepository>();
      final centerId = context.read<CenterProvider>().currentCenterId;
      if (centerId == null) throw Exception('لا يوجد سنتر محدد');

      final studentUserId = student['student_user_id'] as String? ??
          student['user_id'] as String? ??
          '';

      if (studentUserId.isEmpty) {
        throw Exception('لم يتم العثور على معرف المستخدم للطالب');
      }

      final conversationId = await repo.createConversation(
        studentId: studentUserId,
        centerId: centerId,
      );

      if (mounted) {
        final conversation = ConversationModel(
          id: conversationId,
          studentId: studentUserId,
          teacherId: repo.currentUserId ?? '',
          centerId: centerId,
          conversationType: ConversationType.studentTeacher,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          studentName: student['student_name'] as String?,
          studentAvatar: student['student_avatar'] as String?,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل بدء المحادثة: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredStudents.isEmpty
                        ? _buildEmptyState()
                        : _buildStudentList(),
          ),
        ],
      ),
    );
  }

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
                onTap: () => Navigator.pop(context),
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
                  'محادثة جديدة',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDisplay,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.accentVivid.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.accentVivid.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20.sp,
                  color: AppColors.accentVivid,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          GeniusTextField(
            label: 'بحث عن طالب',
            controller: _searchController,
            hint: 'ابحث بالاسم أو الكود أو المجموعة...',
            prefixIcon: Icons.search_rounded,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h)
          .copyWith(bottom: 40.h),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentTile(student, index);
      },
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student, int index) {
    final name = student['student_name'] as String? ?? 'طالب';
    final avatar = student['student_avatar'] as String?;
    final groupName = student['group_name'] as String?;
    final courseName = student['course_name'] as String?;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () => _startConversation(student),
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
                  radius: 24.r,
                  backgroundColor: AppColors.forestPrimary,
                  child: avatar != null
                      ? ClipOval(
                          child: Image.network(
                            avatar,
                            width: 48.r,
                            height: 48.r,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Text(
                          name.isNotEmpty ? name[0] : 'ط',
                          style: TextStyle(
                            color: AppColors.textDisplay,
                            fontSize: 18.sp,
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
                      name,
                      style: TextStyle(
                        color: AppColors.textDisplay,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: [
                        if (groupName != null)
                          _buildTag(
                            icon: Icons.group_rounded,
                            text: groupName,
                            color: AppColors.warmAmber,
                          ),
                        if (courseName != null)
                          _buildTag(
                            icon: Icons.book_rounded,
                            text: courseName,
                            color: AppColors.infoPurple,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat icon
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.accentVivid.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.accentVivid.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.chat_rounded,
                  color: AppColors.accentVivid,
                  size: 18.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
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

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: List.generate(
          6,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ShimmerSkeleton(
              height: 80.h,
              width: double.infinity,
              borderRadius: 20.r,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.search_off_rounded,
                size: 56.sp,
                color: AppColors.textMuted,
              ),
            ).animate().scale(
                  delay: 200.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
            SizedBox(height: 24.h),
            Text(
              'لم يتم العثور على طلاب',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDisplay,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            SizedBox(height: 8.h),
            Text(
              'جرب البحث باسم مختلف',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
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
                Icons.error_outline_rounded,
                size: 56.sp,
                color: AppColors.errorRed,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'تعذر تحميل الطلاب',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDisplay,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? '',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadStudents();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.accentVivid,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: AppColors.forestDeep,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
