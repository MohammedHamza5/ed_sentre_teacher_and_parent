import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/providers/center_provider.dart';
import '../../provider/teacher_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../core/constants/educational_consts.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/genius_text_field.dart';
import '../../../../core/widgets/genius/genius_button.dart';

/// 🎨 Add Student Screen - Forest Dark Edition
class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  // State
  String? _selectedCourseId;
  String? _selectedGradeLevel;
  List<Map<String, dynamic>> _suggestedGroups = [];
  bool _isAnalyzing = false;
  Map<String, dynamic>? _selectedGroup;

  final List<String> _gradeLevels = EducationalStages.allGrades;

  @override
  Widget build(BuildContext context) {
    final centerProvider = context.watch<CenterProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ).copyWith(bottom: 100.h),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Basic Info Card
                    _buildSectionHeader(
                      title: 'بيانات الطالب',
                      icon: Icons.person_add_rounded,
                    ),
                    GlassCard(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          GeniusTextField(
                            controller: _nameController,
                            label: 'اسم الطالب',
                            prefixIcon: Icons.person_rounded,
                            validator: (v) =>
                                v?.isEmpty == true ? 'مطلوب' : null,
                          ),
                          SizedBox(height: 16.h),
                          GeniusTextField(
                            controller: _phoneController,
                            label: 'رقم الهاتف',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    SizedBox(height: 24.h),

                    // Enrollment Logic
                    _buildSectionHeader(
                      title: 'التسجيل الذكي (Smart Enrollment)',
                      icon: Icons.auto_awesome_rounded,
                    ),
                    GlassCard(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Grade Level Dropdown
                          _buildDropdownField<String>(
                            hint: 'السنة الدراسية',
                            icon: Icons.school_rounded,
                            value: _selectedGradeLevel,
                            items: _gradeLevels
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGradeLevel = value;
                                _suggestedGroups.clear();
                                _selectedGroup = null;
                              });
                              _analyzeBestGroups();
                            },
                          ),
                          SizedBox(height: 16.h),

                          // Course Dropdown
                          Builder(
                            builder: (context) {
                              final groups = Provider.of<TeacherProvider>(context).groups;
                              final seen = <String>{};
                              final courses = <Map<String, dynamic>>[];
                              for (var g in groups) {
                                final cName = g.courseName ?? 'Unknown';
                                final cId = g.courseId;
                                if (!seen.contains(cName)) {
                                  seen.add(cName);
                                  courses.add({'id': cId, 'name': cName});
                                }
                              }
                              return _buildDropdownField<String>(
                                hint: 'المادة الدراسية',
                                icon: Icons.book_rounded,
                                value: _selectedCourseId,
                                items: courses
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c['id'] as String,
                                        child: Text(c['name'] as String),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCourseId = value;
                                    _suggestedGroups.clear();
                                    _selectedGroup = null;
                                  });
                                  _analyzeBestGroups();
                                },
                              );
                            },
                          ),

                          if (_isAnalyzing)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      backgroundColor: Colors.purple,
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      'جاري تحليل الجداول والحمل...',
                                      style: TextStyle(
                                        color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (_suggestedGroups.isNotEmpty) ...[
                            SizedBox(height: 24.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.stars_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'المجموعات المقترحة (الأفضل للطالب):',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            ..._suggestedGroups.map(
                              (group) => _buildGroupSuggestionCard(group),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    SizedBox(height: 32.h),

                    GeniusButton(
                      label: 'حفظ وتسجيل',
                      onPressed: _submit,
                      variant: GeniusButtonVariant.glass,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ],
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
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
              'طالب جديد',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, right: 4.w),
      child: Row(
        children: [
          Icon(icon, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey), size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String hint,
    required IconData icon,
    T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        dropdownColor: AppColors.darkElevated,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.sp),
        icon: Icon(Icons.arrow_drop_down_rounded, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildGroupSuggestionCard(Map<String, dynamic> group) {
    final isSelected = _selectedGroup == group;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroup = group),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            if (group['score'] != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${group['score']}% Match',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group['group_name'] ?? 'Group',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    group['reason'] ?? 'مقترح بناء على الجدول',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              size: 28.sp,
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Future<void> _analyzeBestGroups() async {
    if (_selectedCourseId == null || _selectedGradeLevel == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();

      final suggestions = await repository.suggestBestGroups(
        centerId: centerProvider.currentCenterId!,
        courseId: _selectedCourseId!,
        gradeLevel: _selectedGradeLevel,
      );

      setState(() {
        _suggestedGroups = suggestions;
      });
    } catch (e) {
      debugPrint('Error analyzing groups: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار مجموعة للطالب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      final repository = context.read<SupabaseRepository>();
      final centerProvider = context.read<CenterProvider>();

      await repository.addStudent(
        fullName: _nameController.text,
        phone: _phoneController.text,
        gradeLevel: _selectedGradeLevel!,
        groupId: _selectedGroup!['group_id'],
        centerId: centerProvider.currentCenterId!,
        code: _codeController.text.isNotEmpty ? _codeController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل الطالب بنجاح ✅',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.background,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
