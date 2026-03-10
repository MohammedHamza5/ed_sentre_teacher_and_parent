import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Removed AppColors import
import '../../../core/providers/center_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../core/constants/educational_consts.dart';

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
      appBar: AppBar(
        title: Text(
          'إضافة طالب جديد',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'السنة الدراسية',
                        labelStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.school,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      ),
                      dropdownColor: Theme.of(context).canvasColor,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                        );
                      }
                      final courses = snapshot.data!;
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'المادة الدراسية',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.book,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                          ),
                          dropdownColor: Theme.of(context).canvasColor,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                            CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'جاري تحليل الجداول والحمل...',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
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
                        color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
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
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20.sp,
              ),
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
          Divider(
            height: 24.h,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
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
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
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
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${group['score']}% Match',
                  style: TextStyle(
                    color: Colors.green,
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    group['reason'] ?? 'Recommended based on schedule',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
          backgroundColor: Theme.of(context).colorScheme.error,
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
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
