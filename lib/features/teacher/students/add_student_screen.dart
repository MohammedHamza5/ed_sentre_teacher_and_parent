import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/providers/center_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../shared/data/supabase_repository.dart';

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

  final List<String> _gradeLevels = [
    'الصف الأول الأعدادي',
    'الصف الثاني الأعدادي',
    'الصف الثالث الأعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  @override
  Widget build(BuildContext context) {
    final centerProvider = context.watch<CenterProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'إضافة طالب جديد',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info Card
              _buildSectionCard(
                title: 'بيانات الطالب',
                icon: Icons.person_add,
                children: [
                  _buildDarkTextField(
                    controller: _nameController,
                    label: 'اسم الطالب',
                    icon: Icons.person,
                    validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                  ),
                  SizedBox(height: 16.h),
                  _buildDarkTextField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Enrollment Logic
              _buildSectionCard(
                title: 'التسجيل الذكي (Smart Enrollment)',
                icon: Icons.auto_awesome,
                children: [
                  // Grade Level Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'السنة الدراسية',
                        labelStyle: TextStyle(
                          color: AppColors.textOnDarkSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.school,
                          color: AppColors.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      ),
                      dropdownColor: AppColors.darkElevated,
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 14.sp,
                      ),
                      items: _gradeLevels
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
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
                  ),
                  SizedBox(height: 16.h),

                  // Course Dropdown
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: context
                        .read<SupabaseRepository>()
                        .getTeacherGroups(
                          context.read<AuthProvider>().teacherProfile!.id,
                          centerProvider.currentCenterId!,
                        )
                        .then((groups) {
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
                          return courses;
                        }),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.darkSurface,
                        );
                      }
                      final courses = snapshot.data!;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'المادة الدراسية',
                            labelStyle: TextStyle(
                              color: AppColors.textOnDarkSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.book,
                              color: AppColors.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                          ),
                          dropdownColor: AppColors.darkElevated,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 14.sp,
                          ),
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
                        ),
                      );
                    },
                  ),

                  if (_isAnalyzing)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 8.h),
                            Text(
                              'جاري تحليل الجداول والحمل...',
                              style: TextStyle(
                                color: AppColors.textOnDarkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_suggestedGroups.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      'المجموعات المقترحة (الأفضل للطالب):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ..._suggestedGroups.map(
                      (group) => _buildGroupSuggestionCard(group),
                    ),
                  ],
                ],
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
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'حفظ وتسجيل',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
          Divider(height: 24.h, color: AppColors.darkBorder),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.textOnDark, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textOnDarkSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildGroupSuggestionCard(Map<String, dynamic> group) {
    final isSelected = _selectedGroup == group;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroup = group),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.darkSurface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            if (group['score'] != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${group['score']}% Match',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group['group_name'] ?? 'Group',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  Text(
                    group['reason'] ?? 'Recommended based on schedule',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textOnDarkSecondary,
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
        SnackBar(
          content: const Text('يرجى اختيار مجموعة للطالب'),
          backgroundColor: AppColors.error,
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
          SnackBar(
            content: const Text('تم تسجيل الطالب بنجاح ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
