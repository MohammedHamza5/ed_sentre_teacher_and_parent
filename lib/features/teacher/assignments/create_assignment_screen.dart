import 'dart:io';
import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Removed AppColors import
import '../../../core/providers/center_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/models.dart';

/// شاشة إنشاء واجب/امتحان/كويز - تصميم مبسّط وفعال
class CreateAssignmentScreen extends StatefulWidget {
  final String type; // 'assignment', 'exam', 'quiz'
  final String? initialTitle;
  final List<Map<String, dynamic>>? initialQuestions;
  final int? initialDuration;
  final int? initialMaxScore;

  const CreateAssignmentScreen({
    super.key,
    required this.type,
    this.initialTitle,
    this.initialQuestions,
    this.initialDuration,
    this.initialMaxScore,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  final _durationController = TextEditingController(text: '60');

  bool _isLoading = false;
  bool _isLoadingGroups = true;

  List<GroupModel> _groups = [];
  List<GroupModel> _selectedGroups = [];

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _publishDate;
  TimeOfDay? _publishTime;
  bool _startArchived = false;

  // File attachment
  String? _attachmentName;
  String? _attachmentPath;

  // Quiz questions (only for quiz type)
  int _currentStep = 0; // 0 = info, 1 = questions
  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();

    // Pre-fill data if provided (e.g. from AI)
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialQuestions != null) {
      _questions.addAll(widget.initialQuestions!);
      // If quiz, set step to 1 (Questions) if needed? No, let user review info first.
    }
    if (widget.initialDuration != null) {
      _durationController.text = widget.initialDuration.toString();
    }
    if (widget.initialMaxScore != null) {
      _maxScoreController.text = widget.initialMaxScore.toString();
    }

    // Smart defaults
    if (widget.type == 'quiz') {
      _durationController.text = '15';
      _maxScoreController.text = '20';
    } else if (widget.type == 'exam') {
      _durationController.text = '60';
    }
    final now = DateTime.now();
    _publishDate = DateTime(now.year, now.month, now.day);
    _publishTime = TimeOfDay.fromDateTime(now);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final auth = context.read<AuthProvider>();
      final center = context.read<CenterProvider>();
      final repo = context.read<SupabaseRepository>();

      final teacherId = auth.teacherProfile?.id;
      final centerId = center.currentCenterId;

      if (teacherId != null && centerId != null) {
        _groups = await repo.getTeacherGroups(teacherId, centerId);
        if (_groups.isNotEmpty) {
          _selectedGroups = [_groups.first];
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading groups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String get _typeLabel {
    switch (widget.type) {
      case 'exam':
        return 'امتحان';
      case 'quiz':
        return 'كويز';
      default:
        return 'واجب';
    }
  }

  Color get _typeColor {
    switch (widget.type) {
      case 'exam':
        return Colors.orange;
      case 'quiz':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case 'exam':
        return Icons.quiz;
      case 'quiz':
        return Icons.bolt;
      default:
        return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quiz uses stepper, others use single form
    if (widget.type == 'quiz') {
      return _buildQuizScreen();
    } else {
      return _buildSimpleScreen();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SIMPLE SCREEN (Assignment & Exam)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSimpleScreen() {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      appBar: AppBar(
        title: Text(
          'إنشاء $_typeLabel',
          style: const TextStyle(color: AppColors.textDisplay),
        ),
        backgroundColor: AppColors.forestPrimary,
        foregroundColor: AppColors.textDisplay,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDisplay),
      ),
      body: _isLoadingGroups
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.accentVivid,
              ),
            )
          : _groups.isEmpty
          ? _buildNoGroupsState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // Type Header
                  _buildTypeHeader(),
                  SizedBox(height: 20.h),

                  // Group Selection
                  _buildGroupSelector(),
                  SizedBox(height: 16.h),

                  // Title
                  _buildTextField(
                    controller: _titleController,
                    label: 'العنوان *',
                    hint: widget.type == 'exam'
                        ? 'مثال: امتحان نهاية الشهر'
                        : 'مثال: واجب الفصل الثاني',
                    icon: Icons.title,
                    validator: (v) =>
                        v?.isEmpty == true ? 'أدخل العنوان' : null,
                  ),
                  SizedBox(height: 16.h),

                  // Description (optional for assignment)
                  if (widget.type == 'assignment') ...[
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'التعليمات (اختياري)',
                      hint: 'أضف تعليمات للطلاب...',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // File Attachment
                  _buildFileAttachment(),
                  SizedBox(height: 16.h),

                  _buildPublishSelector(),
                  SizedBox(height: 16.h),
                  _buildArchiveSelector(),
                  SizedBox(height: 16.h),

                  // Due Date
                  _buildDateSelector(),
                  SizedBox(height: 16.h),

                  // Duration (for exam only)
                  if (widget.type == 'exam') ...[
                    _buildDurationSelector(),
                    SizedBox(height: 16.h),
                  ],

                  // Score
                  _buildTextField(
                    controller: _maxScoreController,
                    label: 'الدرجة الكلية *',
                    hint: '100',
                    icon: Icons.grade,
                    keyboardType: TextInputType.number,
                    suffix: 'درجة',
                    validator: (v) => v?.isEmpty == true ? 'أدخل الدرجة' : null,
                  ),
                  SizedBox(height: 32.h),

                  // Submit Button
                  _buildSubmitButton(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_typeColor, _typeColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _typeColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(_typeIcon, color: Colors.white, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء $_typeLabel جديد',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.type == 'exam'
                      ? 'ارفع ملف الامتحان وحدد الموعد'
                      : 'أضف واجب للطلاب مع موعد التسليم',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    final selectedNames = _selectedGroups.map((g) => g.groupName).toList();
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: _typeColor),
              SizedBox(width: 8.w),
              Text(
                'المجموعات *',
                style: TextStyle(
                  color: AppColors.textDisplay,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openGroupPicker,
                child: Text('اختيار', style: TextStyle(color: _typeColor)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (selectedNames.isEmpty)
            Text(
              'لم يتم اختيار مجموعة',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: selectedNames
                  .map(
                    (name) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: _typeColor),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: _typeColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _openGroupPicker() async {
    if (_groups.isEmpty) return;
    final selectedIds = _selectedGroups.map((e) => e.id).toSet();
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor:
          AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allSelected = selectedIds.length == _groups.length;
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
                          if (allSelected) {
                            selectedIds.clear();
                          } else {
                            selectedIds
                              ..clear()
                              ..addAll(_groups.map((g) => g.id));
                          }
                          setSheetState(() {});
                        },
                        child: Text(
                          allSelected ? 'إلغاء الكل' : 'تحديد الكل',
                          style: TextStyle(color: _typeColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: _groups.map((group) {
                        final isChecked = selectedIds.contains(group.id);
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: _typeColor,
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
                            style: TextStyle(
                              color: AppColors.textDisplay,
                            ),
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
                        backgroundColor: _typeColor,
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
    if (result != null && mounted) {
      setState(() {
        _selectedGroups = _groups.where((g) => result.contains(g.id)).toList();
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppColors.textDisplay,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(icon, color: _typeColor),
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor:
              AppColors.darkSurface,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildFileAttachment() {
    final isRequired = widget.type == 'exam';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _attachmentName != null
              ? _typeColor
              : AppColors.glassBorderHighlight.withValues(alpha: 0.5),
          width: _attachmentName != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: _typeColor),
              SizedBox(width: 8.w),
              Text(
                isRequired ? 'ملف الامتحان (PDF) *' : 'مرفق (اختياري)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (_attachmentName != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: _typeColor),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _attachmentName!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textDisplay,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.errorRed,
                    ),
                    onPressed: () => setState(() {
                      _attachmentName = null;
                      _attachmentPath = null;
                    }),
                  ),
                ],
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: Icon(Icons.upload_file, color: _typeColor),
              label: Text(
                isRequired ? 'اختر ملف PDF' : 'إضافة مرفق',
                style: TextStyle(color: _typeColor),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _typeColor),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachmentName = result.files.first.name;
          _attachmentPath = result.files.first.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر اختيار الملف')));
    }
  }

  Widget _buildPublishSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: _typeColor),
              SizedBox(width: 8.w),
              Text(
                'موعد الظهور للطلاب',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildQuickPublishChip('فوري', 0),
              _buildQuickPublishChip('غداً', 1),
              _buildQuickPublishChip('بعد 3 أيام', 3),
            ],
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: _selectPublishDate,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _publishDate != null
                    ? _typeColor.withValues(alpha: 0.1)
                    : AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _publishDate != null
                      ? _typeColor
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: _publishDate != null
                        ? _typeColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _publishDate != null
                          ? '${_publishDate!.day}/${_publishDate!.month}/${_publishDate!.year}'
                          : 'اختر تاريخ الظهور',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _publishDate != null
                            ? AppColors.textDisplay
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  if (_publishDate != null) ...[
                    GestureDetector(
                      onTap: _selectPublishTime,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          _publishTime?.format(context) ?? 'الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        value: _startArchived,
        activeColor: _typeColor,
        onChanged: (v) => setState(() => _startArchived = v),
        title: Text(
          'أرشفة عند الإنشاء',
          style: TextStyle(
            color: AppColors.textDisplay,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        subtitle: Text(
          'لن يظهر للطلاب إلا بعد إلغاء الأرشفة',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: _typeColor),
              SizedBox(width: 8.w),
              Text(
                widget.type == 'exam' ? 'موعد الامتحان *' : 'موعد التسليم *',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Quick date options
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildQuickDateChip('غداً', 1),
              _buildQuickDateChip('بعد 3 أيام', 3),
              _buildQuickDateChip('أسبوع', 7),
            ],
          ),
          SizedBox(height: 12.h),

          // Selected date display
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _dueDate != null
                    ? _typeColor.withValues(alpha: 0.1)
                    : AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _dueDate != null
                      ? _typeColor
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _dueDate != null
                        ? _typeColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'اختر التاريخ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _dueDate != null
                            ? AppColors.textDisplay
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...[
                    GestureDetector(
                      onTap: _selectTime,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          _dueTime?.format(context) ?? '11:59 PM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(String label, int days) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected =
        _dueDate != null &&
        _dueDate!.day == targetDate.day &&
        _dueDate!.month == targetDate.month;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) {
        setState(() {
          _dueDate = targetDate;
          _dueTime ??= const TimeOfDay(hour: 23, minute: 59);
        });
      },
      selectedColor: _typeColor.withValues(alpha: 0.2),
      backgroundColor:
          AppColors.darkSurface,
      side: BorderSide(
        color: isSelected
            ? _typeColor
            : AppColors.glassBorderHighlight.withValues(alpha: 0.5),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? _typeColor
            : AppColors.textDisplay.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: _typeColor),
              SizedBox(width: 8.w),
              Text(
                'مدة الامتحان *',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDurationChip(30),
                SizedBox(width: 8.w),
                _buildDurationChip(45),
                SizedBox(width: 8.w),
                _buildDurationChip(60),
                SizedBox(width: 8.w),
                _buildDurationChip(90),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDisplay,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أو أدخل عدد مخصص',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    suffixText: 'دقيقة',
                    suffixStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: _typeColor),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final isSelected = _durationController.text == minutes.toString();

    return ChoiceChip(
      label: Text('$minutes د'),
      selected: isSelected,
      onSelected: (v) {
        setState(() => _durationController.text = minutes.toString());
      },
      selectedColor: _typeColor.withValues(alpha: 0.2),
      backgroundColor:
          AppColors.darkSurface,
      side: BorderSide(
        color: isSelected
            ? _typeColor
            : AppColors.glassBorderHighlight.withValues(alpha: 0.5),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? _typeColor
            : AppColors.textDisplay.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 54.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_typeColor, _typeColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: _typeColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submit,
        icon: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send),
        label: Text('نشر $_typeLabel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildNoGroupsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد مجموعات',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textDisplay,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'تأكد من إضافة مجموعات أولاً',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
        _dueTime ??= const TimeOfDay(hour: 23, minute: 59);
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (time != null) {
      setState(() => _dueTime = time);
    }
  }

  Widget _buildQuickPublishChip(String label, int days) {
    final baseDate = DateTime.now().add(Duration(days: days));
    final targetDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final isSelected =
        _publishDate != null &&
        _publishDate!.day == targetDate.day &&
        _publishDate!.month == targetDate.month &&
        _publishDate!.year == targetDate.year;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) {
        setState(() {
          _publishDate = targetDate;
          _publishTime = days == 0
              ? TimeOfDay.fromDateTime(DateTime.now())
              : const TimeOfDay(hour: 8, minute: 0);
        });
      },
      selectedColor: _typeColor.withValues(alpha: 0.2),
      backgroundColor:
          AppColors.darkSurface,
      side: BorderSide(
        color: isSelected
            ? _typeColor
            : AppColors.glassBorderHighlight.withValues(alpha: 0.5),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? _typeColor
            : AppColors.textDisplay.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _selectPublishDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _publishDate = date;
        _publishTime ??= const TimeOfDay(hour: 8, minute: 0);
      });
    }
  }

  Future<void> _selectPublishTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _publishTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) {
      setState(() => _publishTime = time);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGroups.isEmpty) {
      _showError('اختر مجموعة واحدة على الأقل');
      return;
    }

    if (_dueDate == null) {
      _showError('اختر الموعد');
      return;
    }

    if (widget.type == 'exam' &&
        _attachmentName == null &&
        _questions.isEmpty) {
      _showError('أضف أسئلة تفاعلية أو ارفع ملف الامتحان');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) throw Exception('السنتر غير محدد');

      final dueDateTime = _dueDate!.add(
        Duration(hours: _dueTime?.hour ?? 23, minutes: _dueTime?.minute ?? 59),
      );
      final publishBase = _publishDate ?? DateTime.now();
      final publishDateTime = DateTime(
        publishBase.year,
        publishBase.month,
        publishBase.day,
        _publishTime?.hour ?? TimeOfDay.now().hour,
        _publishTime?.minute ?? TimeOfDay.now().minute,
      );
      if (publishDateTime.isAfter(dueDateTime)) {
        _showError('موعد الظهور يجب أن يسبق موعد التسليم');
        setState(() => _isLoading = false);
        return;
      }
      // Upload file to Supabase Storage if exists
      String? fileUrl;
      String? fileType;
      int? fileSize;

      if (_attachmentPath != null && _attachmentPath!.isNotEmpty) {
        final file = File(_attachmentPath!);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$_attachmentName';
        final storagePath = '$centerId/$fileName';

        // Upload to Storage
        await Supabase.instance.client.storage
            .from('assignments')
            .upload(storagePath, file);

        // Get public URL
        fileUrl = Supabase.instance.client.storage
            .from('assignments')
            .getPublicUrl(storagePath);

        fileType = _attachmentName?.split('.').last;
        fileSize = await file.length();
      }

      for (final group in _selectedGroups) {
        final data = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'center_id': centerId,
          'group_id': group.id,
          'course_id': group.courseId,
          'type': widget.type,
          'max_score': int.tryParse(_maxScoreController.text) ?? 100,
          'due_date': dueDateTime.toIso8601String(),
          'file_url': fileUrl,
          'file_type': fileType,
          'file_size': fileSize,
          'settings': {
            'duration_minutes': widget.type == 'exam' || widget.type == 'quiz'
                ? int.tryParse(_durationController.text)
                : null,
            'publish_at': publishDateTime.toIso8601String(),
            'archived': _startArchived,
            'display_mode': widget.type == 'exam' ? 'all' : 'single',
          },
          'time_limit_minutes': widget.type == 'exam' || widget.type == 'quiz'
              ? int.tryParse(_durationController.text)
              : null,
          'questions': _questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return {
              'id': '${DateTime.now().millisecondsSinceEpoch}_$i',
              'text': q['question'],
              'options': q['options'] ?? [],
              'correct_option_index': q['correct'] ?? 0,
              'correct_answer': q['correct_answer'],
              'points': q['marks'],
              'type': q['type'] ?? 'mcq',
              'difficulty': q['difficulty'],
            };
          }).toList(),
        };
        await repository.addAssignment(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نشر $_typeLabel بنجاح! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error publishing: $e");
      if (mounted) {
        _showError('فشل النشر: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUIZ SCREEN (With Questions Step)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildQuizScreen() {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'إنشاء كويز - المعلومات' : 'إنشاء كويز - الأسئلة',
          style: const TextStyle(color: AppColors.textDisplay),
        ),
        backgroundColor: AppColors.forestPrimary,
        foregroundColor: AppColors.textDisplay,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDisplay),
      ),
      body: _isLoadingGroups
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.accentVivid,
              ),
            )
          : _groups.isEmpty
          ? _buildNoGroupsState()
          : _currentStep == 0
          ? _buildQuizInfoStep()
          : _buildQuizQuestionsStep(),
      bottomNavigationBar: _buildQuizBottomNav(),
    );
  }

  Widget _buildQuizInfoStep() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Type Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_typeColor, _typeColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: _typeColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.white, size: 32.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كويز سريع',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'أسئلة اختيار مع تصحيح تلقائي',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          _buildGroupSelector(),
          SizedBox(height: 16.h),

          _buildTextField(
            controller: _titleController,
            label: 'عنوان الكويز *',
            hint: 'مثال: كويز الوحدة الثانية',
            icon: Icons.title,
            validator: (v) => v?.isEmpty == true ? 'أدخل العنوان' : null,
          ),
          SizedBox(height: 16.h),

          // Duration and Score Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _durationController,
                  label: 'المدة *',
                  hint: '15',
                  icon: Icons.timer,
                  keyboardType: TextInputType.number,
                  suffix: 'دقيقة',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTextField(
                  controller: _maxScoreController,
                  label: 'الدرجة *',
                  hint: '20',
                  icon: Icons.grade,
                  keyboardType: TextInputType.number,
                  suffix: 'درجة',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8.w,
              children: [_buildQuickDateChip('افتراضي 7 أيام', 7)],
            ),
          ),
          SizedBox(height: 12.h),
          _buildPublishSelector(),
          SizedBox(height: 16.h),
          _buildArchiveSelector(),
          SizedBox(height: 16.h),
          _buildDateSelector(),
        ],
      ),
    );
  }

  Widget _buildQuizQuestionsStep() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Questions count
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _typeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.quiz, color: _typeColor),
              SizedBox(width: 12.w),
              Text(
                'عدد الأسئلة: ${_questions.length}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
              const Spacer(),
              Text(
                'الدرجة لكل سؤال: ${_questions.isNotEmpty ? ((int.tryParse(_maxScoreController.text) ?? 20) / _questions.length).toStringAsFixed(1) : '—'}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Questions List
        if (_questions.isEmpty)
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color:
                  AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.quiz,
                  size: 48.sp,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                SizedBox(height: 12.h),
                Text(
                  'لا توجد أسئلة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textDisplay,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'أضف سؤال واحد على الأقل',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_questions.length, (i) => _buildQuestionCard(i)),

        SizedBox(height: 16.h),

        // Add Question Button
        OutlinedButton.icon(
          onPressed: _addQuestion,
          icon: Icon(Icons.add_circle_outline, color: _typeColor),
          label: Text('إضافة سؤال', style: TextStyle(color: _typeColor)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _typeColor),
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = _questions[index];
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: _typeColor,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  q['question'] ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDisplay,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.errorRed,
                  size: 20.sp,
                ),
                onPressed: () => setState(() => _questions.removeAt(index)),
              ),
            ],
          ),
          if (q['options'] != null) ...[
            SizedBox(height: 8.h),
            ...List.generate(
              (q['options'] as List).length,
              (i) => Padding(
                padding: EdgeInsets.only(right: 32.w, top: 4.h),
                child: Row(
                  children: [
                    Icon(
                      q['correct'] == i
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16.sp,
                      color: q['correct'] == i
                          ? Colors.green
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      q['options'][i],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: q['correct'] == i
                            ? Colors.green
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        typeColor: _typeColor,
        onSave: (q) => setState(() => _questions.add(q)),
      ),
    );
  }

  Widget _buildQuizBottomNav() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            AppColors.darkSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDisplay,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('السابق'),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_typeColor, _typeColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_currentStep == 0 ? _goToQuestions : _submitQuiz),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            backgroundColor: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 0
                                  ? 'التالي - الأسئلة'
                                  : 'نشر الكويز',
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              _currentStep == 0
                                  ? Icons.arrow_forward
                                  : Icons.send,
                              size: 18.sp,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToQuestions() {
    if (_selectedGroups.isEmpty) {
      _showError('اختر مجموعة واحدة على الأقل');
      return;
    }
    if (_titleController.text.isEmpty) {
      _showError('أدخل عنوان الكويز');
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _submitQuiz() async {
    if (_questions.isEmpty) {
      _showError('أضف سؤال واحد على الأقل');
      return;
    }
    if (_dueDate == null) {
      _showError('اختر الموعد');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) throw Exception('السنتر غير محدد');

      final dueDateTime = _dueDate!.add(
        Duration(hours: _dueTime?.hour ?? 23, minutes: _dueTime?.minute ?? 59),
      );
      final publishBase = _publishDate ?? DateTime.now();
      final publishDateTime = DateTime(
        publishBase.year,
        publishBase.month,
        publishBase.day,
        _publishTime?.hour ?? TimeOfDay.now().hour,
        _publishTime?.minute ?? TimeOfDay.now().minute,
      );
      if (publishDateTime.isAfter(dueDateTime)) {
        _showError('موعد الظهور يجب أن يسبق موعد التسليم');
        setState(() => _isLoading = false);
        return;
      }

      for (final group in _selectedGroups) {
        final data = {
          'title': _titleController.text,
          'description': 'كويز سريع - ${_questions.length} أسئلة',
          'center_id': centerId,
          'group_id': group.id,
          'course_id': group.courseId,
          'type': 'quiz',
          'max_score': int.tryParse(_maxScoreController.text) ?? 20,
          'due_date': dueDateTime.toIso8601String(),
          'questions': _questions,
          'settings': {
            'duration_minutes': int.tryParse(_durationController.text) ?? 15,
            'auto_grade': true,
            'publish_at': publishDateTime.toIso8601String(),
            'archived': _startArchived,
          },
        };
        await repository.addAssignment(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم نشر الكويز بنجاح! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error publishing quiz: $e");
      if (mounted) {
        _showError('فشل النشر: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// Question Dialog - Supports MCQ, True/False, Short Answer, Essay
// ════════════════════════════════════════════════════════════════════
class _QuestionDialog extends StatefulWidget {
  final Color typeColor;
  final Function(Map<String, dynamic>) onSave;

  const _QuestionDialog({required this.typeColor, required this.onSave});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _questionController = TextEditingController();
  final _options = List.generate(4, (_) => TextEditingController());
  final _correctAnswerController = TextEditingController();
  int _correctOption = 0;
  String _selectedType = 'mcq';
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          AppColors.darkSurface,
      title: Text(
        'إضافة سؤال',
        style: TextStyle(color: AppColors.textDisplay),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text(
              'نوع السؤال:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDisplay,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _buildTypeChip('mcq', 'اختيار من متعدد', Icons.list),
                _buildTypeChip(
                  'true_false',
                  'صح/خطأ',
                  Icons.check_circle_outline,
                ),
                _buildTypeChip('short_answer', 'إجابة قصيرة', Icons.short_text),
                _buildTypeChip('essay', 'مقال', Icons.article),
              ],
            ),
            SizedBox(height: 16.h),

            // Question text
            TextField(
              controller: _questionController,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              style: TextStyle(color: AppColors.textDisplay),
              decoration: InputDecoration(
                labelText: 'نص السؤال',
                labelStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.typeColor),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16.h),

            // Type-specific content
            if (_selectedType == 'mcq') _buildMCQOptions(),
            if (_selectedType == 'true_false') _buildTrueFalseOptions(),
            if (_selectedType == 'short_answer') _buildShortAnswerField(),
            if (_selectedType == 'essay') _buildEssayInfo(),

            if (_errorText != null) ...[
              SizedBox(height: 8.h),
              Text(
                _errorText!,
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(backgroundColor: widget.typeColor),
          child: const Text('إضافة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.typeColor.withValues(alpha: 0.2)
              : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? widget.typeColor
                : AppColors.glassBorderHighlight.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isSelected
                  ? widget.typeColor
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isSelected
                    ? widget.typeColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخيارات:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDisplay,
          ),
        ),
        SizedBox(height: 8.h),
        ...List.generate(
          4,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: GestureDetector(
              onTap: () => setState(() => _correctOption = i),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: _correctOption == i
                        ? widget.typeColor
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctOption,
                      onChanged: (v) => setState(() => _correctOption = v!),
                      activeColor: widget.typeColor,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                        style: TextStyle(
                          color: AppColors.textDisplay,
                        ),
                        decoration: InputDecoration(
                          hintText: 'الخيار ${i + 1}',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجابة الصحيحة:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDisplay,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _correctOption = 0),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: _correctOption == 0
                        ? Colors.green.withValues(alpha: 0.15)
                        : AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _correctOption == 0
                          ? Colors.green
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'صح ✅',
                      style: TextStyle(
                        color: _correctOption == 0
                            ? Colors.green
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _correctOption = 1),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: _correctOption == 1
                        ? Colors.red.withValues(alpha: 0.15)
                        : AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _correctOption == 1
                          ? Colors.red
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'خطأ ❌',
                      style: TextStyle(
                        color: _correctOption == 1
                            ? Colors.red
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortAnswerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجابة الصحيحة:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDisplay,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _correctAnswerController,
          style: TextStyle(color: AppColors.textOnDark),
          decoration: InputDecoration(
            hintText: 'اكتب الإجابة الصحيحة للتصحيح التلقائي',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.typeColor),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'سيتم مقارنة إجابة الطالب بهذه الإجابة (بدون حساسية للأحرف)',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEssayInfo() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'سؤال مقالي - يحتاج تصحيح يدوي من المعلم',
              style: TextStyle(color: Colors.blue, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() => _errorText = 'اكتب نص السؤال');
      return;
    }

    Map<String, dynamic> data = {'question': question, 'type': _selectedType};

    switch (_selectedType) {
      case 'mcq':
        final options = _options.map((c) => c.text.trim()).toList();
        final filledCount = options.where((o) => o.isNotEmpty).length;
        if (filledCount < 2) {
          setState(() => _errorText = 'أدخل خيارين على الأقل');
          return;
        }
        if (options[_correctOption].isEmpty) {
          setState(() => _errorText = 'اختر إجابة صحيحة غير فارغة');
          return;
        }
        data['options'] = options;
        data['correct'] = _correctOption;
        break;
      case 'true_false':
        data['options'] = ['صح', 'خطأ'];
        data['correct'] = _correctOption;
        break;
      case 'short_answer':
        final correctAnswer = _correctAnswerController.text.trim();
        if (correctAnswer.isEmpty) {
          setState(() => _errorText = 'أدخل الإجابة الصحيحة');
          return;
        }
        data['correct_answer'] = correctAnswer;
        data['options'] = <String>[];
        data['correct'] = 0;
        break;
      case 'essay':
        data['options'] = <String>[];
        data['correct'] = -1;
        break;
    }

    widget.onSave(data);
    Navigator.pop(context);
  }
}


