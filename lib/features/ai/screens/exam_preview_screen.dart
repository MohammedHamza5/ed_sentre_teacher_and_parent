import 'dart:math';

import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:ed_sentre_techer_and_parent/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../exam_generator/presentation/cubits/exam_generator/exam_generator_cubit.dart';
import '../../exam_generator/presentation/cubits/exam_generator/exam_generator_state.dart';
import '../../exam_generator/domain/use_cases/publish_ai_exam_use_case.dart';
import '../widgets/exam_preview_summary.dart';
import '../widgets/exam_preview_publish_settings.dart';
import '../widgets/exam_preview_question_view.dart';
import '../widgets/exam_preview_question_editor.dart';
import '../widgets/exam_preview_cognitive_chart.dart';
import '../services/exam_pdf_service.dart';

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
  List<GroupModel> _groups = [];
  Set<String> _selectedGroupIds = {};
  bool _showAnswersAfter = true;
  bool _shuffleQuestions = false;

  // ─── البيانات القابلة للتعديل ──────────────────────────────
  List<Map<String, dynamic>> _questions = [];
  final Set<String> _editingIds = {};

  // للتحكم بحالة التعديل لكل سؤال
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
      }
    } catch (e) {
      debugPrint('❌ Error loading groups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _publishExam() async {
    if (_selectedGroupIds.isEmpty) {
      _showSnack('يرجى اختيار مجموعة واحدة على الأقل');
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

    final center = context.read<CenterProvider>();
    final centerId = center.currentCenterId;

    if (centerId == null) {
      _showSnack('لم يتم تحديد المركز');
      return;
    }

    final duration = int.tryParse(_durationController.text);
    final examType =
        widget.examData['exam_type']?.toString() ??
        widget.examData['examType']?.toString() ??
        'exam';

    final selectedGroups =
        _groups.where((g) => _selectedGroupIds.contains(g.id)).toList();

    context.read<ExamGeneratorCubit>().publishExam(
      PublishAiExamParams(
        centerId: centerId,
        targetGroups: selectedGroups,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        examType: examType,
        difficulty: widget.examData['difficulty']?.toString() ?? 'medium',
        timeLimitMinutes: duration,
        showAnswersAfter: _showAnswersAfter,
        shuffleQuestions: _shuffleQuestions,
        editedQuestions: _questions,
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'تم نشر الامتحان بنجاح لـ ${_selectedGroupIds.length} مجموعات.\n'
          'سيظهر للطلاب في قائمة الامتحانات.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
              child: Text(
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

    _editCorrectAnswers[id] = (q['correct_answer'] as num?)?.toInt() ?? 0;

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
          'explanation': controllers['explanation']?.text,
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

  void _showPdfExportOptions() {
    final auth = context.read<AuthProvider>();
    final teacherName = auth.teacherProfile?.fullName ?? auth.currentUser?.fullName ?? 'المعلم المستقل';
    final duration = int.tryParse(_durationController.text) ?? 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تصدير الاختبار كـ PDF للطباعة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.description_outlined, color: AppColors.primary),
                ),
                title: Text(
                  'نسخة أوراق الطلاب (بدون إجابات)',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'مخصصة للطباعة والتوزيع مع خانة لأسم الطالب ورقم المجموعات.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ExamPdfService.generateAndPrintExam(
                    title: _titleController.text.isNotEmpty ? _titleController.text : 'امتحان بالذكاء الاصطناعي',
                    description: _descriptionController.text,
                    durationMinutes: duration,
                    questions: _questions,
                    isModelAnswer: false,
                    teacherName: teacherName,
                  );
                },
              ),
              Divider(color: AppColors.darkBorder, height: 24.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                ),
                title: Text(
                  'نموذج الإجابة الرسمي (Model Answer)',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'يبرز الإجابات الصحيحة والتوضيحات التحليلة للمعلم والمراجعة.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ExamPdfService.generateAndPrintExam(
                    title: _titleController.text.isNotEmpty ? _titleController.text : 'امتحان بالذكاء الاصطناعي',
                    description: _descriptionController.text,
                    durationMinutes: duration,
                    questions: _questions,
                    isModelAnswer: true,
                    teacherName: teacherName,
                  );
                },
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  // ─── بناء واجهة المستخدم ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExamGeneratorCubit, ExamGeneratorState>(
      listener: (context, state) {
        if (state is ExamGeneratorSaved || state is ExamGeneratorSuccess) {
          _showSuccessDialog();
        } else if (state is ExamGeneratorFailure) {
          _showSnack('حدث خطأ أثناء الحفظ');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'محرر الامتحانات الذكي',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18.sp),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.print_rounded, color: AppColors.primary, size: 24.sp),
            tooltip: 'تصدير ورقة الامتحان كـ PDF / طباعة',
            onPressed: _showPdfExportOptions,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: _isLoadingGroups
          ? Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.primary,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExamPreviewSummary(
                          questions: _questions,
                          difficulty: widget.examData['difficulty']?.toString(),
                        ),
                        SizedBox(height: 20.h),
                        if (widget.examData['cognitiveLevelDistribution'] != null)
                          ExamPreviewCognitiveChart(
                            cognitiveLevelDistribution: widget.examData['cognitiveLevelDistribution'] as Map<String, dynamic>,
                          ),
                        ExamPreviewPublishSettings(
                          titleController: _titleController,
                          descriptionController: _descriptionController,
                          durationController: _durationController,
                          groups: _groups,
                          selectedGroupIds: _selectedGroupIds,
                          onSelectionChanged: (v) => setState(() => _selectedGroupIds = v),
                          showAnswersAfter: _showAnswersAfter,
                          onShowAnswersChanged: (v) => setState(() => _showAnswersAfter = v),
                          shuffleQuestions: _shuffleQuestions,
                          onShuffleChanged: (v) => setState(() => _shuffleQuestions = v),
                        ),
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
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                                    ? ExamPreviewQuestionEditor(
                                        index: index,
                                        question: q,
                                        controllers: _editControllers[id]!,
                                        correctAnswerIndex: _editCorrectAnswers[id] ?? 0,
                                        onCorrectAnswerChanged: (val) {
                                          setState(() => _editCorrectAnswers[id] = val);
                                        },
                                        onCancel: () => _cancelEditing(id),
                                        onSave: () => _saveEditing(q),
                                      )
                                    : ExamPreviewQuestionView(
                                        index: index,
                                        question: q,
                                        onDuplicate: () => _duplicateQuestion(q),
                                        onEdit: () => _startEditing(q),
                                        onDelete: () => _deleteQuestion(id),
                                      ),
                              );
                            },
                          ),

                        SizedBox(height: 16.h),

                        // Add new question button
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _addNewQuestion,
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('إضافة سؤال جديد'),
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
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
                    ),
                  ),
                  child: BlocBuilder<ExamGeneratorCubit, ExamGeneratorState>(
                    builder: (context, state) {
                      final isPublishing = state is ExamGeneratorSaving;
                      return _buildPublishButton(isPublishing);
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildPublishButton(bool isPublishing) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isPublishing || _editingIds.isNotEmpty
            ? null
            : _publishExam,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          disabledBackgroundColor: AppColors.success.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: isPublishing
            ? CircularProgressIndicator(backgroundColor: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, color: Colors.white),
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

  Widget _buildQuestionsHeader() {
    return Row(
      children: [
        Icon(Icons.quiz, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          'الأسئلة (${_questions.length})',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.drag_indicator,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          size: 16.sp,
        ),
        SizedBox(width: 4.w),
        Text(
          'اسحب للترتيب',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12.sp),
        ),
      ],
    );
  }
}
