import 'dart:math';

import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:ed_sentre_techer_and_parent/features/exam_generator/presentation/providers/ai_exam_provider.dart';
import 'package:ed_sentre_techer_and_parent/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../../shared/data/supabase_repository.dart';

/// شاشة معاينة الامتحان المولّد — يراجع المعلم الأسئلة ثم ينشر (محرر تفاعلي)
class ExamPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> examData;

  const ExamPreviewScreen({super.key, required this.examData});

  @override
  State<ExamPreviewScreen> createState() => _ExamPreviewScreenState();
}

class _ExamPreviewScreenState extends State<ExamPreviewScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isLoadingGroups = true;
  bool _isPublishing = false;
  List<GroupModel> _groups = [];
  GroupModel? _selectedGroup;
  bool _showAnswersAfter = true;
  bool _shuffleQuestions = false;

  // ─── البيانات القابلة للتعديل ──────────────────────────────
  List<Map<String, dynamic>> _questions = [];
  final Set<String> _editingIds = {};

  // Controllers لحفظ حالة التعديل لكل سؤال (مفتاح: question id)
  final Map<String, Map<String, TextEditingController>> _editControllers = {};
  final Map<String, int> _editCorrectAnswers = {};

  @override
  void initState() {
    super.initState();
    _titleController.text =
        widget.examData['title']?.toString() ?? 'امتحان بالذكاء الاصطناعي';

    final raw = widget.examData['questions'];
    if (raw is List) {
      _questions = raw.map((e) {
        final q = Map<String, dynamic>.from(e as Map);
        q['id'] = q['id']?.toString() ?? _generateId();
        return q;
      }).toList();
    }

    _durationController.text =
        (widget.examData['estimated_time_minutes'] ?? _questions.length * 2)
            .toString();

    _loadGroups();
  }

  String _generateId() =>
      'q_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    for (final controllers in _editControllers.values) {
      for (final c in controllers.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final auth = context.read<AuthProvider>();
      final center = context.read<CenterProvider>();
      final repo = context.read<SupabaseRepository>();

      final teacherId = auth.teacherProfile?.id;
      final centerId = center.currentCenterId;

      if (teacherId != null && centerId != null) {
        _groups = await repo.getTeacherGroups(teacherId, centerId);
        if (_groups.isNotEmpty) _selectedGroup = _groups.first;
      }
    } catch (e) {
      debugPrint('❌ Error loading groups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _publishExam() async {
    if (_selectedGroup == null) {
      _showSnack('يرجى اختيار مجموعة أولاً');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack('يرجى إدخال عنوان الامتحان');
      return;
    }
    if (_editingIds.isNotEmpty) {
      _showSnack('يرجى حفظ أو إلغاء التعديلات الجارية قبل النشر');
      return;
    }

    setState(() => _isPublishing = true);

    final provider = context.read<AiExamProvider>();
    final center = context.read<CenterProvider>();
    final centerId = center.currentCenterId;

    if (centerId == null) {
      _showSnack('لم يتم تحديد المركز');
      setState(() => _isPublishing = false);
      return;
    }

    final duration = int.tryParse(_durationController.text);
    final examType =
        widget.examData['exam_type']?.toString() ??
        widget.examData['examType']?.toString() ??
        'exam';

    final assignmentId = await provider.saveAndPublishExam(
      centerId: centerId,
      groupId: _selectedGroup!.id,
      courseId: _selectedGroup!.courseId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      examType: examType,
      difficulty: widget.examData['difficulty']?.toString() ?? 'medium',
      timeLimitMinutes: duration,
      showAnswersAfter: _showAnswersAfter,
      shuffleQuestions: _shuffleQuestions,
      editedQuestions: _questions, // تمرير الأسئلة المعدلة
    );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (assignmentId != null) {
        _showSuccessDialog();
      } else {
        _showSnack(provider.error ?? 'فشل النشر');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 56.sp),
            SizedBox(height: 12.h),
            Text(
              'تم النشر بنجاح! 🎉',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'تم نشر الامتحان لمجموعة "${_selectedGroup?.groupName}" بنجاح.\n'
          'سيظهر للطلاب في قائمة الامتحانات.',
          style: TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── دوال تعديل الأسئلة ──────────────────────────────────────────

  void _startEditing(Map<String, dynamic> q) {
    final id = q['id'].toString();
    final options = (q['options'] as List?)?.cast<String>() ?? [];

    _editControllers[id] = {
      'text': TextEditingController(text: q['text']?.toString() ?? ''),
      'explanation': TextEditingController(
        text: q['explanation']?.toString() ?? '',
      ),
      'marks': TextEditingController(text: (q['marks'] ?? 2).toString()),
    };

    for (int i = 0; i < options.length; i++) {
      _editControllers[id]!['opt_$i'] = TextEditingController(text: options[i]);
    }

    _editCorrectAnswers[id] = q['correct_answer'] as int? ?? 0;

    setState(() {
      _editingIds.add(id);
    });
  }

  void _saveEditing(Map<String, dynamic> q) {
    final id = q['id'].toString();
    final controllers = _editControllers[id]!;

    final optionsCount = q['type'] == 'true_false' ? 2 : 4;
    final newOptions = <String>[];
    for (int i = 0; i < optionsCount; i++) {
      newOptions.add(controllers['opt_$i']?.text ?? '');
    }

    setState(() {
      final index = _questions.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        _questions[index] = {
          ...q,
          'text': controllers['text']?.text ?? '',
          'explanation': controllers['explanation']?.text ?? '',
          'marks': int.tryParse(controllers['marks']?.text ?? '2') ?? 2,
          'options': newOptions,
          'correct_answer': _editCorrectAnswers[id] ?? 0,
        };
      }
      _editingIds.remove(id);
    });

    _disposeControllers(id);
  }

  void _cancelEditing(String id) {
    setState(() {
      _editingIds.remove(id);
    });
    _disposeControllers(id);
  }

  void _disposeControllers(String id) {
    for (final c in _editControllers[id]?.values ?? <TextEditingController>[]) {
      c.dispose();
    }
    _editControllers.remove(id);
    _editCorrectAnswers.remove(id);
  }

  void _deleteQuestion(String id) {
    setState(() {
      _questions.removeWhere((q) => q['id'] == id);
      _cancelEditing(id);
    });
  }

  void _duplicateQuestion(Map<String, dynamic> q) {
    final newQ = Map<String, dynamic>.from(q);
    newQ['id'] = _generateId();
    newQ['text'] = '${newQ['text']} (نسخة)';

    setState(() {
      final index = _questions.indexWhere(
        (element) => element['id'] == q['id'],
      );
      if (index != -1) {
        _questions.insert(index + 1, newQ);
      } else {
        _questions.add(newQ);
      }
    });
    _showSnack('تم استنساخ السؤال بنجاح ✨');
  }

  void _addNewQuestion() {
    final newQ = <String, dynamic>{
      'id': _generateId(),
      'type': 'mcq',
      'text': 'سؤال جديد...',
      'options': ['أ', 'ب', 'ج', 'د'],
      'correct_answer': 0,
      'explanation': '',
      'marks': 2,
      'difficulty': 'medium',
    };
    setState(() {
      _questions.add(newQ);
    });
    _startEditing(newQ);
  }

  // ─── بناء واجهة المستخدم ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'محرر الامتحانات الذكي',
          style: TextStyle(color: AppColors.textOnDark, fontSize: 18.sp),
        ),
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textOnDark),
      ),
      body: _isLoadingGroups
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExamSummary(),
                        SizedBox(height: 20.h),
                        _buildPublishSettings(),
                        SizedBox(height: 20.h),
                        _buildQuestionsHeader(),
                        SizedBox(height: 12.h),

                        // NOTE: السحب والإفلات لإعادة ترتيب الأسئلة (Surprise Feature 1)
                        if (_questions.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.r),
                              child: Text(
                                'لا توجد أسئلة، قم بإضافة سؤال جديد.',
                                style: TextStyle(
                                  color: AppColors.textOnDarkHint,
                                ),
                              ),
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _questions.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = _questions.removeAt(oldIndex);
                                _questions.insert(newIndex, item);
                              });
                            },
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                color: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              final id = q['id'].toString();
                              return Container(
                                key: ValueKey(id),
                                margin: EdgeInsets.only(bottom: 12.h),
                                child: _editingIds.contains(id)
                                    ? _buildEditingQuestionCard(index, q)
                                    : _buildViewQuestionCard(index, q),
                              );
                            },
                          ),

                        SizedBox(height: 16.h),

                        // Add new question button
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _addNewQuestion,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('إضافة سؤال جديد'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),

                // Bottom Publish Button Panel
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    border: Border(
                      top: BorderSide(color: AppColors.darkBorder),
                    ),
                  ),
                  child: _buildPublishButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildExamSummary() {
    final totalMarks = _questions.fold<int>(
      0,
      (sum, q) => sum + (q['marks'] as int? ?? 2),
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'محرر الامتحان التفاعلي ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'عدّل الأسئلة بمرونة واسحبها لترتيبها',
                      style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('${_questions.length}', 'سؤال', Icons.help_outline),
              _summaryItem('$totalMarks', 'درجة', Icons.star_border),
              _summaryItem(
                widget.examData['difficulty']?.toString() == 'easy'
                    ? 'سهل'
                    : widget.examData['difficulty']?.toString() == 'hard'
                    ? 'صعب'
                    : 'متوسط',
                'صعوبة',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white60, fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _buildPublishSettings() {
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
          Text(
            'إعدادات النشر',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInput(
            controller: _titleController,
            label: 'عنوان الامتحان',
            icon: Icons.title,
          ),
          SizedBox(height: 12.h),
          _buildInput(
            controller: _descriptionController,
            label: 'وصف (اختياري)',
            icon: Icons.description,
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          _buildInput(
            controller: _durationController,
            label: 'المدة (بالدقائق)',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16.h),
          Text(
            'المجموعة المستهدفة',
            style: TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          if (_groups.isEmpty)
            Text(
              'لا توجد مجموعات',
              style: TextStyle(color: AppColors.error, fontSize: 13.sp),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.darkInput,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GroupModel>(
                  value: _selectedGroup,
                  isExpanded: true,
                  dropdownColor: AppColors.darkElevated,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 14.sp,
                  ),
                  items: _groups.map((g) {
                    return DropdownMenuItem(value: g, child: Text(g.groupName));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedGroup = v),
                ),
              ),
            ),
          SizedBox(height: 16.h),
          _buildSwitch(
            'إظهار الإجابات بعد الحل',
            _showAnswersAfter,
            (v) => setState(() => _showAnswersAfter = v),
          ),
          _buildSwitch(
            'ترتيب الأسئلة عشوائي',
            _shuffleQuestions,
            (v) => setState(() => _shuffleQuestions = v),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textOnDark, fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textOnDarkHint),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.darkInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13.sp),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildQuestionsHeader() {
    return Row(
      children: [
        Icon(Icons.quiz, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          'الأسئلة (${_questions.length})',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.drag_indicator,
          color: AppColors.textOnDarkHint,
          size: 16.sp,
        ),
        SizedBox(width: 4.w),
        Text(
          'اسحب للترتيب',
          style: TextStyle(color: AppColors.textOnDarkHint, fontSize: 12.sp),
        ),
      ],
    );
  }

  // ─── بطاقة معاينة السؤال (View Mode) ──────────────────────────────
  Widget _buildViewQuestionCard(int index, Map<String, dynamic> q) {
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    final correctIdx = q['correct_answer'] as int? ?? 0;
    final type = q['type']?.toString() ?? 'mcq';
    final explanation = q['explanation']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator,
                  color: AppColors.textOnDarkHint,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'سؤال ${index + 1}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: type.contains('true')
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        type.contains('true') ? 'صح/خطأ' : 'اختيار',
                        style: TextStyle(
                          color: type.contains('true')
                              ? AppColors.warning
                              : AppColors.info,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    Text(
                      '${q['marks'] ?? 2} درجة',
                      style: TextStyle(
                        color: AppColors.textOnDarkHint,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: Icon(
                  Icons.copy_rounded,
                  color: AppColors.info,
                  size: 20.sp,
                ),
                tooltip: 'استنساخ السؤال',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _duplicateQuestion(q),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: AppColors.warning,
                  size: 20.sp,
                ),
                tooltip: 'تعديل',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _startEditing(q),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20.sp,
                ),
                tooltip: 'حذف',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteQuestion(q['id'].toString()),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Question text
          Text(
            q['text']?.toString() ?? '',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 10.h),

          // Options
          ...options.asMap().entries.map((e) {
            final isCorrect = e.key == correctIdx;
            return Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.darkInput,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.darkBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: isCorrect ? AppColors.success : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.textOnDarkHint,
                      ),
                    ),
                    child: Center(
                      child: isCorrect
                          ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                          : Text(
                              String.fromCharCode(65 + e.key),
                              style: TextStyle(
                                color: AppColors.textOnDarkHint,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.textOnDarkSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Explanation
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      explanation,
                      style: TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── بطاقة تعديل السؤال (Edit Mode) ────────────────────────────────
  Widget _buildEditingQuestionCard(int index, Map<String, dynamic> q) {
    final id = q['id'].toString();
    final controllers = _editControllers[id]!;
    final type = q['type']?.toString() ?? 'mcq';
    final optionsCount = type == 'true_false' ? 2 : 4;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.warning, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'تعديل سؤال ${index + 1}',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 60.w,
                child: TextField(
                  controller: controllers['marks'],
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    labelText: 'الدرجة',
                    labelStyle: TextStyle(
                      color: AppColors.textOnDarkHint,
                      fontSize: 11.sp,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    filled: true,
                    fillColor: AppColors.darkInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Question Text Edit
          TextField(
            controller: controllers['text'],
            maxLines: null,
            style: TextStyle(color: AppColors.textOnDark, fontSize: 14.sp),
            decoration: InputDecoration(
              labelText: 'نص السؤال',
              filled: true,
              fillColor: AppColors.darkInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Options Edit
          Text(
            'حدد الإجابة الصحيحة واكتب الخيارات:',
            style: TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ...List.generate(optionsCount, (i) {
            final isCorrect = _editCorrectAnswers[id] == i;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: _editCorrectAnswers[id],
                    activeColor: AppColors.success,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.success;
                      }
                      return AppColors.textOnDarkHint;
                    }),
                    onChanged: (val) {
                      setState(() => _editCorrectAnswers[id] = val!);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controllers['opt_$i'],
                      style: TextStyle(
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.textOnDark,
                        fontSize: 13.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'الخيار ${i + 1}',
                        filled: true,
                        fillColor: isCorrect
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.darkInput,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: isCorrect
                              ? BorderSide(color: AppColors.success)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Explanation
          TextField(
            controller: controllers['explanation'],
            maxLines: 2,
            style: TextStyle(color: AppColors.textOnDark, fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'شرح الإجابة (اختياري)',
              filled: true,
              fillColor: AppColors.darkInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _cancelEditing(id),
                child: Text(
                  'إلغاء',
                  style: TextStyle(color: AppColors.textOnDarkHint),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                onPressed: () => _saveEditing(q),
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: const Text(
                  'حفظ التعديل',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: _isPublishing || _editingIds.isNotEmpty
            ? null
            : _publishExam,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          disabledBackgroundColor: AppColors.success.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: _isPublishing
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white),
                  SizedBox(width: 10.w),
                  Text(
                    'نشر الامتحان للطلاب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
