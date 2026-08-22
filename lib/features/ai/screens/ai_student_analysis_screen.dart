import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_colors.dart';
import '../../teacher/provider/teacher_provider.dart';
import '../../ai/provider/ai_provider.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import 'package:go_router/go_router.dart';

/// شاشة تحليل أداء المجموعات والطلاب بالذكاء الاصطناعي
class AIStudentAnalysisScreen extends StatefulWidget {
  const AIStudentAnalysisScreen({super.key});

  @override
  State<AIStudentAnalysisScreen> createState() =>
      _AIStudentAnalysisScreenState();
}

class _AIStudentAnalysisScreenState extends State<AIStudentAnalysisScreen> {
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String? _selectedGroupId;
  String? _selectedStudentId;
  Map<String, dynamic>? _analysisResult;
  List<Map<String, dynamic>> _students = [];
  bool _isGroupAnalysis = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = false);
  }

  Future<void> _loadStudentsForGroup(String groupId) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<SupabaseRepository>();
      final students = await repo.getGroupStudents(groupId);
      _students = students
          .map(
            (s) => {
              'id': s['student_id'] ?? s['id'] ?? '',
              'name': s['students']?['full_name'] ?? s['name'] ?? s['full_name'] ?? s['student_name'] ?? 'طالب',
              'avatar': s['students']?['avatar_url'] ?? s['avatar_url'] ?? '',
              'grade': s['grade_level'] ?? '',
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading students: $e');
      _students = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherProvider>();
    final groups = teacherProvider.groups;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'مستشار الأداء الذكي 📊',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Group Selector
          _buildGroupSelector(groups),

          // Student Selector (if group selected)
          if (_selectedGroupId != null && !_isLoading) _buildStudentSelector(),

          // Loading indicator
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),

          // Analysis Result or Instructions
          if (!_isLoading)
            Expanded(
              child: _analysisResult != null
                  ? _buildAnalysisResult()
                  : (_selectedStudentId != null || _selectedGroupId != null)
                  ? _buildAnalyzeButton()
                  : _buildInstructions(),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector(List groups) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGroupId,
        dropdownColor: AppColors.darkElevated,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: 'اختر المجموعة أولاً',
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.group, color: AppColors.primary),
          border: InputBorder.none,
        ),
        items: groups.map((g) {
          return DropdownMenuItem<String>(
            value: g.id,
            child: Text(g.groupName),
          );
        }).toList(),
        onChanged: (v) {
          setState(() {
            _selectedGroupId = v;
            _selectedStudentId = 'all_group'; // Default to group analysis
            _analysisResult = null;
            _students = [];
          });
          if (v != null) {
            _loadStudentsForGroup(v);
          }
        },
      ),
    );
  }

  Widget _buildStudentSelector() {
    if (_students.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8.w),
            Text(
              'لا يوجد طلاب في هذه المجموعة',
              style: TextStyle(fontSize: 13.sp, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedStudentId,
        dropdownColor: AppColors.darkElevated,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: 'اختر الطالب',
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.person, color: AppColors.primary),
          border: InputBorder.none,
        ),
        items: [
          DropdownMenuItem<String>(
            value: 'all_group',
            child: Text('🌟 تحليل شامل للمجموعة 🌟', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          ..._students.map((s) {
            return DropdownMenuItem<String>(
              value: s['id'] as String,
              child: Text(s['name'] as String),
            );
          }),
        ],
        onChanged: (v) {
          setState(() {
            _selectedStudentId = v;
            _analysisResult = null;
          });
        },
      ),
    );
  }

  Widget _buildInstructions() {
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
                border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
              ),
              child: Icon(
                Icons.analytics,
                size: 60.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'تحليل ذكي لأداء الطلاب',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'اختر مجموعة ثم طالب للحصول على:\n\n• تحليل نقاط القوة والضعف\n• مقارنة بمتوسط الصف\n• اقتراحات للتحسين\n• تقرير شامل',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final selectedStudent = _students.firstWhere(
      (s) => s['id'] == _selectedStudentId,
      orElse: () => {'name': '', 'grade': ''},
    );

    final isGroup = _selectedStudentId == 'all_group' || _selectedStudentId == null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 50.r,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(isGroup ? Icons.groups : Icons.person, size: 50.sp, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            isGroup ? 'تحليل أداء المجموعة بالكامل' : (selectedStudent['name'] as String? ?? ''),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (!isGroup)
            Text(
              selectedStudent['grade'] as String? ?? '',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          SizedBox(height: 32.h),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _performAnalysis,
              icon: _isAnalyzing
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _isAnalyzing ? 'جاري التحليل...' : (isGroup ? 'تحليل المجموعة' : 'تحليل الطالب'),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'تحليل مجاني بالذكاء الاصطناعي',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final result = _analysisResult!;
    final strengths = result['strengths'] as List? ?? [];
    final weaknesses = result['weaknesses'] as List? ?? [];
    final suggestions = result['suggestions'] as List? ?? [];
    final overallScore = (result['overall_score'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score
          _buildOverallScoreCard(overallScore),
          SizedBox(height: 16.h),

          // Strengths
          _buildAnalysisSection(
            title: 'نقاط القوة 💪',
            items: strengths.cast<String>(),
            color: AppColors.success,
            icon: Icons.trending_up,
          ),
          SizedBox(height: 16.h),

          // Weaknesses
          _buildAnalysisSection(
            title: 'نقاط الضعف ⚠️',
            items: weaknesses.cast<String>(),
            color: Colors.orange,
            icon: Icons.trending_down,
          ),
          SizedBox(height: 16.h),

          // Suggestions
          _buildAnalysisSection(
            title: 'اقتراحات للتحسين 💡',
            items: suggestions.cast<String>(),
            color: AppColors.primary,
            icon: Icons.lightbulb,
          ),
          SizedBox(height: 24.h),

          // CTA: Create Quiz (Only for group analysis)
          if (_isGroupAnalysis) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/teacher/create-assignment'); // Navigates to assignment creation
                },
                icon: Icon(Icons.flash_on, color: Colors.white),
                label: Text(
                  'تنفيذ نصيحة الذكاء الاصطناعي: بناء اختبار علاجي الآن',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Analyze Another
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _analysisResult = null;
                _selectedStudentId = null;
              }),
              icon: Icon(Icons.refresh, color: AppColors.primary),
              label: Text(
                'تحليل طالب آخر',
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(int score) {
    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.success;
      scoreLabel = 'ممتاز';
    } else if (score >= 60) {
      scoreColor = AppColors.primary;
      scoreLabel = 'جيد';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'متوسط';
    } else {
      scoreColor = AppColors.error;
      scoreLabel = 'يحتاج تحسين';
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score%',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التقييم العام',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  scoreLabel,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required List<String> items,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (items.isEmpty)
            Text(
              'لا توجد بيانات كافية',
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6.h),
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _performAnalysis() async {
    if (_selectedGroupId == null) return;

    final aiProvider = context.read<AIProvider>();
    final centerProvider = context.read<CenterProvider>();
    final isGroup = _selectedStudentId == 'all_group' || _selectedStudentId == null;

    setState(() {
      _isAnalyzing = true;
      _isGroupAnalysis = isGroup;
    });

    try {
      if (isGroup) {
        final result = await aiProvider.analyzeGroupPerformance(
          groupId: _selectedGroupId!,
        );
        if (result != null) {
          setState(() {
            _analysisResult = result;
          });
        }
      } else {
        final insights = await aiProvider.analyzeStudentWeaknesses(
          studentId: _selectedStudentId!,
          centerId: centerProvider.currentCenterId!,
        );

        final weaknesses = <String>[];
        final suggestions = <String>[];

        for (final insight in insights) {
          weaknesses.add(insight.message);
          suggestions.add(insight.suggestion);
        }

        int overallScore = 100 - (insights.length * 15);
        overallScore = overallScore.clamp(20, 100);

        setState(() {
          _analysisResult = {
            'overall_score': overallScore,
            'strengths': insights.isEmpty
                ? ['أداء جيد بشكل عام', 'لا توجد نقاط ضعف واضحة']
                : <String>[],
            'weaknesses': weaknesses,
            'suggestions': suggestions,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }
}
